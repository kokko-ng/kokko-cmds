#!/usr/bin/env bash
# Lint the prompt files (plugin commands and skills) for the mechanical
# defect classes that have actually shipped here:
#
#   1. Missing or incomplete frontmatter (description for commands;
#      name + description for skills).
#   2. Pseudo-placeholders. Claude Code substitutes $ARGUMENTS, $0-$9, and
#      ${CLAUDE_*} variables in command/skill bodies -- anything else, like
#      `$target`, is left as literal text while looking like a substitution.
#      Rule: outside fenced code blocks, a $token starting with a lowercase
#      letter and 2+ characters long is an error. Uppercase tokens ($UPSTREAM)
#      and single letters ($f) are conventional shell references in prose.
#   3. $ARGUMENTS/$N used in a command body without an argument-hint in the
#      frontmatter, so the user never sees what the command accepts.
#   4. references/... or ${CLAUDE_PLUGIN_ROOT}/... paths that do not exist on
#      disk -- a renamed reference file silently orphans every prompt that
#      cites it.
#   5. Fenced bash blocks a command's own allowed-tools cannot cover. A
#      Bash(<prefix>:*) allowlist matches by command prefix, so a block
#      whose pipeline segment starts with an assignment (VAR=...), a test
#      construct, or an unlisted binary still triggers a permission prompt
#      mid-command -- silently defeating the allowlist's purpose. Commands
#      granting bare unrestricted `Bash` are skipped.
#
# Run from the repo root: bash scripts/lint-prompts.sh
set -euo pipefail

FAIL=0

err() {
  echo "ERROR: $1"
  FAIL=1
}

# frontmatter <file> -> the frontmatter block (empty if none)
frontmatter() {
  awk 'NR==1 {if ($0=="---") {fm=1; next} else exit}
       fm {if ($0=="---") exit; print}' "$1"
}

# pseudo_placeholders <file> -> "line:token" per finding, fences skipped
pseudo_placeholders() {
  awk '
    /^[[:space:]]*```/ {fence = !fence; next}
    fence {next}
    {
      s = $0
      while (match(s, /\$[a-z][a-z0-9_]+/)) {
        print FNR ":" substr(s, RSTART, RLENGTH)
        s = substr(s, RSTART + RLENGTH)
      }
    }' "$1"
}

# check_path_mentions <file> <plugin_dir>: every references/... and
# ${CLAUDE_PLUGIN_ROOT}/... mention must resolve to something on disk
check_path_mentions() {
  local file="$1" plugin_dir="$2" raw rel
  # ${CLAUDE_PLUGIN_ROOT}/<path> mentions resolve against the plugin root
  while IFS= read -r raw; do
    rel="${raw#\$\{CLAUDE_PLUGIN_ROOT\}/}"
    rel="${rel%%#*}"
    rel="${rel%/}"
    [ -n "$rel" ] || continue
    case "$rel" in *'<'*|*'>'*|*'*'*) continue ;; esac
    if [ ! -e "$plugin_dir/$rel" ]; then
      err "$file cites \${CLAUDE_PLUGIN_ROOT}/$rel but $plugin_dir/$rel does not exist"
    fi
  done < <(grep -oE '\$\{CLAUDE_PLUGIN_ROOT\}/[^[:space:]"'\''`)]+' "$file" | sort -u)

  # bare references/... mentions may sit at the plugin root or under a skill
  while IFS= read -r raw; do
    rel="${raw%%#*}"
    rel="${rel%/}"
    [ -n "$rel" ] || continue
    case "$rel" in *'<'*|*'>'*|*'*'*) continue ;; esac
    if [ -z "$(find "$plugin_dir" -path "*/$rel" -print -quit)" ]; then
      err "$file cites $rel but nothing under $plugin_dir matches it"
    fi
  done < <(grep -oE '(^|[^A-Za-z0-9_./-])references/[A-Za-z0-9._/-]+' "$file" \
           | sed -E 's/^[^r]*(references\/)/\1/' | sort -u)
}

# --- check 5: fenced bash the allowed-tools frontmatter cannot cover -------

# bash_block_segments <file> -> "line<TAB>segment" for every command segment
# inside ```bash / ```sh fences, continuations joined, comments dropped.
bash_block_segments() {
  awk '
    /^[[:space:]]*```/ {
      if (!fence) {
        lang = $0; sub(/^[[:space:]]*```/, "", lang)
        fence = 1; isbash = (lang ~ /^(bash|sh)[[:space:]]*$/)
      } else { fence = 0; isbash = 0 }
      next
    }
    fence && isbash {
      line = $0
      if (line ~ /^[[:space:]]*#/) next   # whole-line comment
      # Join backslash continuations, and keep appending while a single- or
      # double-quoted span is still open (multi-line jq/awk programs).
      while (1) {
        cont = (line ~ /\\$/)
        tmp = line
        nsq = gsub(/\047/, "", tmp)
        ndq = gsub(/"/, "", tmp)
        if (!cont && nsq % 2 == 0 && ndq % 2 == 0) break
        if ((getline nxt) <= 0) break
        if (cont) sub(/\\$/, "", line)
        sub(/^[[:space:]]+/, "", nxt)
        line = line " " nxt
      }
      gsub(/\\\|/, "\001", line)          # protect quoted \| (grep alternation)
      # Blank quoted spans so operators inside them do not split segments.
      gsub(/\047[^\047]*\047/, "\047Q\047", line)
      gsub(/"[^"]*"/, "\"Q\"", line)
      gsub(/\|\||&&|;|\|/, "\n", line)    # split on shell operators (not lone &)
      n = split(line, segs, "\n")
      for (i = 1; i <= n; i++) {
        s = segs[i]
        gsub(/\001/, "\\|", s)
        sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s)
        if (s == "" || s ~ /^#/) continue
        printf "%d\t%s\n", FNR, s
      }
    }' "$1"
}

# check_allowed_tools_coverage <file>: every segment must start with an
# allowed Bash prefix. Files granting bare `Bash` are exempt.
check_allowed_tools_coverage() {
  local file="$1" fm tools
  fm=$(frontmatter "$file")
  tools=$(printf '%s\n' "$fm" | sed -n 's/^allowed-tools:[[:space:]]*//p')

  # Bare unrestricted Bash grant: nothing to check.
  printf '%s' "$tools" | grep -qE '(^|,)[[:space:]]*Bash[[:space:]]*(,|$)' && return 0

  local prefixes=()
  while IFS= read -r p; do
    [ -n "$p" ] && prefixes+=("$p")
  done < <(printf '%s\n' "$tools" | grep -oE 'Bash\([^)]*\)' | sed -E 's/^Bash\(//; s/\)$//; s/:\*$//')

  local lineno seg word ok p
  while IFS=$'\t' read -r lineno seg; do
    word="${seg%% *}"
    case "$word" in
      if|then|else|elif|fi|for|while|until|do|done|'case'|'esac'|'['|'[['|test|'!')
        err "$file:$lineno bash block uses '$word' — compound/test constructs never match a Bash(<prefix>:*) allowlist, so this segment permission-prompts mid-command: $seg"
        continue ;;
    esac
    if printf '%s' "$word" | grep -qE '^[A-Za-z_][A-Za-z_0-9]*='; then
      err "$file:$lineno bash block starts a segment with an assignment — assignments never match a Bash(<prefix>:*) allowlist, so this segment permission-prompts mid-command: $seg"
      continue
    fi
    ok=0
    for p in ${prefixes[@]+"${prefixes[@]}"}; do
      case "$seg" in
        "$p" | "$p "*) ok=1; break ;;
      esac
    done
    if [ "$ok" -eq 0 ]; then
      err "$file:$lineno bash block runs '$word' but allowed-tools grants no Bash prefix covering it: $seg"
    fi
  done < <(bash_block_segments "$file")
}

for file in plugins/*/commands/*.md plugins/*/skills/*/SKILL.md; do
  [ -f "$file" ] || continue
  plugin_dir=$(echo "$file" | cut -d/ -f1-2)
  fm=$(frontmatter "$file")

  if [ -z "$fm" ]; then
    err "$file has no frontmatter block"
    continue
  fi

  if ! printf '%s\n' "$fm" | grep -q '^description:'; then
    err "$file frontmatter has no description"
  fi

  case "$file" in
    */SKILL.md)
      if ! printf '%s\n' "$fm" | grep -q '^name:'; then
        err "$file frontmatter has no name"
      fi
      ;;
    */commands/*)
      # shellcheck disable=SC2016  # the $ is a literal to grep for, not an expansion
      if grep -qE '\$ARGUMENTS|\$[0-9]' "$file" \
        && ! printf '%s\n' "$fm" | grep -q '^argument-hint:'; then
        err "$file uses \$ARGUMENTS/\$N but has no argument-hint"
      fi
      ;;
  esac

  while IFS= read -r finding; do
    [ -n "$finding" ] || continue
    err "$file:$finding looks like a substitution placeholder, but Claude Code only substitutes \$ARGUMENTS, \$0-\$9, and \${CLAUDE_*}"
  done < <(pseudo_placeholders "$file")

  check_path_mentions "$file" "$plugin_dir"

  case "$file" in
    */commands/*) check_allowed_tools_coverage "$file" ;;
  esac
done

if [ "$FAIL" -eq 0 ]; then
  echo "prompt lint: all command and skill files are clean"
fi
exit "$FAIL"

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
done

if [ "$FAIL" -eq 0 ]; then
  echo "prompt lint: all command and skill files are clean"
fi
exit "$FAIL"

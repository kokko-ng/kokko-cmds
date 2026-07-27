#!/usr/bin/env bash
# session-context.sh — state the project context and the git safety contract
# at session start.
#
# This merges what used to be two hooks: session-start-context.sh (project type
# detection, which wrote bare text to stdout) and the devcontainer's
# session-git-safety.sh (the git safety rules, as additionalContext JSON). One
# SessionStart hook, one JSON payload, one place to edit.
#
# The safety half does not depend on any file the user might replace. The
# bundled CLAUDE.md carries the same rules, but a host-mounted ~/.claude
# provides its own CLAUDE.md — so in exactly the setup a long-running user is
# most likely to have, a CLAUDE.md-only advisory layer would silently vanish.
set -uo pipefail

HOOK_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# shellcheck source=lib/hook-io.sh
source "$HOOK_LIB/hook-io.sh"

command -v jq >/dev/null 2>&1 || exit 0

read_hook_input
cwd=$(printf '%s' "$HOOK_INPUT" | jq -r '.cwd // "."' 2>/dev/null || echo ".")
cd "$cwd" 2>/dev/null || exit 0

# =====================
# Project type
# =====================
# Ordered so that a polyglot repo reports every stack it actually has rather
# than whichever check happened to run last.
stacks=()
detected_files=()

add_stack() {
    local s="$1"
    local existing
    for existing in ${stacks[@]+"${stacks[@]}"}; do
        [[ "$existing" == "$s" ]] && return 0
    done
    stacks+=("$s")
}

for f in pyproject.toml requirements.txt setup.py; do
    if [[ -f "$f" ]]; then
        add_stack python
        detected_files+=("$f")
        break
    fi
done

if [[ -f package.json ]]; then
    detected_files+=("package.json")
    if [[ -f tsconfig.json ]]; then
        add_stack typescript
        detected_files+=("tsconfig.json")
    else
        add_stack nodejs
    fi
fi

[[ -f go.mod ]] && { add_stack go; detected_files+=("go.mod"); }
[[ -f Cargo.toml ]] && { add_stack rust; detected_files+=("Cargo.toml"); }

# .NET. Previously missing entirely, even though kokko-code-quality ships a
# dotnet variant of every check skill — so a C# repo got no context and the
# skills had to re-detect it.
dotnet_manifest=$(find . -maxdepth 2 \( -name '*.sln' -o -name '*.csproj' -o -name '*.fsproj' \) -print -quit 2>/dev/null || true)
if [[ -n "$dotnet_manifest" ]]; then
    add_stack dotnet
    detected_files+=("${dotnet_manifest#./}")
fi

if [[ ${#stacks[@]} -eq 0 ]]; then
    project_type="unknown"
elif [[ ${#stacks[@]} -eq 1 ]]; then
    project_type="${stacks[0]}"
else
    project_type="mixed ($(IFS=+; echo "${stacks[*]}"))"
fi

# =====================
# Git state
# =====================
git_branch=""
dirty_count=0
in_git=false
if git rev-parse --git-dir >/dev/null 2>&1; then
    in_git=true
    git_branch=$(git branch --show-current 2>/dev/null || true)
    dirty_count=$(git status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' ')
fi

dirty_note=""
if (( dirty_count > 0 )); then
    dirty_note="

ATTENTION: this repo currently has ${dirty_count} uncommitted tracked file(s). If that work is not
yours, STOP and ask the user before editing or running any git command. Do not tidy it,
do not stash it, do not assume it is junk."
fi

safety_note=""
if [[ "$in_git" == true ]]; then
    safety_note="
Git safety (enforced by the kokko-safety hooks):

- Uncommitted changes to TRACKED files are unrecoverable if destroyed: they were never git
  objects, so no reflog entry, no dangling blob, no fsck recovery. rebase/reset/checkout/
  restore/stash/clean overwrite them with no prompt. This has destroyed hours of real work.
- Destructive git commands are BLOCKED while the tree is dirty, and allowed while it is
  clean. If you are blocked, the guard is right: commit the work and retry, or ask the
  user. Do not look for a way around it.
- Uncommitted tracked changes are auto-snapshotted to refs/snapshots/. If work seems lost,
  list them FIRST, before any archaeology and before telling the user it is gone:
  \`git for-each-ref refs/snapshots/\`, then \`git stash show -p <ref>\` to inspect and
  \`git stash apply <ref>\` to restore. The kokko devcontainer wraps all three as \`snaps\`.
- Commit before any build that packages the working tree (docker/az acr build ship what is
  on disk, not HEAD). Stage explicit paths, never \`git add .\`. Push only when asked.${dirty_note}
"
fi

read -r -d '' CONTEXT <<EOF || true
PROJECT CONTEXT:
- Type: $project_type
- Branch: ${git_branch:-"(not in a git repo)"}
- Uncommitted tracked files: $dirty_count
- Manifests: ${detected_files[*]:-"none detected"}
${safety_note}
EOF

jq -n --arg c "$CONTEXT" '{
    hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: $c
    }
}'
exit 0

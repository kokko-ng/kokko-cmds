#!/bin/bash
# pre-tool-branch-protection.sh - Protect production branches
# PreToolUse on Bash - Warns on commits/pushes on main, master, production, prod, release
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
# shellcheck source=utils/hook-preamble.sh
source "$SCRIPT_DIR/utils/hook-preamble.sh"
require_jq_or_ask
read_input_or_ask
# shellcheck source=utils/play-sound.sh
source "$SCRIPT_DIR/utils/play-sound.sh"

command=$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_input.command // ""')

# Protected branch names
protected_branches=("main" "master" "production" "prod" "release")

# Check if this is a git command we care about (git may carry a -C <dir> option)
git_cmd_re='git[[:space:]]+(-C[[:space:]]+("[^"]*"|[^[:space:]]+)[[:space:]]+)?(commit|push|reset|rebase)'
if ! printf '%s\n' "$command" | grep -qE -- "$git_cmd_re"; then
    exit 0
fi

# Determine which directory the git command targets. A leading `cd <dir> && ...`
# or a `git -C <dir>` option wins; otherwise the hook's own cwd is used (which
# is where Claude Code runs the Bash tool). More exotic forms (a cd buried
# mid-pipeline, subshells) fall back to the hook's cwd.
git_dir="."
re_cd_dq='^[[:space:]]*cd[[:space:]]+"([^"]+)"[[:space:]]*&&'
re_cd_sq="^[[:space:]]*cd[[:space:]]+'([^']+)'[[:space:]]*&&"
re_cd_bare='^[[:space:]]*cd[[:space:]]+([^[:space:];&|]+)[[:space:]]*&&'
re_gitc_dq='git[[:space:]]+-C[[:space:]]+"([^"]+)"'
re_gitc_sq="git[[:space:]]+-C[[:space:]]+'([^']+)'"
re_gitc_bare='git[[:space:]]+-C[[:space:]]+([^[:space:];&|]+)'
if [[ "$command" =~ $re_cd_dq ]] || [[ "$command" =~ $re_cd_sq ]] || [[ "$command" =~ $re_cd_bare ]]; then
    git_dir="${BASH_REMATCH[1]}"
elif [[ "$command" =~ $re_gitc_dq ]] || [[ "$command" =~ $re_gitc_sq ]] || [[ "$command" =~ $re_gitc_bare ]]; then
    git_dir="${BASH_REMATCH[1]}"
fi

# Get the branch the command would act on
current_branch=$(git -C "$git_dir" branch --show-current 2>/dev/null || true)

if [ -z "$current_branch" ]; then
    # Not in a git repo (or detached HEAD)
    exit 0
fi

ask_and_exit() {
    play_sound "warning" || true
    emit_ask "$1"
    exit 0
}

# Check if force pushing to a protected branch (regardless of current branch).
# One regex per branch: `git push` followed by a force flag and the protected
# branch in either order, anywhere within the same shell command segment.
force_re='(--force-with-lease(=[^[:space:]]*)?|--force|-f)'
seg_re='([^;&|]*[[:space:]])?'
for branch in "${protected_branches[@]}"; do
    push_force_re="git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?push[[:space:]]+(${seg_re}${force_re}[[:space:]]${seg_re}${branch}([[:space:]]|\$)|${seg_re}${branch}[[:space:]]${seg_re}${force_re}([[:space:]]|\$))"
    if printf '%s\n' "$command" | grep -qE -- "$push_force_re"; then
        ask_and_exit "Force push to protected branch '${branch}' detected. This could overwrite shared history. Allow Claude to proceed?"
    fi
done

# Check if current branch is protected
for branch in "${protected_branches[@]}"; do
    if [ "$current_branch" = "$branch" ]; then
        # Warn about commits, pushes, resets, and rebases on protected branches
        ask_and_exit "You are on protected branch '${current_branch}'. Allow Claude to run this git command directly on this branch?"
    fi
done

exit 0

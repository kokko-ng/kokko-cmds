#!/bin/bash
# pre-tool-branch-protection.sh - Protect production branches
# PreToolUse on Bash - Warns on commits and plain pushes on main, master, production, prod, release
# shellcheck source-path=SCRIPTDIR

# Fail closed from the very first line: a crash before hook-preamble.sh is
# sourced (missing utils/, unresolvable SCRIPT_DIR, set -u trip) would
# otherwise exit non-zero with no output, which Claude Code treats as allow.
# EXIT rather than ERR: bash does not run ERR traps on fatal errors such as a
# failed `source` or an unbound-variable abort, but it does run EXIT traps.
# JSON shape mirrors emit_ask_static in utils/hook-preamble.sh.
# Invoked via the EXIT trap below, which shellcheck cannot see:
# shellcheck disable=SC2329
_fail_closed() {
    rc=$?
    [ "$rc" -eq 0 ] && exit 0
    reason="kokko-safety: pre-tool-branch-protection.sh crashed before it could evaluate this command; failing closed to a permission prompt"
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"},"systemMessage":"%s"}\n' "$reason" "$reason"
    exit 0
}
trap _fail_closed EXIT

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

# Check if this is a git command we care about (git may carry a -C <dir>
# option). Only commit and push: force push, hard reset, and rebase are owned
# by pre-tool-destructive-git via dangerous-patterns/git.txt on every branch,
# and matching them here too made one command prompt twice.
git_cmd_re='git[[:space:]]+(-C[[:space:]]+("[^"]*"|[^[:space:]]+)[[:space:]]+)?(commit|push)'
if ! printf '%s\n' "$command" | grep -qE -- "$git_cmd_re"; then
    exit 0
fi

# Force pushes are pre-tool-destructive-git's job regardless of branch;
# prompting here as well would double-prompt the same command.
force_push_re='git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?push[[:space:]]+([^;&|]*[[:space:]])?(--force(-with-lease(=[^[:space:]]*)?)?|-f)([[:space:]]|$)'
if printf '%s\n' "$command" | grep -qE -- "$force_push_re"; then
    exit 0
fi

# Determine which directory the git command targets. git itself gives -C
# precedence over the shell's working directory, so `git -C <dir>` must win
# over a leading `cd <dir> && ...` prefix; otherwise
# `cd /tmp/x && git -C /repo commit` is checked against /tmp/x. When neither
# is present the hook's own cwd is used (which is where Claude Code runs the
# Bash tool). More exotic forms (a cd buried mid-pipeline, subshells) fall
# back to the hook's cwd.
git_dir="."
re_cd_dq='^[[:space:]]*cd[[:space:]]+"([^"]+)"[[:space:]]*&&'
re_cd_sq="^[[:space:]]*cd[[:space:]]+'([^']+)'[[:space:]]*&&"
re_cd_bare='^[[:space:]]*cd[[:space:]]+([^[:space:];&|]+)[[:space:]]*&&'
re_gitc_dq='git[[:space:]]+-C[[:space:]]+"([^"]+)"'
re_gitc_sq="git[[:space:]]+-C[[:space:]]+'([^']+)'"
re_gitc_bare='git[[:space:]]+-C[[:space:]]+([^[:space:];&|]+)'
if [[ "$command" =~ $re_gitc_dq ]] || [[ "$command" =~ $re_gitc_sq ]] || [[ "$command" =~ $re_gitc_bare ]]; then
    git_dir="${BASH_REMATCH[1]}"
elif [[ "$command" =~ $re_cd_dq ]] || [[ "$command" =~ $re_cd_sq ]] || [[ "$command" =~ $re_cd_bare ]]; then
    git_dir="${BASH_REMATCH[1]}"
fi

ask_and_exit() {
    play_sound "warning" || true
    emit_ask "$1"
    exit 0
}

# Get the branch the command would act on
current_branch=$(git -C "$git_dir" branch --show-current 2>/dev/null || true)

if [ -z "$current_branch" ]; then
    # Empty means "not a git repo" (allow) or a detached HEAD. A detached
    # HEAD parked on a protected branch's tip is still effectively working on
    # that branch, so it gets the same prompt instead of a free pass.
    if [ "$(git -C "$git_dir" rev-parse --is-inside-work-tree 2>/dev/null || true)" = "true" ]; then
        head_branches=$(git -C "$git_dir" for-each-ref refs/heads --points-at HEAD --format='%(refname:short)' 2>/dev/null || true)
        for branch in "${protected_branches[@]}"; do
            if printf '%s\n' "$head_branches" | grep -qxF -- "$branch"; then
                ask_and_exit "Detached HEAD at the tip of protected branch '${branch}'. Allow Claude to run this git command here?"
            fi
        done
    fi
    exit 0
fi

# Check if current branch is protected
for branch in "${protected_branches[@]}"; do
    if [ "$current_branch" = "$branch" ]; then
        # Warn about commits and pushes on protected branches
        ask_and_exit "You are on protected branch '${current_branch}'. Allow Claude to run this git command directly on this branch?"
    fi
done

exit 0

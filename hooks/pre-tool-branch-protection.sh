#!/bin/bash
# pre-tool-branch-protection.sh - Protect production branches
# Hook #21: PreToolUse on Bash - Warns on commits/pushes on main, master, production, prod, release

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Protected branch names
protected_branches=("main" "master" "production" "prod" "release")

# Check if this is a git command we care about
if ! echo "$command" | grep -qE '^git[[:space:]]+(commit|push|reset|rebase)'; then
    exit 0
fi

# Get current branch
current_branch=$(git branch --show-current 2>/dev/null)

if [ -z "$current_branch" ]; then
    # Not in a git repo
    exit 0
fi

# Check if force pushing to a protected branch (regardless of current branch)
for branch in "${protected_branches[@]}"; do
    if echo "$command" | grep -qE "git[[:space:]]+push[[:space:]]+(.*[[:space:]])?(--force|-f)[[:space:]]+(origin|upstream)[[:space:]]+${branch}([[:space:]]|$)"; then
        play_sound "warning"
        cat << EOF
{
  "decision": "ask",
  "message": "Force push to protected branch '${branch}' detected. This could overwrite shared history. Allow Claude to proceed?"
}
EOF
        exit 0
    fi

    # Also check: git push origin main --force (flag at end)
    if echo "$command" | grep -qE "git[[:space:]]+push[[:space:]]+(origin|upstream)[[:space:]]+${branch}[[:space:]]+(--force|-f)"; then
        play_sound "warning"
        cat << EOF
{
  "decision": "ask",
  "message": "Force push to protected branch '${branch}' detected. This could overwrite shared history. Allow Claude to proceed?"
}
EOF
        exit 0
    fi
done

# Check if current branch is protected
is_protected=false
for branch in "${protected_branches[@]}"; do
    if [ "$current_branch" = "$branch" ]; then
        is_protected=true
        break
    fi
done

if [ "$is_protected" = true ]; then
    # Warn about commits, pushes, resets, and rebases on protected branches
    if echo "$command" | grep -qE '^git[[:space:]]+(commit|push|reset|rebase)'; then
        play_sound "warning"
        cat << EOF
{
  "decision": "ask",
  "message": "You are on protected branch '${current_branch}'. Allow Claude to run this git command directly on this branch?"
}
EOF
        exit 0
    fi
fi

exit 0

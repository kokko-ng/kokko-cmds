#!/bin/bash
# pre-tool-destructive-git.sh - Block destructive git operations
# Hook #8: PreToolUse on Bash - Blocks force push, hard reset, clean -fd, branch -D, rebase -i

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Check for destructive git patterns
# Force push variants
if echo "$command" | grep -qE 'git[[:space:]]+push[[:space:]]+(.*[[:space:]])?(--force|-f)([[:space:]]|$)'; then
    play_sound "warning"
    cat << 'EOF'
{
  "decision": "block",
  "reason": "BLOCKED: git push --force can overwrite remote history and cause issues for other developers. If you really need to force push, do it manually in the terminal after careful consideration."
}
EOF
    exit 2
fi

# Hard reset
if echo "$command" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard'; then
    play_sound "warning"
    cat << 'EOF'
{
  "decision": "block",
  "reason": "BLOCKED: git reset --hard permanently discards all uncommitted changes. If you need to reset, consider 'git stash' first or do this manually after confirming you want to lose changes."
}
EOF
    exit 2
fi

# Clean with force and directories
if echo "$command" | grep -qE 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*d|git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*d[a-zA-Z]*f'; then
    play_sound "warning"
    cat << 'EOF'
{
  "decision": "block",
  "reason": "BLOCKED: git clean -fd permanently removes untracked files and directories. Run 'git clean -n' first to preview what would be deleted, then do this manually if needed."
}
EOF
    exit 2
fi

# Force delete branch
if echo "$command" | grep -qE 'git[[:space:]]+branch[[:space:]]+-D'; then
    play_sound "warning"
    cat << 'EOF'
{
  "decision": "block",
  "reason": "BLOCKED: git branch -D force-deletes a branch without checking if it's merged. Use 'git branch -d' for safe deletion, or do this manually after confirming the branch is no longer needed."
}
EOF
    exit 2
fi

# Interactive rebase (not supported in non-interactive mode)
if echo "$command" | grep -qE 'git[[:space:]]+rebase[[:space:]]+-i|git[[:space:]]+rebase[[:space:]]+--interactive'; then
    play_sound "warning"
    cat << 'EOF'
{
  "decision": "block",
  "reason": "BLOCKED: git rebase -i requires interactive input which is not supported. Please run interactive rebase manually in your terminal."
}
EOF
    exit 2
fi

# Direct push to main/master
if echo "$command" | grep -qE 'git[[:space:]]+push[[:space:]]+(origin|upstream)[[:space:]]+(main|master)([[:space:]]|$)'; then
    play_sound "warning"
    cat << 'EOF'
{
  "decision": "block",
  "reason": "BLOCKED: Direct push to main/master branch detected. Please create a feature branch and use a pull request workflow instead."
}
EOF
    exit 2
fi

exit 0

#!/bin/bash
# pre-tool-destructive-git.sh - Warn on destructive git operations
# PreToolUse on Bash - Warns on force push, hard reset, clean -fd, branch -D, rebase -i
#
# This hook loads patterns from:
#   hooks/dangerous-patterns/git.txt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"
source "$SCRIPT_DIR/utils/load-patterns.sh"

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Load git-specific patterns
load_patterns "git"

if check_dangerous_pattern "$command"; then
    play_sound "warning"

    cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "Destructive git operation detected. This could rewrite history, delete branches, or discard changes. Allow Claude to proceed?"
}
EOF
    exit 0
fi

exit 0

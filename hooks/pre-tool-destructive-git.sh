#!/bin/bash
# pre-tool-destructive-git.sh - Warn on destructive git operations
# PreToolUse on Bash - Warns on force push, hard reset, clean -fd, branch -D, rebase -i

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
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "git push --force can overwrite remote history. Allow Claude to proceed?"
}
EOF
    exit 0
fi

# Hard reset
if echo "$command" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard'; then
    play_sound "warning"
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "git reset --hard permanently discards uncommitted changes. Allow Claude to proceed?"
}
EOF
    exit 0
fi

# Clean with force and directories
if echo "$command" | grep -qE 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*d|git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*d[a-zA-Z]*f'; then
    play_sound "warning"
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "git clean -fd permanently removes untracked files and directories. Allow Claude to proceed?"
}
EOF
    exit 0
fi

# Force delete branch
if echo "$command" | grep -qE 'git[[:space:]]+branch[[:space:]]+-D'; then
    play_sound "warning"
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "git branch -D force-deletes a branch without checking if merged. Allow Claude to proceed?"
}
EOF
    exit 0
fi

# Interactive rebase (not supported in non-interactive mode)
if echo "$command" | grep -qE 'git[[:space:]]+rebase[[:space:]]+-i|git[[:space:]]+rebase[[:space:]]+--interactive'; then
    play_sound "warning"
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "git rebase -i requires interactive input which Claude cannot provide. Allow anyway (will likely fail)?"
}
EOF
    exit 0
fi

# Direct push to main/master
if echo "$command" | grep -qE 'git[[:space:]]+push[[:space:]]+(origin|upstream)[[:space:]]+(main|master)([[:space:]]|$)'; then
    play_sound "warning"
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "Direct push to main/master detected. Allow Claude to proceed?"
}
EOF
    exit 0
fi

exit 0

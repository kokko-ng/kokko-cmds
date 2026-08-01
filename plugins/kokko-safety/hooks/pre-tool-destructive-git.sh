#!/bin/bash
# pre-tool-destructive-git.sh - Warn on destructive git operations
# PreToolUse on Bash - Warns on force push, hard reset, clean -fd, branch -D, rebase -i
#
# This hook loads patterns from:
#   hooks/dangerous-patterns/git.txt
# shellcheck source-path=SCRIPTDIR
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
# shellcheck source=utils/hook-preamble.sh
source "$SCRIPT_DIR/utils/hook-preamble.sh"
require_jq_or_ask
read_input_or_ask
# shellcheck source=utils/play-sound.sh
source "$SCRIPT_DIR/utils/play-sound.sh"
# shellcheck source=utils/load-patterns.sh
source "$SCRIPT_DIR/utils/load-patterns.sh"

command=$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_input.command // ""')

# Load git-specific patterns
load_patterns "git"

if check_dangerous_pattern "$command"; then
    play_sound "warning" || true
    emit_ask "Destructive git operation detected: matched pattern '${MATCHED_PATTERN}' from category '${MATCHED_CATEGORY}'. This could rewrite history, delete branches, or discard changes. Allow Claude to proceed?"
    exit 0
fi

exit 0

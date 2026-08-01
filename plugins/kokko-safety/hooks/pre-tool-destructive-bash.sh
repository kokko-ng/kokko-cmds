#!/bin/bash
# pre-tool-destructive-bash.sh - Block dangerous bash commands
# PreToolUse on Bash - Prompts before destructive shell operations
#
# This hook loads patterns from:
#   hooks/dangerous-patterns/file-operations.txt
#   hooks/dangerous-patterns/disk-storage.txt
#   hooks/dangerous-patterns/permissions.txt
#   hooks/dangerous-patterns/users.txt
#   hooks/dangerous-patterns/system-services.txt
#   hooks/dangerous-patterns/packages.txt
#   hooks/dangerous-patterns/networking.txt
#   hooks/dangerous-patterns/process.txt
#   hooks/dangerous-patterns/shell-security.txt
#   hooks/dangerous-patterns/databases.txt
#   hooks/dangerous-patterns/docker.txt
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

# Load patterns for general bash commands (not cloud/git specific)
load_patterns \
    "file-operations" \
    "disk-storage" \
    "permissions" \
    "users" \
    "system-services" \
    "packages" \
    "networking" \
    "process" \
    "shell-security" \
    "databases" \
    "docker"

if check_dangerous_pattern "$command"; then
    play_sound "warning" || true
    emit_ask "Potentially destructive bash command detected: matched pattern '${MATCHED_PATTERN}' from category '${MATCHED_CATEGORY}'. This could delete files, stop services, or modify system state. Allow Claude to proceed?"
    exit 0
fi

exit 0

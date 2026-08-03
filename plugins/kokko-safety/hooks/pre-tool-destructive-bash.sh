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
    reason="kokko-safety: pre-tool-destructive-bash.sh crashed before it could evaluate this command; failing closed to a permission prompt"
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"},"systemMessage":"%s"}\n' "$reason" "$reason"
    exit 0
}
trap _fail_closed EXIT

set -euo pipefail

# KOKKO_SAFETY_SKIP lists hooks to disable by name (comma- and/or space-
# separated, basenames without the pre-tool- prefix). Environments that carry
# their own guard for a category -- e.g. kokko-devcontainer's deny-based git
# guard -- can switch off just that hook and keep the rest.
IFS=', ' read -r -a _skip_tokens <<<"${KOKKO_SAFETY_SKIP:-}"
for _token in ${_skip_tokens[@]+"${_skip_tokens[@]}"}; do
    if [ "$_token" = "destructive-bash" ]; then
        exit 0
    fi
done

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

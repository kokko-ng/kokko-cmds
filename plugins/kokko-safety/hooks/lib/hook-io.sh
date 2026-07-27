#!/bin/bash
# hook-io.sh - shared stdin parsing for the kokko-safety hooks.
#
# Both hooks in this plugin read the same JSON payload from stdin and need the
# same two fields out of it. Keeping that in one place means neither hook
# reimplements the "never die on malformed input" handling, which matters: a
# hook that exits non-zero on a payload it did not expect stops running, and a
# snapshot hook that has stopped running looks exactly like one with nothing to
# snapshot.

# Read the whole hook payload from stdin into HOOK_INPUT.
read_hook_input() {
    HOOK_INPUT=$(cat 2>/dev/null || true)
}

# Extract .tool_input.command from HOOK_INPUT into HOOK_COMMAND.
# Returns 1 when there is no command to inspect, so callers can `|| exit 0`.
hook_command() {
    command -v jq >/dev/null 2>&1 || return 1
    HOOK_COMMAND=$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
    [[ -n "$HOOK_COMMAND" ]]
}

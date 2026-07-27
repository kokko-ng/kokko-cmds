#!/bin/bash
# hook-io.sh - shared stdin parsing and PreToolUse response emission.
#
# Every guard hook has the same shape: read the hook payload from stdin, pull
# out the command, decide, emit one JSON object. Keeping that in one place is
# what lets the guards themselves be nothing but a list of rules.

# Read the whole hook payload from stdin into HOOK_INPUT.
# Never fails: a hook that dies on malformed input is a hook that silently
# stops guarding.
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

# Extract .hook_event_name into HOOK_EVENT.
hook_event() {
    command -v jq >/dev/null 2>&1 || return 1
    HOOK_EVENT=$(printf '%s' "$HOOK_INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null || echo "")
}

# deny <reason> - refuse the tool call outright and exit.
#
# "deny", not "ask": these hooks run under `defaultMode: acceptEdits` where an
# "ask" either blocks an unattended agent forever or gets clicked through
# without reading. See guard-git.sh for the full argument.
deny() {
    jq -n --arg r "$1" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $r
        }
    }'
    exit 0
}

# ask <reason> - prompt the user. Reserved for operations that are routinely
# legitimate but expensive to get wrong, where refusing outright would be
# wrong more often than asking.
ask() {
    jq -n --arg r "$1" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "ask",
            permissionDecisionReason: $r
        },
        systemMessage: $r
    }'
    exit 0
}

# guard_disabled <ENV_VAR_NAME> - honour a per-guard escape hatch, both as an
# ambient variable and as an inline `VAR=off some-command` prefix.
#
# Deliberately verbose and greppable so a bypass shows up in a transcript.
guard_disabled() {
    local var="$1"
    [[ "${!var:-on}" == "off" ]] && return 0
    printf '%s' "${HOOK_COMMAND:-}" | grep -qE "(^|[[:space:];&|(])${var}=off[[:space:]]" && return 0
    return 1
}

#!/bin/bash
# hook-preamble.sh - Shared fail-closed preamble for kokko-safety hooks
#
# Source this file FIRST (after `set -euo pipefail`), then call:
#
#   require_jq_or_ask    PreToolUse hooks: if jq is missing, emit an "ask"
#                        permission decision and exit 0. The hook can never
#                        fail OPEN just because its dependency is absent.
#   read_input_or_ask    PreToolUse hooks: read the payload from stdin into
#                        $HOOK_INPUT; malformed JSON fails closed to "ask".
#   emit_ask <reason>    Emit an "ask" PreToolUse decision. JSON is built with
#                        jq so the reason can safely contain quotes.
#
# Non-gating hooks (e.g. SessionStart) have nothing to fail closed over:
#
#   require_jq_or_exit   Exit 0 quietly (with a stderr note) if jq is missing.
#   read_input_or_exit   Read stdin into $HOOK_INPUT; exit 0 on malformed JSON.

# Emit an "ask" decision without depending on jq. The reason must be a literal
# containing no characters that need JSON escaping.
emit_ask_static() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"},"systemMessage":"%s"}\n' "$1" "$1"
}

# Emit an "ask" decision; the reason is passed through jq --arg so any
# characters (quotes, backslashes, newlines) are escaped correctly.
emit_ask() {
    jq -n --arg reason "$1" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "ask",
            permissionDecisionReason: $reason
        },
        systemMessage: $reason
    }'
}

require_jq_or_ask() {
    if ! command -v jq >/dev/null 2>&1; then
        emit_ask_static "kokko-safety cannot evaluate this command: jq is missing"
        exit 0
    fi
}

read_input_or_ask() {
    HOOK_INPUT=$(cat)
    if ! printf '%s' "$HOOK_INPUT" | jq -e . >/dev/null 2>&1; then
        emit_ask "kokko-safety cannot evaluate this command: hook payload is not valid JSON"
        exit 0
    fi
}

require_jq_or_exit() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "kokko-safety: jq is missing; skipping non-gating hook" >&2
        exit 0
    fi
}

read_input_or_exit() {
    HOOK_INPUT=$(cat)
    if ! printf '%s' "$HOOK_INPUT" | jq -e . >/dev/null 2>&1; then
        echo "kokko-safety: hook payload is not valid JSON; skipping non-gating hook" >&2
        exit 0
    fi
}

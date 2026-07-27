#!/usr/bin/env bash
# Shared bats helpers for exercising the kokko-safety hooks.
#
# A hook is a black box: JSON on stdin, JSON (or nothing) on stdout. These
# helpers keep the tests written in exactly those terms, so a test never has to
# know how a hook is implemented.

SAFETY_HOOKS="${BATS_TEST_DIRNAME}/../plugins/kokko-safety/hooks"

# run_hook <hook-script> <command> — feed a PreToolUse payload to a hook.
run_hook() {
    local hook="$1" cmd="$2"
    jq -n --arg c "$cmd" '{hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: {command: $c}}' \
        | bash "$SAFETY_HOOKS/$hook"
}

# assert_no_decision <hook> <command> — assert a hook does NOT try to block or
# prompt.
#
# This plugin deliberately ships no deterministic blocking: the guards were
# removed because a guard that fires on routine work gets switched off, taking
# the snapshot layer with it. These hooks observe and advise, they never refuse.
# Reintroducing a permissionDecision here would be a behavioural change, not a
# tweak, so it is asserted rather than assumed.
assert_no_decision() {
    local out
    out="$(run_hook "$1" "$2")"
    [[ -z "$out" ]] && return 0
    local decision
    decision="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // ""')"
    if [[ -n "$decision" ]]; then
        printf 'hook %s returned permissionDecision=%s for: %s\n' "$1" "$decision" "$2" >&2
        printf 'this plugin does not block commands; see tests/helpers/hook.bash\n' >&2
        return 1
    fi
}

# assert_valid_json <hook> <command> — a hook that emits malformed JSON is
# ignored by Claude Code, which means it silently stops working.
assert_valid_json() {
    local out
    out="$(run_hook "$1" "$2")"
    [[ -z "$out" ]] && return 0
    printf '%s' "$out" | jq -e . >/dev/null
}

# =====================
# Throwaway git repos
# =====================

new_repo() {
    local dir
    dir="$(mktemp -d)"
    git -C "$dir" init -q
    git -C "$dir" config user.email test@example.com
    git -C "$dir" config user.name "Test"
    git -C "$dir" config commit.gpgsign false
    printf 'initial\n' > "$dir/tracked.txt"
    git -C "$dir" add tracked.txt
    git -C "$dir" commit -qm "initial"
    printf '%s' "$dir"
}

dirty_repo() {
    local dir
    dir="$(new_repo)"
    printf 'uncommitted change\n' >> "$dir/tracked.txt"
    printf '%s' "$dir"
}

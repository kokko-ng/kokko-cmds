#!/usr/bin/env bash
# Shared bats helpers for exercising PreToolUse hooks.
#
# A hook is a black box: JSON on stdin, JSON (or nothing) on stdout. These
# helpers keep the tests written in exactly those terms, so a test never has to
# know how a hook is implemented.

SAFETY_HOOKS="${BATS_TEST_DIRNAME}/../plugins/kokko-safety/hooks"

# Every test runs muted. Without this a sweep over the deny paths fires one
# system alert per assertion.
export KOKKO_SOUNDS=off

# run_hook <hook-script> <command> — feed a PreToolUse payload to a hook.
# Sets $output to whatever the hook wrote on stdout.
run_hook() {
    local hook="$1" cmd="$2"
    jq -n --arg c "$cmd" '{hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: {command: $c}}' \
        | bash "$SAFETY_HOOKS/$hook"
}

# decision_of <hook> <command> — the permissionDecision a hook returns, or the
# literal string "allow" when the hook stays silent (which is how a hook says
# "no opinion, carry on").
decision_of() {
    local out
    out="$(run_hook "$1" "$2")"
    [[ -z "$out" ]] && { echo "allow"; return 0; }
    printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "allow"'
}

# assert_decision <expected> <hook> <command>
assert_decision() {
    local expected="$1" hook="$2" cmd="$3" actual
    actual="$(decision_of "$hook" "$cmd")"
    if [[ "$actual" != "$expected" ]]; then
        printf 'expected %s but got %s\n  hook:    %s\n  command: %s\n' \
            "$expected" "$actual" "$hook" "$cmd" >&2
        return 1
    fi
}

# assert_valid_json <hook> <command> — a hook that emits malformed JSON is
# ignored by Claude Code, which means it silently stops guarding.
assert_valid_json() {
    local out
    out="$(run_hook "$1" "$2")"
    [[ -z "$out" ]] && return 0
    printf '%s' "$out" | jq -e . >/dev/null
}

# =====================
# Throwaway git repos
# =====================
# The dirty-tree rules are the whole point of guard-git.sh, so the tests need
# real repositories in both states rather than mocks.

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

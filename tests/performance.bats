#!/usr/bin/env bats
# Latency budget for the PreToolUse guards.
#
# These run on EVERY Bash tool call, in the interactive path, before the command
# executes. The previous matcher ran one `echo | grep` per pattern -- about
# 2,600 processes per invocation, measured at ~1.65s of added latency per Bash
# call. lib/patterns.sh composes one grep -f instead: ~63ms, a 26x improvement.
#
# The budget below is deliberately loose (10x the measured figure) so this fails
# on an architectural regression -- someone reintroducing a per-pattern loop --
# and not on a slow CI runner.

load helpers/hook

BUDGET_MS=650

elapsed_ms() {
    local start end
    start=$(date +%s%N)
    "$@" >/dev/null 2>&1
    end=$(date +%s%N)
    echo $(( (end - start) / 1000000 ))
}

@test "guard-bash.sh stays inside the latency budget on a benign command" {
    ms="$(elapsed_ms run_hook guard-bash.sh "ls -la")"
    echo "guard-bash.sh: ${ms}ms (budget ${BUDGET_MS}ms)" >&2
    [ "$ms" -lt "$BUDGET_MS" ]
}

@test "guard-cloud.sh stays inside the latency budget on a benign command" {
    ms="$(elapsed_ms run_hook guard-cloud.sh "ls -la")"
    echo "guard-cloud.sh: ${ms}ms (budget ${BUDGET_MS}ms)" >&2
    [ "$ms" -lt "$BUDGET_MS" ]
}

@test "guard-git.sh stays inside the latency budget on a non-git command" {
    ms="$(elapsed_ms run_hook guard-git.sh "ls -la")"
    echo "guard-git.sh: ${ms}ms (budget ${BUDGET_MS}ms)" >&2
    [ "$ms" -lt "$BUDGET_MS" ]
}

@test "the matcher composes exactly one grep invocation per guard" {
    # Structural assertion, not a timing one: a loop calling grep per pattern is
    # the regression this whole file exists to prevent.
    ! grep -qE 'for[[:space:]]+pattern' "$SAFETY_HOOKS/lib/patterns.sh"
    grep -q 'grep -qE -f' "$SAFETY_HOOKS/lib/patterns.sh"
}

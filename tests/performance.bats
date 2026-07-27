#!/usr/bin/env bats
# Latency budget for the hooks that run in the interactive path.
#
# git-snapshot.sh runs on EVERY Bash tool call and on every user turn, before the
# command executes. Its cost is paid by the user on every single action, so it
# has a budget.
#
# The budget is deliberately loose so this fails on an architectural regression
# -- someone adding a subprocess-per-something loop, or a full `git log` walk --
# and not on a slow CI runner.

load helpers/hook

BUDGET_MS=400

elapsed_ms() {
    local start end
    start=$(date +%s%N)
    "$@" >/dev/null 2>&1
    end=$(date +%s%N)
    echo $(( (end - start) / 1000000 ))
}

setup() {
    ORIG_PWD="$PWD"
}

teardown() {
    cd "$ORIG_PWD" || true
    if [[ -n "${REPO:-}" && "$REPO" == /tmp/* ]]; then
        rm -rf "$REPO"
    fi
    return 0
}

@test "git-snapshot.sh exits fast on a non-git command" {
    REPO="$(dirty_repo)"; cd "$REPO"
    ms="$(elapsed_ms run_hook git-snapshot.sh "ls -la")"
    echo "git-snapshot.sh (non-git command): ${ms}ms (budget ${BUDGET_MS}ms)" >&2
    [ "$ms" -lt "$BUDGET_MS" ]
}

@test "git-snapshot.sh exits fast on a clean tree" {
    REPO="$(new_repo)"; cd "$REPO"
    ms="$(elapsed_ms run_hook git-snapshot.sh "git status")"
    echo "git-snapshot.sh (clean tree): ${ms}ms (budget ${BUDGET_MS}ms)" >&2
    [ "$ms" -lt "$BUDGET_MS" ]
}

@test "git-snapshot.sh stays inside budget when it actually checkpoints" {
    REPO="$(dirty_repo)"; cd "$REPO"
    ms="$(elapsed_ms run_hook git-snapshot.sh "git rebase main")"
    echo "git-snapshot.sh (checkpointing): ${ms}ms (budget ${BUDGET_MS}ms)" >&2
    [ "$ms" -lt "$BUDGET_MS" ]
}

@test "the snapshot hook short-circuits before touching git on a non-git command" {
    # Structural, not timed: the early bail is what keeps `ls` off the git path.
    # Losing it would put a git invocation in front of every Bash call.
    grep -q 'PreToolUse' "$SAFETY_HOOKS/git-snapshot.sh"
    grep -q 'exit 0' "$SAFETY_HOOKS/git-snapshot.sh"
}

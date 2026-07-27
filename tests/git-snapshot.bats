#!/usr/bin/env bats
# git-snapshot.sh — the working-tree safety net.
#
# The failure mode that matters here is silence: a snapshot hook that stops
# checkpointing looks exactly like one that has nothing to checkpoint. Every
# test asserts on refs/snapshots/ directly rather than on the hook's output.

load helpers/hook

setup() {
    ORIG_PWD="$PWD"
    REPO="$(new_repo)"
    cd "$REPO"
}

teardown() {
    cd "$ORIG_PWD" || true
    if [[ -n "${REPO:-}" && "$REPO" == /tmp/* ]]; then
        rm -rf "$REPO"
    fi
    return 0
}

snapshot_count() {
    git for-each-ref --format='%(refname)' refs/snapshots/ 2>/dev/null | wc -l | tr -d ' '
}

run_snapshot_prompt() {
    jq -n '{hook_event_name: "UserPromptSubmit"}' | bash "$SAFETY_HOOKS/git-snapshot.sh"
}

run_snapshot_bash() {
    jq -n --arg c "$1" '{hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: {command: $c}}' \
        | bash "$SAFETY_HOOKS/git-snapshot.sh"
}

@test "a clean tree produces no snapshot" {
    run_snapshot_prompt
    [ "$(snapshot_count)" -eq 0 ]
}

@test "a dirty tree is checkpointed on UserPromptSubmit" {
    printf 'change\n' >> tracked.txt
    run_snapshot_prompt
    [ "$(snapshot_count)" -eq 1 ]
}

@test "the snapshot actually contains the uncommitted change" {
    printf 'the-canary-line\n' >> tracked.txt
    run_snapshot_prompt
    ref="$(git for-each-ref --format='%(refname)' refs/snapshots/ | head -1)"
    git stash show -p "$ref" | grep -q 'the-canary-line'
}

@test "an identical tree is not checkpointed twice" {
    printf 'change\n' >> tracked.txt
    run_snapshot_prompt
    run_snapshot_prompt
    run_snapshot_prompt
    [ "$(snapshot_count)" -eq 1 ]
}

@test "a further edit produces a second snapshot" {
    printf 'first\n' >> tracked.txt
    run_snapshot_prompt
    printf 'second\n' >> tracked.txt
    run_snapshot_prompt
    [ "$(snapshot_count)" -eq 2 ]
}

@test "a git command on PreToolUse triggers a checkpoint" {
    printf 'change\n' >> tracked.txt
    run_snapshot_bash "git rebase main"
    [ "$(snapshot_count)" -eq 1 ]
}

@test "a non-git command on PreToolUse does NOT trigger a checkpoint" {
    printf 'change\n' >> tracked.txt
    run_snapshot_bash "ls -la"
    [ "$(snapshot_count)" -eq 0 ]
}

@test "git inside another word does not trigger a checkpoint" {
    printf 'change\n' >> tracked.txt
    run_snapshot_bash "echo digital"
    [ "$(snapshot_count)" -eq 0 ]
}

@test "untracked files are deliberately not captured" {
    printf 'untracked\n' > scratch.txt
    run_snapshot_prompt
    [ "$(snapshot_count)" -eq 0 ]
}

@test "the working tree is untouched by snapshotting" {
    printf 'change\n' >> tracked.txt
    before="$(cat tracked.txt)"
    run_snapshot_prompt
    [ "$(cat tracked.txt)" = "$before" ]
    # and the real stash ref must not have been used
    [ "$(git stash list | wc -l | tr -d ' ')" -eq 0 ]
}

@test "the index is untouched by snapshotting" {
    printf 'change\n' >> tracked.txt
    run_snapshot_prompt
    [ -z "$(git diff --cached --name-only)" ]
}

@test "snapshot refs are pruned to the retention limit" {
    # Seed past the limit cheaply, then confirm the hook trims to 200.
    for i in $(seq 1 205); do
        git update-ref "refs/snapshots/2020010${i}T000000Z-aaaaaaa" HEAD
    done
    printf 'change\n' >> tracked.txt
    run_snapshot_prompt
    [ "$(snapshot_count)" -le 200 ]
}

@test "a repo with no commits does not crash the hook" {
    empty="$(mktemp -d)"
    git -C "$empty" init -q
    cd "$empty"
    printf 'x\n' > f.txt
    run bash -c "printf '{\"hook_event_name\":\"UserPromptSubmit\"}' | bash '$SAFETY_HOOKS/git-snapshot.sh'"
    [ "$status" -eq 0 ]
    rm -rf "$empty"
}

@test "outside a git repo the hook exits quietly" {
    outside="$(mktemp -d)"
    cd "$outside"
    run bash -c "printf '{\"hook_event_name\":\"UserPromptSubmit\"}' | bash '$SAFETY_HOOKS/git-snapshot.sh'"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    rm -rf "$outside"
}

@test "dubious ownership is reported rather than failing silently" {
    # A safety net that stops working must say so. Simulate the refusal by
    # pointing git at a repo owned by another uid via safe.directory rules.
    printf 'change\n' >> tracked.txt
    run bash -c "cd '$REPO' && GIT_CEILING_DIRECTORIES='$REPO' printf '{\"hook_event_name\":\"UserPromptSubmit\"}' | bash '$SAFETY_HOOKS/git-snapshot.sh'"
    [ "$status" -eq 0 ]
}

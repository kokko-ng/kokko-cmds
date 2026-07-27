#!/usr/bin/env bats
# guard-git.sh — the deny rules, the allow paths, and the false positives that
# earlier versions of this hook actually shipped.

load helpers/hook

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

# ---------------------------------------------------------------------------
# Unconditional denies — destructive whether or not the tree is dirty.
# ---------------------------------------------------------------------------

@test "git clean -fd is denied (untracked files have no snapshot)" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git clean -fd"
}

@test "git clean -fdx is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git clean -fdx"
}

@test "force push is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git push --force origin feature"
}

@test "force-with-lease is denied too" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git push --force-with-lease origin feature"
}

@test "short -f force push is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git push -f origin feature"
}

@test "filter-branch is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git filter-branch --tree-filter true HEAD"
}

@test "reflog expire is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git reflog expire --all"
}

@test "gc --prune is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git gc --prune=now"
}

@test "deleting a snapshot ref by hand is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git update-ref -d refs/snapshots/20250101T000000Z-abc1234"
}

@test "git add . is denied on a clean tree" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git add ."
}

@test "git add -A is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git add -A"
}

@test "stash drop is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git stash drop stash@{0}"
}

# ---------------------------------------------------------------------------
# Dirty-tree denies — the same commands are allowed on a clean tree.
# ---------------------------------------------------------------------------

@test "rebase is denied against a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git rebase main"
}

@test "rebase is ALLOWED against a clean tree (reflog-recoverable)" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git rebase main"
}

@test "reset is denied against a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git reset --hard HEAD~1"
}

@test "reset is ALLOWED against a clean tree" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git reset --hard HEAD~1"
}

@test "git restore is denied against a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git restore tracked.txt"
}

@test "git stash is denied against a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git stash"
}

@test "forced checkout is denied against a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git checkout -f main"
}

@test "checkout . is denied against a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git checkout ."
}

@test "checkout ref -- path is denied against a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git checkout main -- tracked.txt"
}

@test "branch -f is denied against a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git branch -f main HEAD~1"
}

@test "global options before the subcommand do not evade the guard" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git -C . rebase main"
}

@test "sh -c quoting does not evade the guard" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "sh -c 'git rebase main'"
}

@test "a git command after && does not evade the guard" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "cd /tmp && git rebase main"
}

# ---------------------------------------------------------------------------
# False positives. Every case here is one the hook's own comments cite as
# having been a real problem, or a routine command that must never be blocked.
# ---------------------------------------------------------------------------

@test "git inside a word is not matched (digit restore)" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "echo 'the last digit restore is fine'"
}

@test "git inside a string literal is not matched" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "echo \"never run git reset --hard\""
}

@test "git add of a dotted path is not treated as git add ." {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git add .claude/settings.json"
}

@test "git add .gitignore is allowed" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git add .gitignore"
}

@test "git status is allowed on a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git status"
}

@test "git diff is allowed on a dirty tree" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git diff --stat"
}

@test "git log is allowed" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git log --oneline -5"
}

@test "pushing a feature branch while sitting on main is allowed" {
    REPO="$(new_repo)"; cd "$REPO"
    git checkout -q -B main
    assert_decision allow guard-git.sh "git push -u origin feature-branch"
}

@test "git worktree add is allowed (kokko-janitor depends on it)" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git worktree add ../wt-check-types"
}

@test "git worktree remove is allowed (was blocked by the old git.txt)" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git worktree remove ../wt-check-types"
}

@test "git stash create is allowed - it is what the snapshot hook uses" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git stash create claude-snapshot"
}

@test "non-git commands are ignored entirely" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "ls -la"
}

# ---------------------------------------------------------------------------
# Protected branches
# ---------------------------------------------------------------------------

@test "committing on main asks" {
    REPO="$(new_repo)"; cd "$REPO"
    git checkout -q -B main
    assert_decision ask guard-git.sh "git commit -m 'fix: thing'"
}

@test "committing on a feature branch is allowed" {
    REPO="$(new_repo)"; cd "$REPO"
    git checkout -q -b feature/thing
    assert_decision allow guard-git.sh "git commit -m 'fix: thing'"
}

@test "pushing explicitly to main asks, even from a feature branch" {
    REPO="$(new_repo)"; cd "$REPO"
    git checkout -q -b feature/thing
    assert_decision ask guard-git.sh "git push origin main"
}

@test "a bare git push while on main asks" {
    REPO="$(new_repo)"; cd "$REPO"
    git checkout -q -B main
    assert_decision ask guard-git.sh "git push"
}

@test "git stash list is allowed" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git stash list"
}

@test "git stash show is allowed" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git stash show -p stash@{0}"
}

@test "rebase on main against a dirty tree still DENIES rather than asks" {
    REPO="$(dirty_repo)"; cd "$REPO"
    git checkout -q -B main
    assert_decision deny guard-git.sh "git rebase origin/main"
}

# ---------------------------------------------------------------------------
# Override and robustness
# ---------------------------------------------------------------------------

@test "an inline CLAUDE_GIT_GUARD=off prefix bypasses the guard" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "CLAUDE_GIT_GUARD=off git rebase main"
}

@test "the ambient CLAUDE_GIT_GUARD=off bypasses the guard" {
    REPO="$(dirty_repo)"; cd "$REPO"
    CLAUDE_GIT_GUARD=off run assert_decision allow guard-git.sh "git rebase main"
    [ "$status" -eq 0 ]
}

@test "every deny emits well-formed JSON" {
    REPO="$(dirty_repo)"; cd "$REPO"
    assert_valid_json guard-git.sh "git rebase main"
    assert_valid_json guard-git.sh "git clean -fd"
    assert_valid_json guard-git.sh "git push --force origin main"
}

@test "a deny reason is always non-empty" {
    REPO="$(dirty_repo)"; cd "$REPO"
    reason="$(run_hook guard-git.sh "git rebase main" | jq -r '.hookSpecificOutput.permissionDecisionReason')"
    [ -n "$reason" ]
    [ "$reason" != "null" ]
}

@test "empty stdin does not crash the hook" {
    REPO="$(new_repo)"; cd "$REPO"
    run bash -c "printf '' | bash '$SAFETY_HOOKS/guard-git.sh'"
    [ "$status" -eq 0 ]
}

@test "malformed stdin does not crash the hook" {
    REPO="$(new_repo)"; cd "$REPO"
    run bash -c "printf 'not json at all' | bash '$SAFETY_HOOKS/guard-git.sh'"
    [ "$status" -eq 0 ]
}

@test "a missing command field does not crash the hook" {
    REPO="$(new_repo)"; cd "$REPO"
    run bash -c "printf '{\"tool_input\":{}}' | bash '$SAFETY_HOOKS/guard-git.sh'"
    [ "$status" -eq 0 ]
}

@test "outside a git repo the hook still denies the unconditional rules" {
    cd "$(mktemp -d)"
    assert_decision deny guard-git.sh "git clean -fd"
}

@test "force push with the flag in trailing position is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git push origin feature --force"
}

@test "force push with -f trailing is denied" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision deny guard-git.sh "git push origin feature -f"
}

@test "a branch named after a flag does not false-positive as force push" {
    REPO="$(new_repo)"; cd "$REPO"
    assert_decision allow guard-git.sh "git push origin feature-fix"
}

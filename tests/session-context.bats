#!/usr/bin/env bats
# session-context.sh — project detection and the git safety briefing.

load helpers/hook

setup() {
    ORIG_PWD="$PWD"
    WORK="$(mktemp -d)"
}

teardown() {
    cd "$ORIG_PWD" || true
    if [[ -n "${WORK:-}" && "$WORK" == /tmp/* ]]; then
        rm -rf "$WORK"
    fi
    return 0
}

context_for() {
    jq -n --arg d "$1" '{hook_event_name: "SessionStart", cwd: $d}' \
        | bash "$SAFETY_HOOKS/session-context.sh" \
        | jq -r '.hookSpecificOutput.additionalContext'
}

@test "output is well-formed SessionStart JSON" {
    out="$(jq -n --arg d "$WORK" '{hook_event_name:"SessionStart", cwd:$d}' | bash "$SAFETY_HOOKS/session-context.sh")"
    printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null
}

@test "a python project is detected" {
    touch "$WORK/pyproject.toml"
    context_for "$WORK" | grep -q "Type: python"
}

@test "a typescript project is detected" {
    touch "$WORK/package.json" "$WORK/tsconfig.json"
    context_for "$WORK" | grep -q "Type: typescript"
}

@test "a node project without tsconfig is nodejs" {
    touch "$WORK/package.json"
    context_for "$WORK" | grep -q "Type: nodejs"
}

@test "a go project is detected" {
    touch "$WORK/go.mod"
    context_for "$WORK" | grep -q "Type: go"
}

@test "a rust project is detected" {
    touch "$WORK/Cargo.toml"
    context_for "$WORK" | grep -q "Type: rust"
}

@test "a dotnet project is detected via csproj" {
    touch "$WORK/Api.csproj"
    context_for "$WORK" | grep -q "dotnet"
}

@test "a dotnet project is detected via sln" {
    touch "$WORK/Solution.sln"
    context_for "$WORK" | grep -q "dotnet"
}

@test "a dotnet project is detected one level down" {
    mkdir -p "$WORK/src"
    touch "$WORK/src/Api.csproj"
    context_for "$WORK" | grep -q "dotnet"
}

@test "a polyglot repo reports every stack, not just the last one" {
    touch "$WORK/pyproject.toml" "$WORK/package.json" "$WORK/tsconfig.json"
    out="$(context_for "$WORK")"
    printf '%s' "$out" | grep -q "mixed"
    printf '%s' "$out" | grep -q "python"
    printf '%s' "$out" | grep -q "typescript"
}

@test "a python plus dotnet repo reports both" {
    touch "$WORK/pyproject.toml" "$WORK/Api.csproj"
    out="$(context_for "$WORK")"
    printf '%s' "$out" | grep -q "python"
    printf '%s' "$out" | grep -q "dotnet"
}

@test "an empty directory reports unknown" {
    context_for "$WORK" | grep -q "Type: unknown"
}

@test "outside a git repo no safety briefing is emitted" {
    out="$(context_for "$WORK")"
    printf '%s' "$out" | grep -q "not in a git repo"
    ! printf '%s' "$out" | grep -q "Protecting uncommitted work"
}

@test "inside a git repo the safety briefing is emitted" {
    repo="$(new_repo)"
    out="$(context_for "$repo")"
    printf '%s' "$out" | grep -q "Protecting uncommitted work"
    printf '%s' "$out" | grep -q "refs/snapshots/"
    rm -rf "$repo"
}

@test "the branch name is reported" {
    repo="$(new_repo)"
    git -C "$repo" checkout -q -b feature/thing
    context_for "$repo" | grep -q "Branch: feature/thing"
    rm -rf "$repo"
}

@test "a clean tree reports zero uncommitted files and no ATTENTION block" {
    repo="$(new_repo)"
    out="$(context_for "$repo")"
    printf '%s' "$out" | grep -q "Uncommitted tracked files: 0"
    ! printf '%s' "$out" | grep -q "ATTENTION"
    rm -rf "$repo"
}

@test "a dirty tree raises the ATTENTION block with a count" {
    repo="$(dirty_repo)"
    out="$(context_for "$repo")"
    printf '%s' "$out" | grep -q "Uncommitted tracked files: 1"
    printf '%s' "$out" | grep -q "ATTENTION"
    rm -rf "$repo"
}

@test "the recovery instructions do not depend on the snaps wrapper alone" {
    repo="$(new_repo)"
    context_for "$repo" | grep -q "git for-each-ref refs/snapshots/"
    rm -rf "$repo"
}

@test "a nonexistent cwd does not crash the hook" {
    run bash -c "jq -n '{hook_event_name:\"SessionStart\", cwd:\"/nope/nowhere\"}' | bash '$SAFETY_HOOKS/session-context.sh'"
    [ "$status" -eq 0 ]
}

@test "empty stdin does not crash the hook" {
    run bash -c "printf '' | bash '$SAFETY_HOOKS/session-context.sh'"
    [ "$status" -eq 0 ]
}

@test "the briefing states plainly that nothing blocks" {
    repo="$(new_repo)"
    out="$(context_for "$repo")"
    printf '%s' "$out" | grep -q "NOTHING BLOCKS YOU"
    printf '%s' "$out" | grep -q "There is NO guard hook"
    rm -rf "$repo"
}

@test "the briefing does not claim commands are blocked" {
    repo="$(dirty_repo)"
    out="$(context_for "$repo")"
    ! printf '%s' "$out" | grep -q "are BLOCKED"
    ! printf '%s' "$out" | grep -qi "the guard is right"
    rm -rf "$repo"
}

@test "the briefing still carries the work-loss rules" {
    repo="$(new_repo)"
    out="$(context_for "$repo")"
    printf '%s' "$out" | grep -q "git status --short --untracked-files=no"
    printf '%s' "$out" | grep -q "never .git add ."
    printf '%s' "$out" | grep -q "Commit before anything that rewrites history"
    printf '%s' "$out" | grep -q "docker/az acr build ship what is"
    rm -rf "$repo"
}

@test "the briefing warns that git clean has no recovery path" {
    repo="$(new_repo)"
    context_for "$repo" | grep -q "Untracked files are NOT snapshotted"
    rm -rf "$repo"
}

@test "the session hook never returns a permission decision" {
    assert_no_decision session-context.sh "git rebase main"
}

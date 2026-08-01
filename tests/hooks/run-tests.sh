#!/usr/bin/env bash
# run-tests.sh - Table-driven test harness for the kokko-safety hooks and the
# shared play-sound utility. Plain bash, no test framework required.
#
# Usage: bash tests/hooks/run-tests.sh
#
# Each case feeds a real JSON payload (built with jq) through the actual hook
# script and asserts on the parsed permissionDecision:
#   ask  -> the hook must emit a PreToolUse "ask" decision
#   pass -> the hook must emit nothing (command allowed through)
# Any non-empty hook output must also be valid JSON.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS="$ROOT/plugins/kokko-safety/hooks"
export KOKKO_SOUNDS=off

PASS_COUNT=0
FAIL_COUNT=0
RESULTS=()

record() { # status name detail
    local status="$1" name="$2" detail="${3:-}"
    if [ "$status" = PASS ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    RESULTS+=("$(printf '%-4s  %s%s' "$status" "$name" "${detail:+  [$detail]}")")
}

payload() { # command -> JSON payload on stdout
    jq -n --arg c "$1" \
        '{session_id: "test", hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: {command: $c}}'
}

# decision <hook> <command> [cwd] -> prints ask|pass|invalid-json|error:<rc>
decision() {
    local hook="$1" cmd="$2" cwd="${3:-$ROOT}" out rc
    out=$( (cd "$cwd" && payload "$cmd" | "$HOOKS/$hook") 2>/dev/null )
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "error:$rc"
        return
    fi
    if [ -z "$out" ]; then
        echo "pass"
        return
    fi
    if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
        echo "invalid-json"
        return
    fi
    printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "pass"'
}

expect() { # hook command expected(ask|pass) [cwd] [label]
    local hook="$1" cmd="$2" want="$3" cwd="${4:-$ROOT}" label="${5:-}"
    local got
    got=$(decision "$hook" "$cmd" "$cwd")
    local name="${hook%.sh}: ${label:-$cmd}"
    if [ "$got" = "$want" ]; then
        record PASS "$name"
    else
        record FAIL "$name" "want=$want got=$got"
    fi
}

# ---------------------------------------------------------------------------
# pre-tool-destructive-bash.sh
# ---------------------------------------------------------------------------
BASH_HOOK=pre-tool-destructive-bash.sh

# Dangerous forms must still ask
expect "$BASH_HOOK" 'rm -rf /tmp/build' ask
expect "$BASH_HOOK" 'rm -rf ~/project' ask
expect "$BASH_HOOK" '-n rm -rf /' ask '' 'command starting with echo-eating -n'
expect "$BASH_HOOK" 'wipe /dev/sda' ask
expect "$BASH_HOOK" 'rmdir old-dir' ask
expect "$BASH_HOOK" 'shutdown now' ask
expect "$BASH_HOOK" 'mkfs.ext4 /dev/sda1' ask
expect "$BASH_HOOK" 'echo pwned > /etc/passwd' ask
expect "$BASH_HOOK" 'chmod 777 file' ask
expect "$BASH_HOOK" 'chmod 0777 file' ask
expect "$BASH_HOOK" 'chmod 666 secrets.txt' ask
expect "$BASH_HOOK" 'chmod -R 777 .' ask
expect "$BASH_HOOK" 'chmod -R 755 /etc' ask
expect "$BASH_HOOK" 'chmod -R 700 /' ask
expect "$BASH_HOOK" 'docker-compose down' ask
expect "$BASH_HOOK" 'docker-compose rm' ask
expect "$BASH_HOOK" 'docker-compose kill' ask
expect "$BASH_HOOK" 'docker-compose stop' ask
expect "$BASH_HOOK" 'docker compose down -v' ask
expect "$BASH_HOOK" 'docker compose stop web' ask
expect "$BASH_HOOK" 'drop table users' ask
expect "$BASH_HOOK" 'psql -c "DROP TABLE users"' ask
expect "$BASH_HOOK" 'dd if=/dev/zero of=/dev/sda' ask

# False positives fixed in the pattern corpus must now pass through
expect "$BASH_HOOK" 'swipe left' pass '' 'swipe is not wipe'
expect "$BASH_HOOK" 'git help swipe' pass
expect "$BASH_HOOK" 'echo hi > /tmp/x' pass '' 'redirect to /tmp is routine'
expect "$BASH_HOOK" 'sort data.txt > /home/user/out.txt' pass '' 'redirect to home path'
expect "$BASH_HOOK" 'chmod 0644 file' pass
expect "$BASH_HOOK" 'chmod 0755 script.sh' pass
expect "$BASH_HOOK" 'chmod 755 script.sh' pass
expect "$BASH_HOOK" 'chmod -R 755 ./build' pass '' 'project-local chmod -R'
expect "$BASH_HOOK" 'docker composer require foo/bar' pass
expect "$BASH_HOOK" 'ls -la' pass
expect "$BASH_HOOK" 'backdrop table settings' pass

# ---------------------------------------------------------------------------
# pre-tool-destructive-git.sh
# ---------------------------------------------------------------------------
GIT_HOOK=pre-tool-destructive-git.sh

expect "$GIT_HOOK" 'git push --force origin main' ask
expect "$GIT_HOOK" 'git reset --hard HEAD~1' ask
expect "$GIT_HOOK" 'git clean -fd' ask
expect "$GIT_HOOK" 'git branch -D topic' ask
expect "$GIT_HOOK" 'git rebase -i HEAD~3' ask
expect "$GIT_HOOK" 'git rebase --onto main base topic' ask

# Recovery commands must never prompt (they get you OUT of a bad rebase)
expect "$GIT_HOOK" 'git rebase --continue' pass
expect "$GIT_HOOK" 'git rebase --abort' pass
expect "$GIT_HOOK" 'git rebase --skip' pass
# Direct push to main is owned by branch protection, not git.txt (no double prompt)
expect "$GIT_HOOK" 'git push origin main' pass '' 'push to main owned by branch-protection'
expect "$GIT_HOOK" 'git status' pass
expect "$GIT_HOOK" 'git commit -m "docs: mention swipe gesture"' pass

# ---------------------------------------------------------------------------
# pre-tool-cloud-ops.sh
# ---------------------------------------------------------------------------
CLOUD_HOOK=pre-tool-cloud-ops.sh

expect "$CLOUD_HOOK" 'aws s3 rm s3://bucket --recursive' ask
expect "$CLOUD_HOOK" 'terraform destroy' ask
expect "$CLOUD_HOOK" 'kubectl delete namespace prod' ask
expect "$CLOUD_HOOK" 'az group delete -n rg-prod' ask
expect "$CLOUD_HOOK" 'aws s3 ls' pass
expect "$CLOUD_HOOK" 'terraform plan' pass
expect "$CLOUD_HOOK" 'kubectl get pods' pass

# ---------------------------------------------------------------------------
# pre-tool-branch-protection.sh (needs real git repos)
# ---------------------------------------------------------------------------
BP_HOOK=pre-tool-branch-protection.sh
TMPDIR_TESTS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TESTS"' EXIT

make_repo() { # dir branch
    git init -q -b main "$1"
    git -C "$1" -c user.email=t@test -c user.name=test commit -q --allow-empty -m init
    if [ "$2" != main ]; then
        git -C "$1" checkout -q -b "$2"
    fi
}
MAIN_REPO="$TMPDIR_TESTS/mainrepo"
FEAT_REPO="$TMPDIR_TESTS/featrepo"
QUOTE_REPO="$TMPDIR_TESTS/quoterepo"
make_repo "$MAIN_REPO" main
make_repo "$FEAT_REPO" feature
make_repo "$QUOTE_REPO" 'we"ird'

expect "$BP_HOOK" 'git commit -m x' ask "$MAIN_REPO" 'commit while on main'
expect "$BP_HOOK" 'git push origin main' ask "$MAIN_REPO" 'push while on main'
expect "$BP_HOOK" 'git commit -m x' pass "$FEAT_REPO" 'commit on feature branch'
expect "$BP_HOOK" 'git push origin feature' pass "$FEAT_REPO" 'plain push on feature branch'
# Force flag before remote, between remote and branch, and after branch (item 15)
expect "$BP_HOOK" 'git push --force origin main' ask "$FEAT_REPO" 'force flag before remote'
expect "$BP_HOOK" 'git push origin --force main' ask "$FEAT_REPO" 'force flag between remote and branch'
expect "$BP_HOOK" 'git push origin main --force' ask "$FEAT_REPO" 'force flag after branch'
expect "$BP_HOOK" 'git push origin -f main' ask "$FEAT_REPO" '-f between remote and branch'
expect "$BP_HOOK" 'git push --force-with-lease origin main' ask "$FEAT_REPO" 'force-with-lease'
expect "$BP_HOOK" 'git push origin feature --force' pass "$FEAT_REPO" 'force push to unprotected branch'
# Directory parsing (item 14): cd <dir> && ... and git -C <dir>
expect "$BP_HOOK" "cd $MAIN_REPO && git commit -m x" ask "$TMPDIR_TESTS" 'cd protected-repo && commit'
expect "$BP_HOOK" "git -C $MAIN_REPO commit -m x" ask "$TMPDIR_TESTS" 'git -C protected-repo commit'
expect "$BP_HOOK" "cd $FEAT_REPO && git commit -m x" pass "$MAIN_REPO" 'cd feature-repo && commit overrides cwd'
expect "$BP_HOOK" 'git commit -m x' pass "$TMPDIR_TESTS" 'not in a git repo'
expect "$BP_HOOK" 'ls -la' pass "$MAIN_REPO" 'non-git command on main'

# Branch name containing a double quote: output must be valid JSON (item 4)
bp_quote_out=$( (cd "$QUOTE_REPO" && payload 'git push --force origin main' | "$HOOKS/$BP_HOOK") 2>/dev/null )
if printf '%s' "$bp_quote_out" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null 2>&1; then
    record PASS "$BP_HOOK: valid JSON with double quote in branch name"
else
    record FAIL "$BP_HOOK: valid JSON with double quote in branch name" "output=$bp_quote_out"
fi

# ---------------------------------------------------------------------------
# Fail-closed paths: jq missing and malformed JSON (all four PreToolUse hooks)
# ---------------------------------------------------------------------------
EMPTY_PATH_DIR="$TMPDIR_TESTS/emptybin"
mkdir -p "$EMPTY_PATH_DIR"

for hook in "$BASH_HOOK" "$GIT_HOOK" "$CLOUD_HOOK" "$BP_HOOK"; do
    out=$(payload 'rm -rf /' | env PATH="$EMPTY_PATH_DIR" "$HOOKS/$hook" 2>/dev/null)
    rc=$?
    if [ "$rc" -eq 0 ] \
        && printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null 2>&1 \
        && printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecisionReason | test("jq is missing")' >/dev/null 2>&1; then
        record PASS "${hook%.sh}: fails closed to ask when jq is missing"
    else
        record FAIL "${hook%.sh}: fails closed to ask when jq is missing" "rc=$rc output=$out"
    fi

    out=$(printf 'this is not json' | "$HOOKS/$hook" 2>/dev/null)
    rc=$?
    if [ "$rc" -eq 0 ] \
        && printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null 2>&1; then
        record PASS "${hook%.sh}: fails closed to ask on malformed JSON payload"
    else
        record FAIL "${hook%.sh}: fails closed to ask on malformed JSON payload" "rc=$rc output=$out"
    fi
done

# ---------------------------------------------------------------------------
# session-start-context.sh basic behavior
# ---------------------------------------------------------------------------
SS_HOOK=session-start-context.sh
out=$(jq -n --arg cwd "$MAIN_REPO" '{cwd: $cwd}' | "$HOOKS/$SS_HOOK" 2>/dev/null)
rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'PROJECT CONTEXT'; then
    record PASS "$SS_HOOK: emits project context for valid payload"
else
    record FAIL "$SS_HOOK: emits project context for valid payload" "rc=$rc"
fi
out=$(printf 'nope' | "$HOOKS/$SS_HOOK" 2>/dev/null)
rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
    record PASS "$SS_HOOK: silent no-op on malformed payload"
else
    record FAIL "$SS_HOOK: silent no-op on malformed payload" "rc=$rc output=$out"
fi

# ---------------------------------------------------------------------------
# play-sound.sh: both copies must stay quiet on stderr with no usable audio
# backend and no controlling terminal (the /dev/tty fallback path)
# ---------------------------------------------------------------------------
FAKEBIN="$TMPDIR_TESTS/fakebin"
mkdir -p "$FAKEBIN"
for tool in uname grep; do
    ln -sf "$(command -v $tool)" "$FAKEBIN/$tool"
done
SETSID=()
if command -v setsid >/dev/null 2>&1; then
    SETSID=("$(command -v setsid)" -w)
fi
for copy in \
    "$ROOT/plugins/kokko-notifications/hooks/utils/play-sound.sh" \
    "$ROOT/plugins/kokko-safety/hooks/utils/play-sound.sh"; do
    err=$( { env KOKKO_SOUNDS=on PATH="$FAKEBIN" "${SETSID[@]}" "$BASH" -c "source '$copy'; play_sound warning" >/dev/null </dev/null; } 2>&1 )
    rc=$?
    if [ "$rc" -eq 0 ] && [ -z "$err" ]; then
        record PASS "play-sound ($(basename "$(dirname "$(dirname "$(dirname "$copy")")")")): no stderr noise without a TTY"
    else
        record FAIL "play-sound ($(basename "$(dirname "$(dirname "$(dirname "$copy")")")")): no stderr noise without a TTY" "rc=$rc stderr=$err"
    fi
done

# The two copies must be byte-identical
if cmp -s "$ROOT/plugins/kokko-notifications/hooks/utils/play-sound.sh" \
          "$ROOT/plugins/kokko-safety/hooks/utils/play-sound.sh"; then
    record PASS "play-sound: notification and safety copies are byte-identical"
else
    record FAIL "play-sound: notification and safety copies are byte-identical"
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo
echo "kokko hook test results"
echo "-----------------------"
for line in "${RESULTS[@]}"; do
    echo "$line"
done
echo "-----------------------"
echo "passed: $PASS_COUNT  failed: $FAIL_COUNT  total: $((PASS_COUNT + FAIL_COUNT))"

[ "$FAIL_COUNT" -eq 0 ]

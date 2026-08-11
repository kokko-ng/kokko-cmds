#!/usr/bin/env bash
# run-tests.sh - Table-driven test harness for the kokko-notifications hooks
# and their shared play-sound utility. Plain bash, no test framework required.
#
# Usage: bash tests/hooks/run-tests.sh
#
# (The kokko-safety hook suite that used to live here was removed together
# with that plugin — permission decisions are Claude Code Auto mode's job
# now, not a pattern-matching hook layer's.)
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NOTIF_HOOKS="$ROOT/plugins/kokko-notifications/hooks"
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

TMPDIR_TESTS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TESTS"' EXIT

# ---------------------------------------------------------------------------
# stop-notification.sh: quiet, zero-exit behavior on every payload shape
# ---------------------------------------------------------------------------
STOP_HOOK="$NOTIF_HOOKS/stop-notification.sh"

run_stop() { # payload -> sets RC / OUT / ERR
    OUT=$(printf '%s' "$1" | "$STOP_HOOK" 2>"$TMPDIR_TESTS/err")
    RC=$?
    ERR=$(cat "$TMPDIR_TESTS/err")
}

run_stop '{"session_id":"t","hook_event_name":"Stop","stop_hook_active":false}'
if [ "$RC" -eq 0 ] && [ -z "$OUT" ] && [ -z "$ERR" ]; then
    record PASS "stop-notification: normal Stop payload exits 0 with no output"
else
    record FAIL "stop-notification: normal Stop payload exits 0 with no output" "rc=$RC out=$OUT err=$ERR"
fi

run_stop '{"session_id":"t","hook_event_name":"Stop","stop_hook_active":true}'
if [ "$RC" -eq 0 ] && [ -z "$OUT" ] && [ -z "$ERR" ]; then
    record PASS "stop-notification: stop_hook_active continuation is silent"
else
    record FAIL "stop-notification: stop_hook_active continuation is silent" "rc=$RC out=$OUT err=$ERR"
fi

run_stop 'this is not json'
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then
    record PASS "stop-notification: malformed payload does not crash"
else
    record FAIL "stop-notification: malformed payload does not crash" "rc=$RC err=$ERR"
fi

# ---------------------------------------------------------------------------
# play-sound.sh: must stay quiet on stderr with no usable audio backend and
# no controlling terminal (the /dev/tty fallback path)
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
PLAY_SOUND="$NOTIF_HOOKS/utils/play-sound.sh"
err=$( { env KOKKO_SOUNDS=on PATH="$FAKEBIN" "${SETSID[@]}" "$BASH" -c "source '$PLAY_SOUND'; play_sound warning" >/dev/null </dev/null; } 2>&1 )
rc=$?
if [ "$rc" -eq 0 ] && [ -z "$err" ]; then
    record PASS "play-sound: no stderr noise without a TTY"
else
    record FAIL "play-sound: no stderr noise without a TTY" "rc=$rc stderr=$err"
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

#!/bin/bash
# stop-notification.sh - Play a sound when Claude finishes a turn.
# Stop
#
# This used to branch on `.reason` from the Stop payload:
#
#     stop_reason=$(echo "$input" | jq -r '.reason // "unknown"')
#     case "$stop_reason" in
#         "end_turn")            play_sound "completion" ;;
#         "interrupted")         ;;   # deliberately silent
#         ...
#         *)                     play_sound "info" ;;
#     esac
#
# Claude Code does not send a `reason` field on Stop. The payload is
# {session_id, transcript_path, hook_event_name, stop_hook_active}. So the jq
# fallback made stop_reason "unknown" every single time, every branch was dead,
# and control fell to the `*)` wildcard -- meaning a sound played on EVERY stop,
# including the "interrupted" case that was written to be silent. Interrupting
# Claude to complain about the noise therefore made the noise. At the old
# default gain of 10.0 it was relentless.
#
# Since the field the feature depended on does not exist, the per-reason
# behaviour cannot be recovered -- so this now does the one thing it can do
# honestly: one completion sound per turn, at unity gain.
#
# Silence it with KOKKO_SOUNDS=off, or disable the plugin in settings.json.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"

input=$(cat)

# stop_hook_active is true when Claude is already continuing as a result of a
# previous Stop hook -- do not chime again for the continuation.
if [ "$(echo "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ]; then
    exit 0
fi

play_sound "completion"
exit 0

#!/bin/bash
# stop-notification.sh - Play sound on task completion
# Stop - Plays different sounds based on stop reason

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"

input=$(cat)
stop_reason=$(echo "$input" | jq -r '.reason // "unknown"')

case "$stop_reason" in
    "end_turn")
        # Natural completion - success/completion sound
        play_sound "completion"
        ;;
    "max_tokens")
        # Hit token limit - info sound to indicate incomplete
        play_sound "info"
        ;;
    "interrupted"|"stop_sequence")
        # User interrupted or stop sequence hit - no sound
        ;;
    "tool_use")
        # Claude is calling a tool - no sound, work in progress
        ;;
    *)
        # Unknown reason - subtle info sound
        play_sound "info"
        ;;
esac

exit 0

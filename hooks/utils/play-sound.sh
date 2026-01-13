#!/bin/bash
# play-sound.sh - Cross-platform sound utility for Claude Code hooks
# Supports: macOS (afplay), Linux (paplay/aplay/speaker-test), Windows/WSL (PowerShell)

play_sound() {
    local sound_type="${1:-info}"
    local os_type
    os_type=$(uname -s)

    case "$os_type" in
        Darwin)
            # macOS: Use afplay with system sounds
            local sound_file
            case "$sound_type" in
                warning)    sound_file="/System/Library/Sounds/Basso.aiff" ;;
                error)      sound_file="/System/Library/Sounds/Sosumi.aiff" ;;
                success)    sound_file="/System/Library/Sounds/Glass.aiff" ;;
                info)       sound_file="/System/Library/Sounds/Pop.aiff" ;;
                completion) sound_file="/System/Library/Sounds/Hero.aiff" ;;
                *)          sound_file="/System/Library/Sounds/Pop.aiff" ;;
            esac
            [ -f "$sound_file" ] && afplay "$sound_file" &
            ;;

        Linux)
            # Check for WSL first
            if grep -qi microsoft /proc/version 2>/dev/null; then
                # WSL: Use PowerShell
                local sound_name
                case "$sound_type" in
                    warning)    sound_name="Asterisk" ;;
                    error)      sound_name="Hand" ;;
                    success)    sound_name="Exclamation" ;;
                    info)       sound_name="Question" ;;
                    completion) sound_name="Asterisk" ;;
                    *)          sound_name="Asterisk" ;;
                esac
                powershell.exe -Command "[System.Media.SystemSounds]::${sound_name}.Play()" 2>/dev/null &
            else
                # Native Linux: Try paplay, then aplay with generated tone
                local freq duration
                case "$sound_type" in
                    warning)    freq=440; duration=0.3 ;;
                    error)      freq=880; duration=0.4 ;;
                    success)    freq=660; duration=0.2 ;;
                    info)       freq=520; duration=0.15 ;;
                    completion) freq=770; duration=0.25 ;;
                    *)          freq=520; duration=0.15 ;;
                esac

                if command -v paplay &>/dev/null; then
                    # PulseAudio: Try freedesktop sounds
                    local sound_file
                    case "$sound_type" in
                        warning|error) sound_file="/usr/share/sounds/freedesktop/stereo/dialog-warning.oga" ;;
                        success)       sound_file="/usr/share/sounds/freedesktop/stereo/complete.oga" ;;
                        completion)    sound_file="/usr/share/sounds/freedesktop/stereo/message.oga" ;;
                        *)             sound_file="/usr/share/sounds/freedesktop/stereo/bell.oga" ;;
                    esac
                    if [ -f "$sound_file" ]; then
                        paplay "$sound_file" &
                    elif [ -f "/usr/share/sounds/freedesktop/stereo/bell.oga" ]; then
                        paplay "/usr/share/sounds/freedesktop/stereo/bell.oga" &
                    fi
                elif command -v speaker-test &>/dev/null; then
                    # ALSA: Generate tone
                    (speaker-test -t sine -f "$freq" -l 1 >/dev/null 2>&1 &
                     sleep "$duration" && pkill -f "speaker-test.*-f $freq" 2>/dev/null) &
                fi
            fi
            ;;

        MINGW*|MSYS*|CYGWIN*)
            # Windows Git Bash/MSYS/Cygwin
            local sound_name
            case "$sound_type" in
                warning)    sound_name="Asterisk" ;;
                error)      sound_name="Hand" ;;
                success)    sound_name="Exclamation" ;;
                info)       sound_name="Question" ;;
                completion) sound_name="Asterisk" ;;
                *)          sound_name="Asterisk" ;;
            esac
            powershell.exe -Command "[System.Media.SystemSounds]::${sound_name}.Play()" 2>/dev/null &
            ;;

        *)
            # Unknown OS: Try PowerShell as fallback (might be WSL variant)
            if command -v powershell.exe &>/dev/null; then
                powershell.exe -Command "[System.Media.SystemSounds]::Asterisk.Play()" 2>/dev/null &
            fi
            ;;
    esac
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    play_sound "$1"
fi

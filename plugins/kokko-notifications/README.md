# kokko-notifications

Sound notifications for Claude Code. A single Stop hook plays a completion
chime when Claude finishes a turn, so long-running work can be left alone.

```bash
/plugin install kokko-notifications@kokko-ng-kokko-cmds
```

## Hooks

| Hook | Purpose |
| ---- | ------- |
| `stop-notification` | Plays a completion sound when Claude finishes a turn |

## Environment variables

Sounds go through `hooks/utils/play-sound.sh`. It supports macOS (afplay),
Linux (paplay/aplay), WSL and Git Bash (PowerShell system sounds), and falls
back to a terminal bell in containers.

| Environment Variable | Default | Purpose |
| -------------------- | ------- | ------- |
| `KOKKO_SOUNDS` | `on` | Set to `off` to mute all hook sounds |
| `KOKKO_SOUND_VOLUME` | `1.0` | afplay gain multiplier (macOS); `1.0` = unity |

# kokko-safety

Safety hooks for Claude Code. Four PreToolUse hooks watch every Bash command
and turn dangerous ones into an explicit permission prompt (`permissionDecision:
"ask"`); a SessionStart hook adds project context. Nothing is ever silently
blocked or silently allowed: dangerous commands prompt, and if the hooks
cannot evaluate a command at all (missing `jq`, malformed payload) they fail
closed to a prompt rather than open.

## Hooks

| Hook | Purpose |
| ---- | ------- |
| `pre-tool-destructive-bash` | Prompts on destructive shell commands (rm -rf, mkfs, chmod 777, ...) |
| `pre-tool-cloud-ops` | Prompts on destructive cloud/IaC commands (aws/az/gcloud delete, terraform destroy, kubectl delete, ...) |
| `pre-tool-destructive-git` | Prompts on history-rewriting git (force push, hard reset, clean -fd, ...) |
| `pre-tool-branch-protection` | Prompts on commit/push/reset/rebase on protected branches (main, master, production, prod, release) and on force pushes to them; understands `cd <dir> &&` and `git -C <dir>` prefixes |
| `session-start-context` | Emits project type and git status at session start (non-gating) |

The prompt reason always names the exact pattern and category that matched.

## Pattern categories

Patterns live in `hooks/dangerous-patterns/`, one extended regular expression
per line, `#` for comments. The 18 category files:

| Category | Covers |
| -------- | ------ |
| `cloud-aws` | AWS CLI deletes/terminations across S3, EC2, RDS, IAM, ... |
| `cloud-azure` | Azure CLI deletes, deallocations, stops |
| `cloud-gcp` | gcloud/gsutil/bq destructive operations |
| `cloud-github` | gh CLI deletes, closures, admin overrides, API DELETEs |
| `databases` | DROP/TRUNCATE/DELETE across Postgres, MySQL, Mongo, Redis, ... |
| `disk-storage` | mkfs, fdisk, dd to devices, LVM/ZFS/RAID destruction |
| `docker` | prune, rm -f, stop/kill, compose down (both invocation forms) |
| `file-operations` | rm -rf and friends, shred/wipe, redirects onto system paths |
| `git` | force push, hard reset, clean, destructive rebase, reflog expire |
| `kubernetes` | kubectl delete/drain/patch, helm uninstall, argo/flux teardown |
| `networking` | firewall flushes, interface down, route deletion, VPN teardown |
| `packages` | package-manager remove/purge across apt, dnf, brew, npm, pip, ... |
| `permissions` | world-writable chmod, recursive chmod/chown on system paths, SUID |
| `process` | kill -9, killall/pkill, OOM-killer manipulation |
| `shell-security` | sudo, history wiping, curl-pipe-to-shell, credential deletion |
| `system-services` | systemctl stop/disable, shutdown/reboot, service managers |
| `terraform` | terraform/tofu/pulumi destroy, auto-approve applies, state rm |
| `users` | userdel, passwd locking, /etc/passwd and sudoers edits |

`pre-tool-destructive-bash` loads the general categories,
`pre-tool-cloud-ops` the cloud/IaC ones, `pre-tool-destructive-git` only
`git`.

## Sound environment variables

Warning sounds go through `hooks/utils/play-sound.sh` (byte-identical to the
kokko-notifications copy; CI enforces this).

| Environment Variable | Default | Purpose |
| -------------------- | ------- | ------- |
| `KOKKO_SOUNDS` | `on` | Set to `off` to mute all hook sounds |
| `KOKKO_SOUND_VOLUME` | `1.0` | afplay gain multiplier (macOS); `1.0` = unity |

## Adding a pattern

1. Pick the right category file and add one ERE per line. Anchor command
   names with `(^|[[:space:]])` so `wipe` does not match `swipe`; patterns
   are matched case-insensitively against the raw command string.
2. Add two cases to `tests/hooks/run-tests.sh`: the dangerous form must
   produce `ask`, and the nearest legitimate look-alike must pass through.
3. Run `bash tests/hooks/run-tests.sh` from the repo root; it feeds real JSON
   payloads through the actual hook scripts.

Invalid regexes are not silently dead: the hooks report any pattern grep
rejects (exit status 2) to stderr.

## Known limitation: quoted strings

Matching is plain `grep -E` over the raw command string. A dangerous-looking
substring inside a quoted argument still prompts, e.g.:

```bash
git commit -m "remove the rm -rf example from docs"   # prompts (rm -rf)
grep -rn "rm -rf" docs/                               # prompts (rm -rf)
```

This is inherent to grep-on-raw-string; the hooks do not parse shell syntax.
The cost of the false positive is one extra permission prompt, which was
judged acceptable against the complexity of a real shell parser. If it bites
you repeatedly, rephrase the string (e.g. `rm -_rf` in prose) or answer the
prompt.

# Changelog

All plugins in this marketplace share one version; see `scripts/bump.sh`.

## 5.0.0 - unreleased

### kokko-safety - all deterministic command blocking removed

The `PreToolUse` guards are gone: `guard-git.sh`, `guard-cloud.sh`,
`guard-bash.sh`, the whole `hooks/dangerous-patterns/` tree (~1,300 regex
patterns across 14 categories), and `hooks/lib/patterns.sh`. **No command is
refused or prompted by this plugin any more.**

A blocklist is the wrong shape for this problem. It has to enumerate every
spelling of every dangerous command, which makes it simultaneously too broad and
too narrow. Too broad: 4.0.0 had to un-block `rm -rf ./dist`,
`sudo apt-get install`, `docker image prune -a`, `git worktree remove`,
`pip uninstall` and `git stash create` — and that was after a test suite went
looking. Too narrow: anything not on the list passes, including the same
destructive operation invoked from a script, a Makefile or a Python subprocess.
The first failure mode is the expensive one, because a guard that fires on
routine work gets switched off, and switching it off takes the snapshot layer
with it. That is exactly what had happened before 4.0.0.

Kept, unchanged in behaviour:

- **`git-snapshot.sh`** — the recovery layer, and the reason removing the guards
  is survivable. It checkpoints uncommitted tracked changes to `refs/snapshots/`
  before every git command and on every user turn, via `git stash create`, so the
  work becomes a real git object that survives rebase/reset/checkout. It does not
  need to predict which command will destroy the tree.
- **`session-context.sh`** — project detection plus the work-loss briefing, now
  rewritten to say plainly that nothing blocks and that the judgement is the
  agent's: check the tree before the first edit, commit before anything that
  rewrites history or packages the working tree, stage explicit paths, use `cp`
  rather than `git checkout -- <path>`, and that `git clean` has no recovery path
  because untracked files are not snapshotted.

Also removed as a consequence:

- `hooks/lib/play-sound.sh` from this plugin — only the guards played sounds.
  `kokko-notifications` keeps its copy.
- `deny()`, `ask()` and `guard_disabled()` from `hooks/lib/hook-io.sh`.
- `CLAUDE_GIT_GUARD`, `CLAUDE_CLOUD_GUARD` and `CLAUDE_BASH_GUARD`. There is
  nothing left to override.
- `scripts/check-patterns.sh`, and the `tests/guard-*.bats` and
  `tests/no-false-positives.bats` suites.

Tests now assert the *absence* of blocking: neither hook may return a
`permissionDecision`, `hooks.json` may wire only the two remaining hooks, and no
guard file or pattern directory may exist. Reintroducing a guard is a failing
change rather than a quiet hook edit. 48 cases remain, covering snapshot
behaviour, the briefing's content, and a latency budget for the snapshot hook —
which still runs on every Bash call.

## 4.0.0

### kokko-safety - rebuilt

The plugin was disabled in the reference devcontainer roster and therefore
protecting nothing. It now carries the git safety net that used to live in
`kokko-ng/kokko-devcontainer`, and its command guards were rewritten to stop
firing on routine work.

Breaking:

- Hooks renamed. `pre-tool-branch-protection.sh`, `pre-tool-cloud-ops.sh`,
  `pre-tool-destructive-bash.sh`, `pre-tool-destructive-git.sh` and
  `session-start-context.sh` are replaced by `guard-git.sh`, `guard-cloud.sh`,
  `guard-bash.sh`, `git-snapshot.sh` and `session-context.sh`.
- `hooks/utils/` is now `hooks/lib/`.
- Pattern categories `git.txt`, `packages.txt`, `process.txt` and
  `networking.txt` were deleted. See below.
- Guards now **deny** rather than **ask**. Under `defaultMode: acceptEdits` an
  "ask" either stalls an unattended agent or gets clicked through unread. Each
  guard has a documented override: `CLAUDE_GIT_GUARD`, `CLAUDE_CLOUD_GUARD`,
  `CLAUDE_BASH_GUARD`.

Added:

- `git-snapshot.sh` checkpoints uncommitted tracked changes to
  `refs/snapshots/` before every git command and on every user turn, so work
  destroyed by rebase/reset/checkout is recoverable.
- `guard-git.sh` blocks the commands that destroy uncommitted work, and only
  while the tree is dirty — a rebase on a clean tree is reflog-recoverable and
  passes through silently.
- `session-context.sh` merges project-type detection with the git safety
  briefing, and now detects .NET projects (`*.sln`, `*.csproj`, `*.fsproj`),
  which were previously invisible despite `kokko-code-quality` shipping dotnet
  variants of every check skill.
- Polyglot repos now report every stack they contain rather than whichever
  detector ran last.

Fixed:

- **Pattern matching no longer fires on prose.** Patterns are now anchored to a
  shell command position and matched case-sensitively. Previously
  `echo "never run rm -rf /"` and `cat runbook.md` tripped the guards.
- **26x faster.** The matcher ran one `grep` subprocess per pattern — roughly
  2,600 processes on every Bash tool call, about 1.65s of added latency. It now
  composes a single `grep -f`: ~63ms.
- **`git stash create` is no longer blocked.** It was caught by the generic
  `git stash` rule, which disabled the very snapshot mechanism the safety net
  depends on. `git stash list` and `git stash show` are allowed too.
- **`git worktree remove` is no longer blocked**, which had broken
  `kokko-janitor`'s worktree workflow.
- **`docker image prune -a` is no longer blocked** — the command
  kokko-devcontainer's own disk-space warning tells you to run. Docker rules now
  key on volumes (persistent state) rather than containers and images
  (rebuildable by definition).
- **`rm -rf ./dist`, `rm -rf node_modules` and `rm -f file` are no longer
  blocked.** `file-operations.txt` keyed on flags, denying every recursive
  delete. It now keys on the target: filesystem root, system directories, home,
  parent directories, bare globs and credential material.
- **`sudo apt-get install` is no longer blocked.** `shell-security.txt` led with
  a bare `sudo` pattern. It now covers only irreversible destruction of
  credentials, history and audit trails.
- Protected-branch prompts key on the branch the operation *lands on*, not the
  branch that happens to be checked out, so pushing a feature branch from main
  no longer prompts.

Removed:

- `packages.txt` — `pip uninstall`, `npm prune`, `poetry remove`,
  `go clean -cache`. Uninstalling a package does not destroy work.
- `process.txt` — `killall`, `pkill`, `kill -9`. That is how a dev server gets
  managed; the genuinely dangerous entries are unreachable in a container.
- `networking.txt` — inside a devcontainer none of it reaches the host, and the
  proxy entries fired on ordinary shell setup.
- `git.txt` — superseded by `guard-git.sh`.

### kokko-notifications

Fixed:

- `play-sound.sh` is now identical to the copy in `kokko-safety`. The two had
  diverged: the safety copy kept a `10.0` afplay gain default (a 10x
  amplification of a system alert) and had no `KOKKO_SOUNDS=off` mute, long
  after both were fixed here, while the README documented the fixed behaviour as
  if it applied everywhere. `scripts/check-shared-lib-sync.sh` now enforces it.
- Hook library moved from `hooks/utils/` to `hooks/lib/`.

### kokko-code-quality

- `commands/clean/references/cruft-patterns.md` moved out of the `commands/`
  tree to `skills/cruft/references/`. A `.md` file under `commands/` is treated
  as a command; reference material there either registers broken or is ignored.
- Every `SKILL.md` now declares `allowed-tools`, which the commands always did.

### Repository

Added:

- `tests/` — a bats suite covering every guard hook: the deny rules, the allow
  paths, a corpus of ~90 everyday development commands that must never be
  blocked, snapshot behaviour, and a latency budget. There were no tests before.
- `scripts/check-shared-lib-sync.sh` — asserts duplicated hook libraries stay
  byte-identical.
- `scripts/check-patterns.sh` — asserts every pattern compiles as an ERE and
  every category file is wired to a guard. A single malformed pattern makes
  `grep -f` fail on the whole file, silently disabling an entire guard.
- `scripts/bump.sh` — lockstep version bump across the marketplace and all
  manifests.
- `scripts/check-version-bumped.sh` — fails a PR that changes plugin content
  without bumping the version.
- `.github/workflows/plugin-repo-ci.yml` — the CI jobs, as a reusable workflow
  so `kokko-janitor` runs the same ones instead of having none.
- Frontmatter validation in CI: every command and skill must declare a
  description, and skills must declare `name` and `allowed-tools`.

## 3.2.0

- Reworked the `tailor` skill and master-prompt templates.
- Added `kokko-validation` to the README install list.
- Dropped non-standard frontmatter keys and model pins.

## 3.1.0

- Added `kokko-env` with `/devcontainer-update` and `/plugins-update`.

## 3.0.1

- Moved the janitor skill to `kokko-ng/kokko-janitor`.

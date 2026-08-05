# Changelog

All plugins version in lock-step, so one entry covers the whole
marketplace. Format loosely follows [Keep a
Changelog](https://keepachangelog.com/). Releases before 3.6.0 are
documented in [GitHub
Releases](https://github.com/kokko-ng/kokko-cmds/releases) only.

## 3.7.0 - 2026-08-05

### Added

- CI prompt lint (`scripts/lint-prompts.sh`): frontmatter completeness,
  pseudo-placeholder detection, argument-hint coverage, and existence of
  every `references/` and `CLAUDE_PLUGIN_ROOT` path a command or skill
  cites.
- `scripts/check-skill-sync.sh`: the shared language-detection block is
  enforced byte-identical across the kokko-code-quality skills.
- kokko-viz bundles the C4-PlantUML library
  (`skills/c4/assets/c4-plantuml/`, MIT), so `/c4-map` needs no network
  access; download remains as a fallback for older installs.

### Changed

- The six kokko-code-quality skills detect every language present and run
  once per language, naming anything skipped -- previously a mixed repo got
  a single-language pass with no mention of the rest.
- kokko-safety: bare `sudo` no longer prompts; root-shell forms (`sudo -i`,
  `sudo su`, `sudo bash`, ...) still do, and destructive payloads behind
  sudo keep prompting via their own category patterns.
- `session-start-context` reports every detected stack, not just the last
  match (a Python repo with a `go.mod` previously reported only "go").
- `/prune` resolves the repo's actual default branch and prints
  guard-denied deletions (`git branch -D`, `git push --delete`) for the
  user to run in a terminal instead of attempting them.
- `/compush` reports a rejected push and shows the divergence instead of
  auto-running `git pull --rebase`.
- `/deps-update` rolls a failed update forward by re-pinning the previous
  version -- never `git restore`/`git checkout` on a dirty tree, which
  git-guarded environments deny.

### Fixed

- `/review`, `/debt`, and `/emojis` used `$target`, which Claude Code never
  substitutes; they now use the real `$1` placeholder.
- `/c4-update` and `/c4-verify` honor their `[system-id]` argument instead
  of always taking the first entry in `codemap/`; `/c4-map` documents that
  `$1` scopes the target directory.
- `/az-status` lookback-date computation works on macOS (BSD `date`
  fallback).

## 3.6.0 - 2026-08-02

### Added

- `KOKKO_SAFETY_SKIP` environment variable: disable individual kokko-safety
  hooks by name (e.g. `destructive-git` in environments with their own git
  guard, such as kokko-devcontainer).
- `scripts/bump-version.sh` sets the lock-step version in every plugin
  manifest and marketplace entry; `/release` uses it.
- Per-plugin READMEs for all ten plugins.
- CI: actionlint on workflows, `check-json` in pre-commit, and a lock-step
  version assertion in the marketplace sync check.
- Hook tests: ERE compile check for all dangerous patterns and coverage
  check that every pattern file is loaded by a hook.

### Changed

- kokko-safety pattern matching batch-rejects benign commands with a single
  grep: ~1.7s to ~0.06s per Bash call for the destructive-bash hook.
- macOS warning sounds no longer block the hook (afplay backgrounded).
- Ownership split between the git hooks: destructive-git owns force push,
  hard reset, and rebase on all branches; branch-protection owns commit and
  plain push on protected branches. No more double prompts.
- kokko-code-quality commands moved out of `analysis/`, `clean/`, and
  `quality/` subdirectories so `/debt`, `/cruft`, `/check` resolve as
  documented.

### Fixed

- Gating hooks now fail closed even when they crash before their utilities
  load (previously a crash exited 1 with no output, which counts as allow).
- `git -C <dir>` takes precedence over a leading `cd <dir> &&` in
  branch-protection, matching git's own semantics.
- A detached HEAD parked on a protected branch's tip no longer bypasses
  branch protection.

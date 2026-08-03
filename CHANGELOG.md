# Changelog

All plugins version in lock-step, so one entry covers the whole
marketplace. Format loosely follows [Keep a
Changelog](https://keepachangelog.com/). Releases before 3.6.0 are
documented in [GitHub
Releases](https://github.com/kokko-ng/kokko-cmds/releases) only.

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

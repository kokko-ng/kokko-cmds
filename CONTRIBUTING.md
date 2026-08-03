# Contributing

## Developing locally

Add your checkout as a local marketplace and install plugins straight from
it:

```text
/plugin marketplace add /path/to/kokko-cmds
/plugin install kokko-safety@kokko-ng-kokko-cmds
```

Claude Code copies the plugin at install time, so edits to the checkout do
not appear in a running session automatically. The reliable reload path is
to remove and re-add:

```text
/plugin uninstall kokko-safety@kokko-ng-kokko-cmds
/plugin marketplace update kokko-ng-kokko-cmds
/plugin install kokko-safety@kokko-ng-kokko-cmds
```

then restart Claude Code (or run `/reload-plugins` where available) so hooks
and commands are re-read.

For the safety hooks you rarely need an installed plugin at all:
`tests/hooks/run-tests.sh` feeds real JSON payloads through the hook scripts
directly from the working tree.

Run `pre-commit install` once after cloning so the lint suite runs as a git
pre-commit hook; `pre-commit run --all-files` covers the whole tree on
demand (see Local checks below).

## Versioning policy: lock-step

All ten plugins share one version number. Every release bumps every
`plugins/*/.claude-plugin/plugin.json` and every entry in
`.claude-plugin/marketplace.json` to the same `x.y.z` together, even for
plugins that did not change. This is deliberate: one number to reason about,
and `release.yml` refuses to publish if the marketplace entries disagree.

`scripts/check-marketplace-sync.sh` (run in CI) asserts that each marketplace
entry matches its plugin manifest (name, version, description) and that every
`plugins/*/` directory is listed in the marketplace.

## Adding a plugin

1. Create `plugins/<name>/` with a `.claude-plugin/plugin.json` manifest.
   Commands go in `commands/`, skills in `skills/<skill>/SKILL.md`, hooks in
   `hooks/` with a `hooks/hooks.json`. Rely on directory convention; do not
   add explicit `commands`/`skills` arrays to the manifest.
2. Add a matching entry to `.claude-plugin/marketplace.json` (same name,
   version, and description as the manifest). CI fails if either side is
   missing or out of sync.
3. Hook scripts must be executable and start with `#!/bin/bash`; CI checks
   that every `hooks.json` command resolves to an existing executable file.

## Adding a dangerous pattern (kokko-safety)

1. Add the ERE to the right category file under
   `plugins/kokko-safety/hooks/dangerous-patterns/`. Anchor command names
   with `(^|[[:space:]])` so the pattern does not match inside longer words
   (`wipe` vs `swipe`).
2. Add test cases to `tests/hooks/run-tests.sh`: one asserting the dangerous
   form produces an `ask` decision, and one asserting the nearest legitimate
   look-alike passes through.
3. Run `bash tests/hooks/run-tests.sh` and make it green. See
   `plugins/kokko-safety/README.md` for pattern-writing details and known
   limitations.

## Release flow

1. `/release` (kokko-git) bumps the version in all plugin manifests and the
   marketplace via `scripts/bump-version.sh <x.y.z>` (which ends by running
   the sync check), then opens and merges a PR to `main`. Update
   [CHANGELOG.md](CHANGELOG.md) with an entry for the new version as part of
   the same PR.
2. CI runs on `main` (pre-commit, hook tests, plugin validation, sync check).
3. When CI succeeds, `.github/workflows/release.yml` fires via `workflow_run`
   and creates the `v<version>` GitHub release. It is the sole publisher;
   never run `gh release create` by hand. `workflow_dispatch` with an
   explicit tag exists for recovery.

## Local checks

```bash
pre-commit run --all-files      # lint (shellcheck, markdownlint, hygiene)
bash tests/hooks/run-tests.sh   # hook behavior tests
bash scripts/check-marketplace-sync.sh
```

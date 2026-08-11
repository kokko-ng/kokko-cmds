---
description: Bump version across all files and open/merge a PR; the Release workflow publishes.
argument-hint: '[patch|minor|major] [--version x.y.z]'
allowed-tools: Bash(git:*), Bash(gh:*), Bash(bash:*), Bash(grep:*), Read, Edit, Grep, Glob, AskUserQuestion, mcp__github__create_pull_request, mcp__github__merge_pull_request, mcp__github__pull_request_read, mcp__github__list_releases, mcp__github__actions_list, mcp__github__get_job_logs
disable-model-invocation: true
---

# Version Bump and Release

Increment version, then open and merge a PR. The GitHub release itself is
published automatically by the Release workflow once CI succeeds on `main`.
`$ARGUMENTS` sets the bump type (patch/minor/major, default patch) or an explicit `--version x.y.z`.

## Steps

### 1. Detect current version

If the repo has a bump script, it owns the version locations — read the
current version from where it writes (for kokko-cmds:
`jq -r '.plugins[0].version' .claude-plugin/marketplace.json`). Otherwise
check common locations: `pyproject.toml`, `package.json`, `*/__init__.py`
(`__version__`), `.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, `Cargo.toml`, `version.txt`/`VERSION`.

```bash
grep -rl '"version"' . --include="*.json"
grep -E "^version\s*=" pyproject.toml Cargo.toml
grep -rn "__version__" . --include="__init__.py"
git describe --tags --abbrev=0
```

### 2. Calculate new version

Semantic versioning: patch = Z+1 (fixes), minor = Y+1/Z=0 (features), major = X+1/Y=0/Z=0 (breaking).

### 3. Update ALL version references

If `scripts/bump-version.sh` exists (it does in kokko-cmds), use it — it
rewrites every plugin manifest and marketplace entry in lock-step and ends
with the sync check; do not grep-and-edit version strings by hand:

```bash
bash scripts/bump-version.sh X.Y.Z
```

Otherwise replace the old version in every file from step 1. Keep formats
consistent — no `v` prefix in files, `v` prefix on the git tag. Then verify:

```bash
git diff
```

### 4. Create the version-bump PR

Branch, commit, and push. Stage the modified files by explicit path from the
`git status` output — never `git add .` (it sweeps in untracked files):

```bash
git checkout -b version-bump-vX.Y.Z
git status --porcelain
git add <each modified file, named explicitly>
git commit -m "chore: bump version to vX.Y.Z"
git push -u origin version-bump-vX.Y.Z
```

Open the PR with the GitHub MCP tool `mcp__github__create_pull_request` (base `main`, title "Bump version to vX.Y.Z"). Fallback: `gh pr create` if the MCP server is unavailable.

### 5. Confirm and merge the PR

Run quality checks and wait for CI. Then **confirm with AskUserQuestion before merging** — show the PR number, title, and CI status, with options "Merge", "Wait", "Abort". Only after approval, merge via `mcp__github__merge_pull_request` (fallback: `gh pr merge --merge`).

### 6. Verify the automated release

This command's job ends at the version bump + merge. Publishing is owned by
the Release workflow (`.github/workflows/release.yml`): after the merge lands
on `main` and CI succeeds, the workflow creates the `vX.Y.Z` GitHub release
automatically. Do NOT run `gh release create` or push tags by hand.

Monitor the CI and Release workflow runs (`mcp__github__actions_list` /
`mcp__github__get_job_logs`, or `gh run list`) and confirm the release exists
once they finish (`mcp__github__list_releases` or `gh release view vX.Y.Z`).
If the workflow did not fire (e.g. CI failed), report why instead of
publishing manually.

## Notes

- Update ALL version refs consistently; keep the with/without `v` convention.
- No emojis or attribution footers in commits or release notes.
- Version not found → search manually and add the file to the update set.

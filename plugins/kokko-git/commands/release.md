---
description: Bump version across all files, open/merge a PR, and publish a GitHub release.
argument-hint: [patch|minor|major] [--version x.y.z]
allowed-tools: Bash(git:*), Read, Edit, Grep, Glob
---

# Version Bump and Release

Increment version, open and merge a PR, then publish a GitHub release. `$ARGUMENTS` sets the bump type (patch/minor/major, default patch) or an explicit `--version x.y.z`.

## Steps

### 1. Detect current version

Check common locations: `pyproject.toml`, `package.json`, `*/__init__.py` (`__version__`), `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `Cargo.toml`, `version.txt`/`VERSION`.

```bash
grep -r '"version"' . --include="*.json" 2>/dev/null | head -20
grep -E "^version\s*=" pyproject.toml Cargo.toml 2>/dev/null
grep "__version__" **/__init__.py 2>/dev/null
git describe --tags --abbrev=0
```

### 2. Calculate new version

Semantic versioning: patch = Z+1 (fixes), minor = Y+1/Z=0 (features), major = X+1/Y=0/Z=0 (breaking).

### 3. Update ALL version references

Replace the old version in every file from step 1. Keep formats consistent — no `v` prefix in files, `v` prefix on the git tag. Then verify:

```bash
git diff
```

### 4. Create the version-bump PR

Branch, commit, and push:

```bash
git checkout -b version-bump-vX.Y.Z
git add .
git commit -m "chore: bump version to vX.Y.Z"
git push -u origin version-bump-vX.Y.Z
```

Open the PR with the GitHub MCP tool `mcp__github__create_pull_request` (base `main`, title "Bump version to vX.Y.Z"). Fallback: `gh pr create` if the MCP server is unavailable.

### 5. Merge the PR

Run quality checks, then merge via `mcp__github__merge_pull_request`. Fallback: `gh pr merge --merge`.

### 6. Prepare release notes

```bash
git describe --tags --abbrev=0
git log <previous-tag>..HEAD --oneline
git diff <previous-tag>..HEAD --stat
```

Categorize commits into Features, Improvements, Bug Fixes, Documentation, Internal, and note Breaking Changes.

### 7. Publish the GitHub release

Create tag `vX.Y.Z` targeting `main` with the categorized notes using the GitHub MCP release-creation tool (e.g. `mcp__github__create_release`). Fallback: `gh release create vX.Y.Z --target main`.

### 8. Verify

Confirm the release exists and monitor any triggered CI (`mcp__github__actions_list` / `mcp__github__get_job_logs`, or `gh run list`).

## Notes

- Update ALL version refs consistently; keep the with/without `v` convention.
- No emojis or attribution footers in commits or release notes.
- Version not found → search manually and add the file to the update set.

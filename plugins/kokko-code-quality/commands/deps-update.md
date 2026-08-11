---
description: Interactively update outdated dependencies with validation between each.
argument-hint: '[package|critical|major|minor]'
allowed-tools: Bash, AskUserQuestion
disable-model-invocation: true
---

# Interactive Dependency Update

Update outdated dependencies safely, validating after each. `$1` filters scope:
a package name, or `critical` (security only), `major`, or `minor`. No arg =
interactive over all outdated packages.

## 1. Audit (in parallel)

```bash
uv pip list --outdated   # Python
npm outdated             # JS (per package.json dir)
pip-audit                # Python vulns
npm audit                # JS vulns
```

## 2. Categorize by risk

Critical (security) → Major (x.0.0) → Minor (0.x.0) → Patch (0.0.x). Update in
that order.

## 3. Interactive loop

For each package (critical first):

1. Show current/latest version and changelog summary if available.
2. Ask whether to update (AskUserQuestion).
3. If yes: record the currently installed version (from step 1), then
   `uv add package@latest` or `npm install package@latest`, then validate
   (`uv run python -c "import package_name"` / `npm run build`). On failure,
   roll FORWARD to the recorded pin — `uv add 'package==<previous>'` /
   `npm install package@<previous>` — and report. Never roll back with
   `git restore`/`git checkout -- <lockfile>`: the tree is dirty at this
   point and those commands overwrite uncommitted work unrecoverably.

## 4. Final validation

`uv run pytest` (or `uv run mypy .`) for Python; `npm test`/`npm run build` for JS.

## 5. Summary

| Package | Old | New | Status |
| ------- | --- | --- | ------ |
| ... | ... | ... | Updated/Skipped/Failed |

- Never force an update when tests fail.
- Commit lock-file changes separately from code changes.
- Warn about breaking changes on major bumps.

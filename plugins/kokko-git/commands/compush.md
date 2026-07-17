---
description: Stage, commit (Conventional Commits), and push one logical change.
argument-hint: '[files] [--message "msg"]'
allowed-tools: Bash(git:*), Bash(detect-secrets:*), Bash(pre-commit:*), Bash(uv run pre-commit:*)
disable-model-invocation: true
---

# Commit and Push

Stage, commit, and push a single logical change. Honor `$ARGUMENTS` as files to commit and/or a `--message` override.

## Steps

### 1. Assess scope and stage

```bash
git status
git diff --stat
```

Keep commits small and modular — ONE logical change each. Split unrelated work (config vs code, refactor vs feature, file moves vs edits) into separate commits. If the subject needs an "and", split it. Never `--amend` to combine unrelated changes.

Stage only the files for this change. Use `git add -p` for partial staging when a file mixes concerns; avoid `git add .` unless everything belongs together.

### 2. Scan staged files for secrets

```bash
if command -v detect-secrets >/dev/null 2>&1; then
  git diff --cached --name-only --diff-filter=d | xargs -r detect-secrets scan --list-all-secrets
else
  echo "detect-secrets not installed - review the staged diff manually"
  git diff --cached
fi
```

If anything is flagged, unstage and remove it (use env vars / secret management). NEVER commit secrets. When detect-secrets is unavailable, review the staged diff for keys, tokens, passwords, and connection strings before continuing.

### 3. Run quality checks

If the repo has a `.pre-commit-config.yaml`, run the hooks on the staged files and fix failures before committing:

```bash
pre-commit run --files $(git diff --cached --name-only --diff-filter=d)
# uv projects: uv run pre-commit run --files ...
```

### 4. Commit

Write a Conventional Commits message: `type(scope): subject`

- Subject imperative, lowercase, no trailing period, ≤50 chars.
- Body (optional) wrapped at 72 chars explaining motivation.
- Footer (optional): `Closes #N`, or `BREAKING CHANGE: <desc>`.

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.

### 5. Push

```bash
git push
```

New branch:

```bash
git push -u origin $(git branch --show-current)
```

- Push rejected → `git pull --rebase` then push.

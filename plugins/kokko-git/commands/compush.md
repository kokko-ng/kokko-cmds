---
description: Stage, commit (Conventional Commits), and push one logical change.
argument-hint: [files] [--message "msg"]
allowed-tools: Bash(git:*), Bash(detect-secrets:*)
---

# Commit and Push

Stage, commit, and push a single logical change. Honor `$ARGUMENTS` as files to commit and/or a `--message` override.

## Steps

### 1. Scan for secrets

```bash
git diff --cached --name-only | xargs detect-secrets scan --list-all-secrets 2>/dev/null
```

If anything is flagged, remove it (use env vars / secret management). NEVER commit secrets.

### 2. Assess scope and stage

```bash
git status
git diff --stat
```

Keep commits small and modular — ONE logical change each. Split unrelated work (config vs code, refactor vs feature, file moves vs edits) into separate commits. If the subject needs an "and", split it. Never `--amend` to combine unrelated changes.

Stage only the files for this change. Use `git add -p` for partial staging when a file mixes concerns; avoid `git add .` unless everything belongs together.

### 3. Commit

Write a Conventional Commits message: `type(scope): subject`

- Subject imperative, lowercase, no trailing period, ≤50 chars.
- Body (optional) wrapped at 72 chars explaining motivation.
- Footer (optional): `Closes #N`, or `BREAKING CHANGE: <desc>`.

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.

### 4. Push

```bash
git push
```

New branch:

```bash
git push -u origin $(git branch --show-current)
```

- Push rejected → `git pull --rebase` then push.

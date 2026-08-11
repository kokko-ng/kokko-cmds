---
description: Stage, commit (Conventional Commits), and push one logical change.
argument-hint: '[files] [--message "msg"]'
allowed-tools: Bash(git:*), Bash(detect-secrets:*), Bash(detect-secrets-hook:*), Bash(ls:*), Bash(pre-commit:*), Bash(uv run pre-commit:*), Read, Edit
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

Stage only the files for this change, by explicit path — never `git add .`
or `-A` (they sweep in untracked files). When one file mixes concerns, `git add -p` will not work
here (it needs an interactive terminal); stage hunks non-interactively
instead: write the file's diff to a patch (`git diff <file> > /tmp/hunks.patch`),
trim the patch to this change's hunks, then `git apply --cached /tmp/hunks.patch`.

### 2. Scan staged files for secrets

List what is staged, then scan exactly those paths:

```bash
git diff --cached --name-only --diff-filter=d
ls .secrets.baseline
```

When the repo has a `.secrets.baseline`, use the hook entrypoint — it exits
non-zero exactly when a staged file adds a secret the baseline does not know:

```bash
detect-secrets-hook --baseline .secrets.baseline <staged files>
```

Without a baseline, scan the staged paths and review the `results` object —
any entry is a finding:

```bash
detect-secrets scan <staged files>
```

If detect-secrets is not installed (the commands above fail with "command
not found"), review the staged diff manually for keys, tokens, passwords,
and connection strings:

```bash
git diff --cached
```

If anything is flagged, unstage and remove it (use env vars / secret management). NEVER commit secrets.

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

- Push rejected (non-fast-forward) → the remote has commits you do not have.
  A rejected push is usually correct: do NOT pull, rebase, merge, or force
  anything on your own. Fetch and show the divergence, then stop and let the
  user decide how to integrate:

  ```bash
  git fetch origin
  git log --oneline HEAD..origin/$(git branch --show-current)   # remote-only
  git log --oneline origin/$(git branch --show-current)..HEAD   # local-only
  ```

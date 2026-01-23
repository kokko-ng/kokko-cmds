---
disable-model-invocation: true
---

# Commit and Push

Generate commit message, commit changes, and push to remote.

## When to Use

- After completing a unit of work
- Before switching branches
- To save progress to remote

## Arguments

Usage: `/compush [files] [--message "msg"]`

- `files` - Specific files to commit (default: all changes)
- `--message` - Optional commit message override

If `$ARGUMENTS` is provided, use it as files to commit or message.

## Steps

### 1. Security Check

Scan for secrets before committing:

```bash
git diff --cached --name-only | xargs detect-secrets scan --list-all-secrets 2>/dev/null
```

If secrets are found, remove them immediately. Use environment variables or
secret management. **NEVER commit files containing secrets.**

### 2. Assess Change Scope

Review the changes:

```bash
git status
git diff --stat
```

**Small, modular commits are mandatory.** Prefer many small commits over
fewer large ones. Each commit should represent ONE logical change:

- One file rename = one commit
- One function refactor = one commit
- One bug fix = one commit
- One new feature = one commit
- Config changes separate from code changes
- Refactoring separate from feature work
- Moving files separate from modifying them

**Signs you need to split:**

- Commit message needs "and" (e.g., "add X and fix Y")
- Changes span unrelated files or concerns
- You cannot describe the change in ~50 characters
- Diff touches more than one logical unit

**Never use `git commit --amend` to combine unrelated changes.** Create
separate commits instead. Stage and commit each logical change separately
before moving to the next.

### 3. Stage Changes

Stage only the files for ONE logical change:

```bash
git add <file1> <file2>
```

Use `git add -p` to stage partial files when a file contains multiple
unrelated changes.

Avoid `git add .` unless all changes belong to the same logical commit.

### 4. Write Commit Message

Use **Conventional Commits** format (commitizen compatible):

```text
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**

| Type | Description |
| ---- | ----------- |
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Formatting, whitespace, missing semi-colons |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Code change that improves performance |
| `test` | Adding or correcting tests |
| `build` | Changes to build system or external dependencies |
| `ci` | Changes to CI configuration files and scripts |
| `chore` | Other changes that don't modify src or test files |
| `revert` | Reverts a previous commit |

**Scope:** Component affected (e.g., `auth`, `api`, `db`, `parser`).

**Subject rules:**

- Imperative, present tense: "add" not "added" nor "adds"
- Lowercase first letter
- No period at the end
- Maximum 50 characters

**Body:** Motivation for the change. Wrap at 72 characters.

**Footer:** Reference issues with `Closes #123` or `Fixes #456`. Breaking
changes start with `BREAKING CHANGE:`.

### 5. Commit

Commit with the formatted message:

```bash
git commit -m "<type>(<scope>): <subject>"
```

For commits with body/footer, use HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<body>

<footer>
EOF
)"
```

**Examples:**

Simple commit:

```bash
git commit -m "feat(auth): add JWT token refresh endpoint"
```

Commit with body:

```bash
git commit -m "$(cat <<'EOF'
fix(db): resolve connection pool exhaustion

The pool was not releasing connections after query timeout.
Added explicit connection release in finally block.

Fixes #567
EOF
)"
```

Breaking change:

```bash
git commit -m "$(cat <<'EOF'
chore(deps): upgrade FastAPI to 0.110.0

BREAKING CHANGE: minimum Python version is now 3.9
EOF
)"
```

### 6. Push to Remote

Push to the remote repository:

```bash
git push
```

If the branch is new:

```bash
git push -u origin $(git branch --show-current)
```

## Error Handling

| Issue | Cause | Resolution |
| ----- | ----- | ---------- |
| Pre-commit hook fails | Code style issues | Fix issues, re-stage, commit |
| Push rejected | Remote has new commits | Run `git pull --rebase` then push |
| Secrets detected | Sensitive data in commit | Remove secrets, use env vars |

## Success Criteria

- Security scan passes (no secrets)
- Each commit represents ONE logical change
- Commit messages follow Conventional Commits format
- No "and" in commit subjects
- Push successful

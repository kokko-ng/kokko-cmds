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

If secrets are found, remove them immediately. Use environment variables or secret management. **NEVER commit files containing secrets.**

### 2. Assess Change Scope

Review the changes:
```bash
git status
git diff --stat
```

If extensive changes exist, break into logical groups. Each commit should be cohesive. Group by: feature, bug fix, refactoring, docs, tests.

### 3. Stage Changes

Stage files for commit:
```bash
git add .
```

For specific files:
```bash
git add <file1> <file2>
```

### 4. Write Commit Message

Use **Conventional Commits** format (commitizen compatible):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
| Type | Description |
|------|-------------|
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

**Scope:** Name of the component affected (e.g., `auth`, `api`, `db`, `parser`).

**Subject rules:**
- Imperative, present tense: "add" not "added" nor "adds"
- Lowercase first letter
- No period at the end
- Maximum 50 characters

**Body:** Motivation for the change. Wrap at 72 characters.

**Footer:** Reference issues with `Closes #123` or `Fixes #456`. Breaking changes start with `BREAKING CHANGE:`.

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
|-------|-------|------------|
| Pre-commit hook fails | Code style issues | Fix issues, re-stage, commit again |
| Push rejected | Remote has new commits | Run `git pull --rebase` then push |
| Secrets detected | Sensitive data in commit | Remove secrets, use env vars |

## Success Criteria

- Security scan passes (no secrets)
- Commit message follows Conventional Commits format
- Changes logically grouped
- Push successful

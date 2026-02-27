# Git Worktree Orchestration Workflow

This document details the worktree-based parallel quality check workflow.

## Prerequisites

- Git repository with clean working tree
- All quality tools installed (or will be installed per tool)

## Step 1: Preparation

```bash
# Verify clean working tree
git status --porcelain
# Should be empty

# Get current branch as default target
TARGET_BRANCH=$(git branch --show-current)

# Create worktree base directory
WORKTREE_BASE=$(mktemp -d)
echo "Worktree base: $WORKTREE_BASE"
```

## Step 2: Detect Languages

Check which languages are present:

```bash
# Python
[ -f pyproject.toml ] || [ -f setup.py ] && echo "py"

# JavaScript/TypeScript
[ -f package.json ] && echo "js"

# .NET
ls *.csproj *.sln 2>/dev/null && echo "dotnet"
```

## Step 3: Create Worktrees

For each language + check combination:

```bash
# Example for Python security
git worktree add $WORKTREE_BASE/py-security -b janitor/py-security

# Example for JavaScript types
git worktree add $WORKTREE_BASE/js-types -b janitor/js-types
```

Create all needed worktrees upfront to allow parallel execution.

## Step 4: Launch Subagents

Spawn one subagent per worktree using the Task tool:

```text
Task: Run /security py in worktree
Prompt: Navigate to $WORKTREE_BASE/py-security and run /security py
        Fix ALL issues found, commit incrementally
```

Launch all subagents in parallel for maximum efficiency.

## Step 5: Monitor Progress

Track subagent completion:

- Use TaskList to monitor active agents
- Note any failures or blockers
- Count issues fixed per agent

## Step 6: Merge Strategy

### Simple Merge (Preferred)

```bash
git checkout $TARGET_BRANCH

# Merge each branch
git merge janitor/py-security --no-ff \
  -m "chore(quality): merge py security fixes"
git merge janitor/py-types --no-ff \
  -m "chore(quality): merge py type fixes"
# ... continue for all branches
```

### Handling Conflicts

If merge conflicts occur:

1. **Understand both changes** - Read the conflicting hunks
2. **Determine intent** - What was each fix trying to accomplish?
3. **Resolve preserving both** - Usually both fixes are valid
4. **Complete merge**:

   ```bash
   git add .
   git commit -m "chore(quality): resolve merge conflict in <file>"
   ```

### Common Conflict Patterns

| Pattern | Resolution |
| ------- | ---------- |
| Same line modified | Keep both if independent, combine if related |
| Import ordering | Accept either, let formatter fix |
| Adjacent lines | Both changes usually apply |
| Delete vs modify | Prefer the fix unless delete was intentional |

## Step 7: Cleanup

```bash
# Remove all worktrees
for dir in $WORKTREE_BASE/*; do
  git worktree remove "$dir" --force
done

# Remove base directory
rmdir $WORKTREE_BASE

# Delete temporary branches
git branch --list 'janitor/*' | xargs git branch -d
```

## Step 8: Final Validation

Run comprehensive checks on merged result:

```bash
# Python
uv run pre-commit run --all-files

# JavaScript/TypeScript
npm run lint
npm run build

# .NET
dotnet build -warnaserror
```

## Error Recovery

### Worktree Creation Fails

```bash
# If dirty working tree
git stash
# Create worktrees
git stash pop
```

### Subagent Fails

1. Check the worktree for partial work
2. Fix remaining issues manually
3. Commit and continue with merge

### Merge Fails Completely

```bash
# Abort merge
git merge --abort

# Try rebasing instead
git rebase janitor/py-security

# Or cherry-pick specific commits
git cherry-pick <commit-sha>
```

## Optimization Tips

1. **Parallelize aggressively** - Launch all subagents at once
2. **Merge order** - Merge smaller changesets first to minimize conflicts
3. **Skip empty branches** - Don't merge branches with no commits

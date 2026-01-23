---
name: janitor
description: Orchestrate all quality checks via subagents and git worktrees
argument-hint: "[target-branch] [--langs py,js,dotnet] [--checks security,types,complexity,deadcode,docs]"
disable-model-invocation: true
---

# Janitor Skill

Run code quality checks in parallel using subagents and git worktrees, then
merge all fixes.

## Arguments

Parse `$ARGUMENTS` for:

- `target-branch` - Branch to merge fixes into (default: current branch)
- `--langs` - Comma-separated languages to check (default: auto-detect all present)
- `--checks` - Comma-separated checks to run (default: all)

## Available Checks

- `security` - Security analysis (bandit, npm audit, SecurityCodeScan)
- `types` - Type checking (mypy, tsc, nullable analyzers)
- `complexity` - Complexity metrics (radon, eslint, CA1502)
- `deadcode` - Dead code detection (vulture, knip, IDE0051)
- `docs` - Documentation coverage (interrogate, jsdoc, XML docs)

## Workflow

Read `references/worktree-workflow.md` for detailed orchestration steps.

### 1. Preparation

1. Verify clean working tree (`git status`)
2. Detect languages present in codebase
3. Create worktree base directory: `WORKTREE_BASE=$(mktemp -d)`

### 2. Create Worktrees

For each language + check combination:

```bash
git worktree add $WORKTREE_BASE/<lang>-<check> -b janitor/<lang>-<check>
```

### 3. Launch Parallel Subagents

Spawn one subagent per worktree using the Task tool. Each subagent:

1. Navigates to its worktree
2. Runs `/<check> <lang>`
3. Fixes ALL issues found (not just reports)
4. Groups fixes into small, logical commits
5. Uses commit format: `fix(<check>): <description>`

### 4. Monitor Completion

Track all subagents until complete:

- Which checks finished
- Issues fixed per check
- Any failures or blockers

### 5. Merge Results

```bash
git checkout <target-branch>
for branch in janitor/*; do
  git merge $branch --no-ff -m "chore(quality): merge ${branch#janitor/} fixes"
done
```

Preserve small logical commits (use merge, not squash).

### 6. Resolve Conflicts

If merge conflicts occur:

- Understand both changes
- Preserve intent of both fixes
- Test the resolution
- Continue with remaining merges

### 7. Cleanup

```bash
# Remove all worktrees
for wt in $WORKTREE_BASE/*; do
  git worktree remove $wt
done

# Delete temporary branches
git branch -d $(git branch --list 'janitor/*')
```

### 8. Final Validation

Run all quality checks on merged result:

- Tests pass
- Linters pass
- No regressions introduced

## Reference Files

- `references/worktree-workflow.md` - Detailed worktree orchestration and
  conflict resolution

## Success Criteria

- All quality checks run successfully
- All issues fixed (not just reported)
- Clean commit history with logical grouping
- All merges complete without unresolved conflicts
- Final validation passes

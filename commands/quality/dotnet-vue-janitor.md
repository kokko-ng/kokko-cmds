# Code Quality Janitor (Dotnet + Vue)

Run code quality checks in parallel using subagents and git worktrees, then merge all fixes.

## When to Use

- During scheduled code quality improvements
- Before major releases
- To clean up accumulated technical debt
- For full-stack .NET/Vue applications

## Arguments

Usage: `/quality/dotnet-vue-janitor [target-branch] [--tools list]`

- `target-branch` - Branch to merge fixes into (default: current branch)
- `--tools` - Comma-separated list of tools to run (default: all)

If `$ARGUMENTS` is provided, use it as the target branch or tool list.

## Prerequisites

- Git repository with clean working tree
- .NET SDK 6.0+
- Node.js and npm
- All quality tools installed (or will be installed per tool)

## Tools Available

**.NET Backend:**
- `/quality/dotnet-quality/security` - Security analyzers (SecurityCodeScan, NuGet audit)
- `/quality/dotnet-quality/docs` - XML documentation coverage
- `/quality/dotnet-quality/types` - Nullable reference types, strict type checking
- `/quality/dotnet-quality/complexity` - Code metrics (CA1502, CA1505)
- `/quality/dotnet-quality/deadcode` - Unused code analyzers (IDE0051, IDE0052)

**Vue/JavaScript/TypeScript Frontend:**
- `/quality/js-quality/security` - Dependency vulnerability scan (npm audit)
- `/quality/js-quality/complexity` - Code complexity analysis (ESLint)
- `/quality/js-quality/docs` - Documentation checker (JSDoc)
- `/quality/js-quality/deadcode` - Unused exports/dependencies (knip)
- `/quality/js-quality/types` - TypeScript compiler checks (tsc)

## Steps

### 1. Create Git Worktrees

Create a separate worktree for each tool:

```bash
# Create temp directory for worktrees
WORKTREE_BASE=$(mktemp -d)

# Create worktree for each tool
# Backend
git worktree add $WORKTREE_BASE/dotnet-security -b janitor/dotnet-security
git worktree add $WORKTREE_BASE/dotnet-types -b janitor/dotnet-types
git worktree add $WORKTREE_BASE/dotnet-docs -b janitor/dotnet-docs
git worktree add $WORKTREE_BASE/dotnet-complexity -b janitor/dotnet-complexity
git worktree add $WORKTREE_BASE/dotnet-deadcode -b janitor/dotnet-deadcode
# Frontend
git worktree add $WORKTREE_BASE/vue-security -b janitor/vue-security
git worktree add $WORKTREE_BASE/vue-types -b janitor/vue-types
git worktree add $WORKTREE_BASE/vue-docs -b janitor/vue-docs
git worktree add $WORKTREE_BASE/vue-complexity -b janitor/vue-complexity
git worktree add $WORKTREE_BASE/vue-deadcode -b janitor/vue-deadcode
```

### 2. Launch Parallel Subagents

Spawn one subagent per tool/worktree. Each subagent must:

1. Navigate to its worktree
2. Run its assigned quality tool
3. **Fix every issue found** (not just report)
4. Group fixes into small, logical commits
5. Use clear commit messages: `fix(<tool>): <description>`

### 3. Wait for Completion

Monitor all subagents until complete. Track:
- Which tools finished
- How many issues fixed per tool
- Any failures or blockers

### 4. Merge Results

Merge each subagent's commits into the target branch:

```bash
# Switch to target branch
git checkout <target-branch>

# Merge backend fixes
git merge janitor/dotnet-security --no-ff -m "chore(quality): merge dotnet security fixes"
git merge janitor/dotnet-types --no-ff -m "chore(quality): merge dotnet type fixes"
git merge janitor/dotnet-docs --no-ff -m "chore(quality): merge dotnet doc fixes"
git merge janitor/dotnet-complexity --no-ff -m "chore(quality): merge dotnet complexity fixes"
git merge janitor/dotnet-deadcode --no-ff -m "chore(quality): merge dotnet deadcode fixes"

# Merge frontend fixes
git merge janitor/vue-security --no-ff -m "chore(quality): merge vue security fixes"
git merge janitor/vue-types --no-ff -m "chore(quality): merge vue type fixes"
git merge janitor/vue-docs --no-ff -m "chore(quality): merge vue doc fixes"
git merge janitor/vue-complexity --no-ff -m "chore(quality): merge vue complexity fixes"
git merge janitor/vue-deadcode --no-ff -m "chore(quality): merge vue deadcode fixes"
```

Preserve small logical commits (use merge or cherry-pick, not squash).

### 5. Resolve Conflicts

If merge conflicts occur:
- Understand both changes
- Preserve the intent of both fixes
- Test the resolution
- Continue with remaining merges

### 6. Cleanup

Remove worktrees when finished:

```bash
# Remove backend worktrees
git worktree remove $WORKTREE_BASE/dotnet-security
git worktree remove $WORKTREE_BASE/dotnet-types
git worktree remove $WORKTREE_BASE/dotnet-docs
git worktree remove $WORKTREE_BASE/dotnet-complexity
git worktree remove $WORKTREE_BASE/dotnet-deadcode

# Remove frontend worktrees
git worktree remove $WORKTREE_BASE/vue-security
git worktree remove $WORKTREE_BASE/vue-types
git worktree remove $WORKTREE_BASE/vue-docs
git worktree remove $WORKTREE_BASE/vue-complexity
git worktree remove $WORKTREE_BASE/vue-deadcode

# Delete temporary branches
git branch -d janitor/dotnet-security janitor/dotnet-types janitor/dotnet-docs janitor/dotnet-complexity janitor/dotnet-deadcode
git branch -d janitor/vue-security janitor/vue-types janitor/vue-docs janitor/vue-complexity janitor/vue-deadcode
```

### 7. Final Validation

```bash
# Backend validation
dotnet build -warnaserror
dotnet test

# Frontend validation
npm install
npm run build
npm test
npm run lint
```

## Error Handling

| Issue | Cause | Resolution |
|-------|-------|------------|
| Worktree creation fails | Dirty working tree | Commit or stash changes first |
| Subagent fails | Tool error | Check tool output, fix manually if needed |
| Merge conflict | Overlapping fixes | Resolve conflict, prioritize correctness |
| Tests fail after merge | Conflicting fixes | Debug, may need to revert and re-run |
| Frontend/backend mismatch | API contract changed | Update both sides, ensure integration tests pass |

## Success Criteria

- All quality tools run successfully
- All issues fixed (not just reported)
- Clean commit history with logical grouping
- All merges complete without unresolved conflicts
- Both backend and frontend validations pass
- Integration between frontend and backend verified

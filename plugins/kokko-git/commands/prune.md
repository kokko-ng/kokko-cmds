---
description: Find and safely delete stale local/remote branches with confirmation.
argument-hint: '[local|remote|merged|<days>]'
allowed-tools: Bash(git:*), Bash(gh:*), AskUserQuestion
disable-model-invocation: true
---

# Git Branch Cleanup

Find and remove stale branches safely. `$ARGUMENTS` scopes the run: `local`, `remote`, `merged`, or an age threshold in days (default 30).

## Process

### 1. Fetch latest state

```bash
git fetch --all --prune
```

### 2. Categorize branches

```bash
# Merged into main (safe to delete)
git branch --merged main | grep -v "main\|master\|\*"
git branch -r --merged origin/main | grep -v "main\|master\|HEAD"

# Orphaned (remote gone)
git branch -vv | grep ': gone]'

# Older than the age threshold (default 30 days)
CUTOFF=$(date -d "30 days ago" +%s 2>/dev/null || date -v-30d +%s)
git for-each-ref --sort=committerdate \
  --format='%(refname:short) %(committerdate:unix) %(committerdate:relative)' refs/heads/ \
  | awk -v cutoff="$CUTOFF" '$2 < cutoff {print $1, $3, $4, $5}'
```

If an age threshold was passed in `$ARGUMENTS`, substitute it for `30` above and only report branches older than the cutoff.

**Squash-merge caveat:** `git branch --merged` misses squash-merged branches (the norm on GitHub), so treat its output as a lower bound. The `: gone]` orphan check is what usually catches them after the remote branch is deleted. When `gh` is available, confirm suspected-stale branches:

```bash
gh pr list --state merged --head <branch> --json number,title
```

### 3. Report

Show a table: Branch | Status | Last Commit | Age | Recommendation.

### 4. Confirm with AskUserQuestion

Present branches recommended for deletion and let the user choose. Options: "Delete all merged", "Delete all orphaned", "Select individually", "Skip".

### 5. Execute approved deletions

```bash
git branch -d branch-name              # -D only if not fully merged but approved
git push origin --delete branch-name   # only with explicit approval
```

### 6. Summarize

Report counts of deleted local, deleted remote, and kept branches. Optionally `git gc` to reclaim space.

## Safety Rules

- NEVER delete main, master, or the current branch.
- NEVER force-delete without explicit user approval.
- Always show what will be deleted before doing it.
- Require confirmation for remote branch deletion.
- Skip branches with unpushed commits unless the user confirms.

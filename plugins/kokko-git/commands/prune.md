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

Resolve the default branch first — never hardcode `main` (`git branch
--merged main` errors outright on a `master`/`trunk` repo):

```bash
BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
[ -n "$BASE" ] || BASE=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
[ -n "$BASE" ] || BASE=main
```

```bash
# Merged into the default branch (safe to delete)
git branch --merged "$BASE" | grep -v "main\|master\|\*"
git branch -r --merged "origin/$BASE" | grep -v "main\|master\|HEAD"

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
git branch -d branch-name   # refuses on unmerged work — that refusal is a finding
```

Run only `git branch -d` yourself. Never `git branch -D` and never
`git push origin --delete`: environments with the kokko-devcontainer git
guard deny both outright, and the deny is not lifted by an in-session
approval — the override is reserved for humans. For branches `-d` refuses
and for remote deletions the user approved, print the exact commands for
the user to run themselves in a terminal:

```text
# Approved but must be run by you (the git guard denies them for agents):
git branch -D <branch>                # unmerged local branch
git push origin --delete <branch>     # remote branch
```

### 6. Summarize

Report counts of deleted local, deleted remote, and kept branches. Optionally `git gc` to reclaim space.

## Safety Rules

- NEVER delete the default branch, master, or the current branch.
- NEVER run `git branch -D` or `git push origin --delete` yourself — print
  approved force/remote deletions for the user to run (see step 5).
- Always show what will be deleted before doing it.
- Skip branches with unpushed commits unless the user confirms.

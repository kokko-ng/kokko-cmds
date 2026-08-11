---
description: Find and safely delete stale local/remote branches with confirmation.
argument-hint: '[local|remote|merged|<days>]'
allowed-tools: Bash(git:*), Bash(gh:*), Bash(grep:*), Bash(date:*), AskUserQuestion
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
git symbolic-ref --short refs/remotes/origin/HEAD
git remote show origin
```

The first command prints `origin/<base>` — strip the `origin/` prefix. If it
errors, take the `HEAD branch:` line from the second, and fall back to `main`
only if both fail. Use the result as `<base>` everywhere below.

```bash
# Merged into the default branch (safe to delete)
git branch --merged <base> | grep -v "main\|master\|\*"
git branch -r --merged origin/<base> | grep -v "main\|master\|HEAD"

# Orphaned (remote gone)
git branch -vv | grep ': gone]'
```

For the age check, print the cutoff epoch (default 30 days; substitute the
`$ARGUMENTS` threshold when one was given), then list every branch's age and
report the ones whose unix timestamp is below the cutoff:

```bash
date -d "30 days ago" +%s 2>/dev/null || date -v-30d +%s
git for-each-ref --sort=committerdate \
  --format='%(refname:short) %(committerdate:unix) %(committerdate:relative)' refs/heads/
```

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
`git push origin --delete`: `-D` discards a branch's unmerged commits (and
its reflog with them), and a remote deletion cannot be undone from here.
For branches `-d` refuses and for remote deletions the user approved, print
the exact commands for the user to run themselves in a terminal:

```text
# Approved but must be run by you (this command never deletes these itself):
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

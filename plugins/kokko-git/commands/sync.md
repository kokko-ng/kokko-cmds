---
description: Pull latest base branch and merge/rebase it into the current branch.
argument-hint: '[base-branch] [--strategy merge|rebase]'
allowed-tools: Bash(git:*), Read, Edit
disable-model-invocation: true
---

# Sync with Base Branch

Integrate the latest base branch into the current branch. `$ARGUMENTS` sets the base branch (default `main`) and `--strategy` (merge or rebase, default merge). Use the chosen base branch everywhere `<base>` appears below — do not hardcode `main`.

## Steps

### 1. Fetch the base branch

```bash
git fetch origin <base>
```

Merging `origin/<base>` directly avoids checking out or touching the local base branch.

### 2. Merge or rebase

```bash
git merge origin/<base>    # preserves history
# or
git rebase origin/<base>   # linear history
```

Rebase rewrites the branch, so pushing a rebased branch that was already
pushed needs a force push — which git-guarded environments deny (see step 5).
Reserve rebase for branches not yet pushed; default to merge otherwise.

### 3. Resolve conflicts (if any)

Edit each conflicted file, pick the correct result, remove the `<<<<<<<`/`=======`/`>>>>>>>` markers, then `git add` it. Continue with `git merge --continue` or `git rebase --continue`. Useful: `git log --oneline origin/<base>..HEAD` and `HEAD..origin/<base>` to see diverging commits.

### 4. Verify and test

```bash
git status && git log --oneline -10
# Python: uv run pytest && uv run pre-commit run --all-files
# JS:     npm test && npm run lint
```

### 5. Push

```bash
git push origin <branch-name>
```

After a merge, a plain push suffices. After a rebase of an already-pushed
branch, the push needs a force flag — and git-guarded environments
(kokko-devcontainer) deny every force push outright, `--force-with-lease`
included; the deny is not lifted by an in-session approval. Do not attempt
it: report that the rebase is complete locally and print the exact command
for the user to run themselves:

```text
# Must be run by you (the git guard denies force pushes for agents):
git push origin <branch-name> --force-with-lease
```

## Notes

- Dirty working tree → commit before syncing. Do not stash to clear it:
  guard environments deny `git stash` exactly when the tree is dirty, and a
  forgotten stash was load-bearing in past data-loss incidents.
- Rebase conflicting on every commit → prefer merge instead.

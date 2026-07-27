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

Recovery and context. **Nothing here blocks a command.**

| Hook | Purpose |
| ---- | ------- |
| `git-snapshot` | Checkpoints uncommitted tracked changes to `refs/snapshots/` before every git command and on every turn |
| `session-context` | Reports project type, git state, and the rules for not losing uncommitted work, at session start |

#### Why there are no guards

Earlier versions shipped `PreToolUse` hooks that denied destructive git, cloud
and shell commands from a list of ~1,300 regex patterns. They are gone, on
purpose.

A blocklist is the wrong shape for this problem. It has to enumerate every
spelling of every dangerous command, so it is simultaneously too broad — it
denied `rm -rf ./dist`, `sudo apt-get install`, `docker image prune -a`, and
`git worktree remove` — and too narrow, because anything not on the list sails
straight through, including the same operation invoked from a script, a
Makefile, or a Python subprocess. Both failure modes are bad, and the first one
is worse: a guard that fires on routine work gets switched off, and switching it
off takes the snapshot layer with it. That is not hypothetical — the previous
version of this plugin was disabled in the reference devcontainer roster and
protecting nothing at all.

What replaces it is a recovery mechanism that does not need to predict anything,
plus an explicit briefing so the judgement call is made with the facts in hand.

#### Recovering work

`git-snapshot` turns uncommitted changes into real git objects before every git
command, which is what makes them survive `rebase`, `reset` and `checkout` — the
reason uncommitted work is normally unrecoverable is that it was never an object
at all. The mechanism is `git stash create`, which builds a commit **without**
touching the working tree, the index or the stash ref.

```bash
git for-each-ref refs/snapshots/     # list checkpoints, newest last
git stash show -p <ref>              # inspect one
git stash apply <ref>                # restore it
```

[kokko-devcontainer](https://github.com/kokko-ng/kokko-devcontainer) wraps those
three as `snaps` / `snaps show` / `snaps restore`.

**Scope: tracked changes only.** Untracked files are not captured, so `git clean`
has no recovery path — the one case the old guard did usefully cover, and now a
matter of judgement like everything else.

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
bats tests/                           # the hook test suite
bash scripts/check-shared-lib-sync.sh # duplicated hook libraries are identical
bash scripts/check-marketplace-sync.sh
bash scripts/bump.sh patch            # lockstep version bump across all plugins
pre-commit run --all-files
```

All plugins share one version. `scripts/bump.sh` updates `marketplace.json` and
every `plugin.json` together; CI fails a PR that changes plugin content without
bumping. See [CHANGELOG.md](CHANGELOG.md).

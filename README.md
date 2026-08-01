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

Safety hooks for all sessions.

| Hook | Purpose |
| ---- | ------- |
| `session-start-context` | Detects project type and git status |
| `pre-tool-cloud-ops` | Prompts before destructive cloud operations |
| `pre-tool-branch-protection` | Prompts before commits to protected branches |
| `pre-tool-destructive-git` | Prompts before force push, hard reset |
| `pre-tool-destructive-bash` | Prompts before rm -rf, mkfs, chmod 777 |

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

Set up a dev environment, then keep it current without rebuilding it.

| Commands | Purpose |
| -------- | ------- |
| `/devcontainer-update` | Pull the latest `.devcontainer/` from [kokko-ng/kokko-devcontainer](https://github.com/kokko-ng/kokko-devcontainer) and apply it live, reporting what still needs a rebuild |
| `/plugins-update` | Refresh the marketplaces, update installed plugins to the published versions, then prompt for `/reload-plugins` |

| Skill | Purpose |
| ----- | ------- |
| `devcontainer-setup` | Install the [kokko-devcontainer](https://github.com/kokko-ng/kokko-devcontainer) starter into a directory (defaults to the current one), tailor it to that project, and bring the container up |

`devcontainer-setup` is the first-time install and runs on the host;
`/devcontainer-update` is the follow-up for a project that already has a
`.devcontainer/`.

`/devcontainer-update` applies the config by re-running the project's own
`post-create.sh --config-only`. A `.devcontainer/` copied before that flag
existed needs updating first — the command detects this and says so.

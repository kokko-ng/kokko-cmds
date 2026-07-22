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

Shared templates live in `commands/references/c4-templates.md` (bundled reference, not a command).

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

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
/plugin install kokko-learning@kokko-ng-kokko-cmds
```

## Versioning

All ten plugins version in lock-step: every release bumps every plugin (and
every marketplace entry) to the same version, even ones that did not change.
See [CONTRIBUTING.md](CONTRIBUTING.md).

## Environment variables

Both kokko-safety (warning prompts) and kokko-notifications (completion
chimes) play sounds through the same `play-sound.sh` utility and honor the
same sound variables; `KOKKO_SAFETY_SKIP` is read by the kokko-safety hooks
only:

| Environment Variable | Default | Purpose |
| -------------------- | ------- | ------- |
| `KOKKO_SOUNDS` | `on` | Set to `off` to mute all hook sounds |
| `KOKKO_SOUND_VOLUME` | `1.0` | afplay gain multiplier (macOS); `1.0` = system default |
| `KOKKO_SAFETY_SKIP` | unset | Comma/space-separated kokko-safety hooks to disable (`destructive-git`, `branch-protection`, `cloud-ops`, `destructive-bash`); see [plugins/kokko-safety/README.md](plugins/kokko-safety/README.md) |

## Plugins

### kokko-safety

Safety hooks for all sessions. See
[plugins/kokko-safety/README.md](plugins/kokko-safety/README.md) for the
pattern categories, how to add patterns, and known limitations.

| Hook | Purpose |
| ---- | ------- |
| `session-start-context` | Detects project type and git status |
| `pre-tool-cloud-ops` | Prompts before destructive cloud operations |
| `pre-tool-branch-protection` | Prompts before commits to protected branches |
| `pre-tool-destructive-git` | Prompts before force push, hard reset |
| `pre-tool-destructive-bash` | Prompts before rm -rf, mkfs, chmod 777 |

### kokko-notifications

Sound notifications for task completion events. See
[plugins/kokko-notifications/README.md](plugins/kokko-notifications/README.md).

| Hook | Purpose |
| ---- | ------- |
| `stop-notification` | Plays sounds on task completion |

### kokko-git

Git workflow commands. The janitor skill moved to its own repo:
[kokko-ng/kokko-janitor](https://github.com/kokko-ng/kokko-janitor). See
[plugins/kokko-git/README.md](plugins/kokko-git/README.md).

| Commands | Purpose |
| -------- | ------- |
| `/compush` | Commit and push in one step |
| `/prune` | Prune stale local and remote branches |
| `/release` | Cut a versioned release |
| `/sync` | Merge or rebase the latest base branch into the current branch |

### kokko-validation

Generic master-prompt templates (local validation, deployed validation,
Azure deployment, aesthetics) and a skill that tailors them to the repo. See
[plugins/kokko-validation/README.md](plugins/kokko-validation/README.md).

| Skill | Purpose |
| ----- | ------- |
| `tailor` | Fill a generic template's placeholders from the repo and save it to `prompts/` |

### kokko-code-quality

Code analysis commands and quality skills. See
[plugins/kokko-code-quality/README.md](plugins/kokko-code-quality/README.md).

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

C4 architecture diagram commands. See
[plugins/kokko-viz/README.md](plugins/kokko-viz/README.md).

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

Azure infrastructure commands. See
[plugins/kokko-infra/README.md](plugins/kokko-infra/README.md).

| Commands | Purpose |
| -------- | ------- |
| `/az-costs` | Show Azure resource costs |
| `/az-status` | Show Azure service status |

### kokko-ai-config

AI/Claude configuration management commands. See
[plugins/kokko-ai-config/README.md](plugins/kokko-ai-config/README.md).

| Commands | Purpose |
| -------- | ------- |
| `/prune-docs` | Trim CLAUDE.md or README.md to the essentials under a line target |
| `/verify-docs` | Audit CLAUDE.md or README.md against the codebase and fix inaccuracies |

### kokko-env

Set up a dev environment, then keep it current without rebuilding it. See
[plugins/kokko-env/README.md](plugins/kokko-env/README.md).

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

### kokko-learning

Study and recall aids. See
[plugins/kokko-learning/README.md](plugins/kokko-learning/README.md).

| Skill | Purpose |
| ----- | ------- |
| `anki-concept-cards` | Generate flashcard JSON for the [BulkCardCreator](https://github.com/Ifiora-Timothy/BulkCardCreator-anki-addon) Anki add-on — a prose description on the front, the concept's name on the back |

The craft is in the description: it has to identify one concept unambiguously
without leaking its name, its morphological variants, its acronym expansion, or
the eponym inside it. The skill carries the non-leakage rules, worked examples,
and a per-card self-check.

Triggers on Anki, BulkCardCreator, or any "definition on front, term on back"
request — including a bare list of terms with "make me study cards".

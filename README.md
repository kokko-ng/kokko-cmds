# kokko-cmds

My Claude Code plugin for day-to-day work.

## Installation

```bash
/plugin marketplace add kokko-ng/kokko-cmds
/plugin install kokko-cmds@kokko-ng-kokko-cmds
```

## Commands

| Category | Commands |
| -------- | -------- |
| `/ai-config/` | prune-claude-md, prune-readme, verify-claude-md |
| | verify-readme |
| `/analysis/` | debt, perf, review, spec, split, verify-spec |
| `/clean/` | cruft, emojis |
| `/git/` | compush, prune, release, sync |
| `/infra/` | az-costs, az-status |
| `/quality/` | check, deps-update, verify-no-mocks |
| `/viz/` | c4-map, c4-templates, c4-update, c4-verify |

## Skills

Agent skills for code quality analysis (language-agnostic):

| Skill | Purpose |
| ----- | ------- |
| `complexity` | Analyze and reduce code complexity |
| `deadcode` | Find and remove unused code |
| `docs` | Generate and improve documentation |
| `janitor` | General code cleanup tasks |
| `security` | Security vulnerability analysis |
| `types` | Type safety improvements |

## Hooks

| Hook | Purpose |
| ---- | ------- |
| `session-start-context` | Detects project type and git status |
| `stop-notification` | Plays sounds on task completion |
| `pre-tool-cloud-ops` | Prompts before destructive cloud operations |
| `pre-tool-branch-protection` | Prompts before commits to protected branches |
| `pre-tool-destructive-git` | Prompts before force push, hard reset |
| `pre-tool-destructive-bash` | Prompts before rm -rf, mkfs, chmod 777 |
| `prompt-expand-shorthand` | Expands shortcuts: gd, assume, edge, hunt |

## License

MIT

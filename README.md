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
| `/ai-config/` | verify-claude-md, verify-readme, prune-claude-md |
| `/analysis/` | debt, e2e, perf, review, spec, split |
| `/git/` | compush, feature-start, merge, pr, prune, release, sync |
| `/infra/` | az-costs, az-status, deploy, docker |
| `/quality/` | check, deps-update, janitor, tests, verify-no-mocks |
| `/quality/clean/` | cruft, emojis |
| `/quality/js-quality/` | complexity, deadcode, docs, security, types |
| `/quality/py-quality/` | complexity, deadcode, docs, security, types |
| `/quality/dotnet-quality/` | complexity, deadcode, docs, security, types |
| `/viz/` | c4-map, c4-verify, c4-update, c4-templates, anki |

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

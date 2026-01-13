# kokko-cmds

Claude Code plugin for C4 architecture mapping, code analysis, quality checks, git workflows, and infrastructure management.

## Installation

```bash
/plugin marketplace add kokko-ng/kokko-cmds
/plugin install kokko-cmds@kokko-ng-kokko-cmds
```

## Commands

| Category | Commands |
|----------|----------|
| `/ai-config/` | verify-claude-md, verify-readme, prune-claude-md, prune-readme |
| `/analysis/` | debt, e2e, perf, review, spec, split |
| `/git/` | compush, feature-start, merge, pr, prune, release, sync |
| `/infra/` | az-costs, az-status, deploy, docker |
| `/quality/` | check, deps-update, janitor, tests |
| `/quality/clean/` | cruft, emojis |
| `/quality/js-quality/` | complexity, deadcode, docs, security, types |
| `/quality/py-quality/` | complexity, deadcode, docs, security, types |
| `/viz/` | c4-map, c4-verify, c4-checklist, c4-update, c4-templates, anki-generate, anki-verify |

## License

MIT

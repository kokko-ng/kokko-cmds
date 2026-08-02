# kokko-ai-config

AI configuration management: keep CLAUDE.md and README files small and
truthful. One command trims them to the essentials, the other audits them
against the actual codebase.

```bash
/plugin install kokko-ai-config@kokko-ng-kokko-cmds
```

## Commands

| Command | Purpose |
| ------- | ------- |
| `/prune-docs` | Trim CLAUDE.md or README.md to the essentials under a line target |
| `/verify-docs` | Audit CLAUDE.md or README.md against the codebase and fix inaccuracies |

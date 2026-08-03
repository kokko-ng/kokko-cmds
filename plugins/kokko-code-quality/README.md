# kokko-code-quality

Code analysis commands and quality skills: technical debt, performance,
review, specs, dead code, security, types, complexity, docs, and
architecture enforcement across Python, JavaScript/TypeScript, and .NET.

```bash
/plugin install kokko-code-quality@kokko-ng-kokko-cmds
```

## Commands

| Command | Purpose |
| ------- | ------- |
| `/debt` | Deep-read a target to identify technical debt and build a remediation roadmap |
| `/perf` | Identify performance bottlenecks and recommend prioritized fixes |
| `/review` | Direct, no-nonsense code review with a clear merge verdict |
| `/spec` | Generate a test specification documenting all testable user stories |
| `/split` | Find oversized files and split them into focused modules |
| `/verify-spec` | Validate a spec.md for structure, completeness, and codebase alignment |
| `/check` | Run pre-commit until it passes, fixing every issue without skipping hooks |
| `/deps-update` | Interactively update outdated dependencies with validation between each |
| `/verify-no-mocks` | Scan production code for mock/stub/dummy data and unconfigured integrations |
| `/cruft` | Find and remove repository cruft not covered by .gitignore, with confirmation |
| `/emojis` | Remove emojis from source files while preserving code functionality |

## Skills

Each skill picks the right tool per language (Python / JS-TS / .NET) and
carries per-language references.

| Skill | Purpose |
| ----- | ------- |
| `architecture` | Enforce layering and import rules (import-linter / dependency-cruiser) |
| `complexity` | Measure and reduce code complexity (radon / ESLint / .NET analyzers) |
| `deadcode` | Detect and remove dead code (vulture / knip / .NET analyzers) |
| `docs` | Check and improve documentation coverage (interrogate / eslint-plugin-jsdoc / XML docs) |
| `security` | Security analysis and fixes (bandit / eslint-plugin-security + npm audit / SecurityCodeScan) |
| `types` | Strengthen type safety (mypy / tsc / nullable reference analyzers) |

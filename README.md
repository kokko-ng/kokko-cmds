# kokko-cmds

A comprehensive Claude Code plugin with commands for C4 architecture mapping, code analysis, quality checks, git workflows, infrastructure management, and AI configuration.

## Installation

```bash
/plugin marketplace add kokko-ng/kokko-cmds
/plugin install kokko-cmds@kokko-ng-kokko-cmds
```

## Commands

### AI Configuration (`/ai-config/`)
- `/ai-config/verify-claude-md` - Verify CLAUDE.md file accuracy
- `/ai-config/verify-readme` - Verify README.md file accuracy
- `/ai-config/prune-claude-md` - Remove unnecessary content from CLAUDE.md
- `/ai-config/prune-readme` - Remove unnecessary content from README.md

### Analysis (`/analysis/`)
- `/analysis/debt` - Analyze technical debt in the codebase
- `/analysis/e2e` - End-to-end analysis
- `/analysis/perf` - Performance analysis
- `/analysis/review` - Code review analysis
- `/analysis/spec` - Specification analysis
- `/analysis/split` - Code splitting analysis

### Git Workflows (`/git/`)
- `/git/compush` - Commit and push changes
- `/git/feature-start` - Start a new feature branch
- `/git/merge` - Merge branches
- `/git/pr` - Create pull request
- `/git/prune` - Prune stale branches
- `/git/release` - Create a release
- `/git/sync` - Sync with remote

### Infrastructure (`/infra/`)
- `/infra/az-costs` - Azure cost analysis
- `/infra/az-status` - Azure resource status
- `/infra/deploy` - Deployment commands
- `/infra/docker` - Docker operations

### Quality (`/quality/`)
- `/quality/check` - Run quality checks
- `/quality/deps-update` - Update dependencies
- `/quality/janitor` - Code cleanup tasks
- `/quality/tests` - Run tests

#### Clean Utilities (`/quality/clean/`)
- `/quality/clean/cruft` - Remove cruft files
- `/quality/clean/emojis` - Remove emojis from code

#### JavaScript Quality (`/quality/js-quality/`)
- `/quality/js-quality/complexity` - Analyze code complexity
- `/quality/js-quality/deadcode` - Find dead code
- `/quality/js-quality/docs` - Documentation analysis
- `/quality/js-quality/security` - Security analysis
- `/quality/js-quality/types` - Type checking

#### Python Quality (`/quality/py-quality/`)
- `/quality/py-quality/complexity` - Analyze code complexity
- `/quality/py-quality/deadcode` - Find dead code
- `/quality/py-quality/docs` - Documentation analysis
- `/quality/py-quality/security` - Security analysis
- `/quality/py-quality/types` - Type checking

### Visualization (`/viz/`)
- `/viz/c4-map` - Generate C4 architecture documentation
- `/viz/c4-verify` - Validate accuracy against actual codebase
- `/viz/c4-checklist` - Verify diagrams against C4 best practices
- `/viz/c4-update` - Update documentation to reflect changes
- `/viz/c4-templates` - C4 diagram templates
- `/viz/anki-generate` - Generate Anki flashcards from architecture
- `/viz/anki-verify` - Verify flashcard accuracy

## License

MIT

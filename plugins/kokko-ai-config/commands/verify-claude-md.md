---
description: Audit CLAUDE.md against the codebase and fix inaccuracies.
argument-hint: [claude-md-path]
allowed-tools: Read, Edit, Bash, Glob, Grep
---

# Verify CLAUDE.md Accuracy

Audit CLAUDE.md so it accurately reflects the current codebase, then fix what's wrong. Default path `./CLAUDE.md` (override via `$ARGUMENTS`).

## Steps

1. **Read** the CLAUDE.md and understand every instruction.
2. **Verify each claim** against reality:
   - Description and project structure match the actual repo.
   - Package manager matches lockfiles: `ls pyproject.toml uv.lock package.json pnpm-lock.yaml yarn.lock requirements.txt 2>/dev/null`.
   - Documented build/run/test commands execute successfully.
   - Referenced paths and directories exist.
   - Mentioned tools appear in dependency files; versions are current.
   - Config files and documented settings exist and match.
3. **Find missing context** worth adding: entry points / how to run, test commands and frameworks, required env vars / .env, key architectural patterns and conventions, external services (APIs, DBs).
4. **Flag outdated content:** references to deleted files, deprecated commands/workflows, old versions, obsolete config.
5. **Update** CLAUDE.md: remove outdated info, correct commands/paths, add missing critical context.
6. **Validate:** re-run documented commands and confirm referenced paths exist.

Done when all documented commands work, all paths exist, and no outdated info remains.

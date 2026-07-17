---
description: Audit CLAUDE.md or README.md against the codebase and fix inaccuracies.
argument-hint: '[claude-md|readme|<path>]'
allowed-tools: Read, Edit, Bash, Glob, Grep, WebFetch
---

# Verify Documentation Accuracy

Audit a documentation file so it accurately reflects the current codebase, then fix what's wrong. `$ARGUMENTS` selects the file — `claude-md` (`./CLAUDE.md`), `readme` (`./README.md`), or an explicit path (profile inferred from the filename; default: `claude-md`).

## Steps

1. **Read** the file and understand every instruction and claim.
2. **Verify each claim** against reality:
   - Description and project structure match the actual repo.
   - Package manager matches lockfiles: `ls pyproject.toml uv.lock package.json pnpm-lock.yaml yarn.lock requirements.txt 2>/dev/null`.
   - Prerequisites match installed tools/versions (`node --version`, `python --version`, `go version`, etc.).
   - Documented build/run/test/install commands execute successfully — run each code block from the project root and confirm the documented result.
   - Referenced paths and directories exist.
   - Mentioned tools appear in dependency files; versions are current.
   - Config files, env vars, and documented settings exist and match.
3. **Find missing essentials:** entry points / how to run, test commands and frameworks, required env vars (grep `process.env`, `os.environ`, `os.Getenv`), system dependencies (databases/services), default ports, key architectural patterns, external services (APIs, DBs), common setup errors.
4. **Check links** (README profile especially):
   - Internal: `grep -oE '\[.*\]\((\.?/[^)]+)\)' <path> | grep -oE '\(.*\)' | tr -d '()' | while read p; do [ ! -e "$p" ] && echo "Broken: $p"; done`
   - External: fetch each URL (docs, resources, badges, repo links) and confirm it resolves.
5. **Flag outdated content:** references to deleted files, deprecated commands/workflows, old versions, stale screenshots, obsolete config.
6. **Update** the file: remove outdated info, correct commands/paths/versions, fix broken links, add missing critical context.
7. **Validate:** re-run documented commands from scratch and confirm referenced paths exist and the project runs.

Done when all documented commands work, all paths and links resolve, and no outdated info remains.

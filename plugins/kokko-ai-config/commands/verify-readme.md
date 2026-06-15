---
description: Audit README.md accuracy, including links, and fix what's broken.
argument-hint: [readme-path]
allowed-tools: Read, Edit, Bash, Glob, Grep, WebFetch
---

# Verify README.md Accuracy

Audit README.md so it accurately reflects the codebase and provides working instructions, then fix inaccuracies. Default path `./README.md` (override via `$ARGUMENTS`).

## Steps

1. **Read** the README and understand all content.
2. **Verify each section** against reality:
   - Description accurately states what the code does.
   - Prerequisites match installed tools/versions (`node --version`, `python --version`, `go version`, etc.).
   - Install and run/start commands execute without errors and the app starts.
   - Documented config files and env vars exist and are accurate.
   - Referenced paths and directories exist.
3. **Test every code block:** run the exact command in the project root and confirm it produces the documented result.
4. **Check for missing essentials:** env vars (grep `process.env`, `os.environ`, `os.Getenv`), system dependencies (databases/services), default ports, common setup errors.
5. **Check links:**
   - Internal: `grep -oE '\[.*\]\((\.?/[^)]+)\)' <path> | grep -oE '\(.*\)' | tr -d '()' | while read p; do [ ! -e "$p" ] && echo "Broken: $p"; done`
   - External: fetch each URL (docs, resources, badges, repo links) and confirm it resolves.
6. **Flag outdated content:** removed files / deprecated features, old version numbers, stale screenshots, failing commands.
7. **Update** README: fix commands, versions, paths, and broken links; add missing setup steps.
8. **Validate:** follow the instructions from scratch and confirm the project runs.

Done when all commands work, all links resolve, and no outdated info remains.

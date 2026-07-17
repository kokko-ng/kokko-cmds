---
description: Trim CLAUDE.md or README.md to the essentials under a line target.
argument-hint: '[claude-md|readme|<path>] [--target-lines N]'
allowed-tools: Read, Edit, Bash(wc:*)
---

# Prune Documentation

Reduce a documentation file to only what its audience needs. `$ARGUMENTS` selects the file — `claude-md` (`./CLAUDE.md`), `readme` (`./README.md`), or an explicit path (profile inferred from the filename; default: `claude-md`) — plus an optional `--target-lines N` override.

Profiles:

- **CLAUDE.md** — audience: an agent working in the repo. Default target 300 lines.
- **README.md** — audience: a new developer going from clone to running. Default target ~100 lines (simple project) / ~200 (complex).

## Steps

1. Measure current size: `wc -l <path>`.
2. Categorize and cut by priority, using the profile for the file:

   **CLAUDE.md profile:**
   - **Keep:** project-specific commands (build/test/run), critical constraints, non-obvious architectural decisions, environment setup essentials.
   - **Keep if space:** code style beyond linting, codebase-specific gotchas, key file locations.
   - **Remove:** general programming advice, explanations of standard tools, verbose examples, aspirational/unenforced guidelines, redundancy, obvious project structure, anything inferable from code or already known to Claude.

   **README profile:**
   - **Keep:** project name + one-line description, prerequisites (language version, required tools), install steps, basic usage/run command.
   - **Keep if space:** brief config options, common troubleshooting, contributing (or link), license.
   - **Remove:** lengthy architecture (move to docs/), redundant usage examples (keep one + link), changelog content (use CHANGELOG.md), verbose feature lists, non-essential screenshots/badges, anything obvious from code or duplicated elsewhere.

3. Apply compression: consolidate related points, prefer bullets over paragraphs, drop filler/qualifiers, replace examples with patterns, link to docs instead of duplicating. For READMEs also: tables for options/config, a single copy-paste install+run block, collapse optional sections with details/summary where supported.
4. Re-measure with `wc -l`. If still over target, loop back to step 2.

## Effectiveness check

- CLAUDE.md: "Could an agent complete common tasks with only this file?"
- README: "Could a new developer go from clone to running in 5 minutes?"

If no, add back the minimum context needed. Done when under the target line count with all critical content retained.

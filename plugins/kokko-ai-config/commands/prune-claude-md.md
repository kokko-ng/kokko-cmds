---
description: Trim CLAUDE.md to essential, agent-relevant context under a line target.
argument-hint: [claude-md-path] [--target-lines N]
allowed-tools: Read, Edit, Bash(wc:*)
---

# Prune CLAUDE.md

Reduce CLAUDE.md to only the context an agent needs to work effectively. Default path `./CLAUDE.md`, default target 300 lines (override via `$ARGUMENTS`).

## Steps

1. Measure current size: `wc -l <path>`.
2. Categorize and cut by priority:
   - **Keep:** project-specific commands (build/test/run), critical constraints, non-obvious architectural decisions, environment setup essentials.
   - **Keep if space:** code style beyond linting, codebase-specific gotchas, key file locations.
   - **Remove:** general programming advice, explanations of standard tools, verbose examples, aspirational/unenforced guidelines, redundancy, obvious project structure, anything inferable from code or already known to Claude.
3. Apply compression: consolidate related points, prefer bullets over paragraphs, drop filler/qualifiers, replace examples with patterns, link to docs instead of duplicating, use code blocks only for non-obvious commands.
4. Re-measure with `wc -l`. If still over target, loop back to step 2.

## Effectiveness check

Ask: "Could an agent complete common tasks with only this CLAUDE.md?" If no, add back the minimum context needed.

Done when under the target line count with all critical context retained.

---
description: Trim README.md to the essentials for fast developer onboarding.
argument-hint: [readme-path] [--target-lines N]
allowed-tools: Read, Edit, Bash(wc:*)
---

# Prune README.md

Reduce README.md to what a new developer needs to go from clone to running quickly. Default path `./README.md`, default target ~100 lines (simple) / ~200 (complex); override via `$ARGUMENTS`.

## Steps

1. Measure current size: `wc -l <path>`.
2. Categorize and cut by priority:
   - **Keep:** project name + one-line description, prerequisites (language version, required tools), install steps, basic usage/run command.
   - **Keep if space:** brief config options, common troubleshooting, contributing (or link), license.
   - **Remove:** lengthy architecture (move to docs/), redundant usage examples (keep one + link), changelog content (use CHANGELOG.md), verbose feature lists, non-essential screenshots/badges, anything obvious from code or duplicated elsewhere.
3. Apply compression: tables for options/config, a single copy-paste install+run block, link to docs instead of duplicating, drop uninformative badges, collapse optional sections with details/summary where supported.
4. Re-measure with `wc -l`. If still over target, loop back to step 2.

## Effectiveness check

Ask: "Could a new developer go from clone to running in 5 minutes?" If no, add back the minimum steps needed.

Done when under the target line count with a clear, scannable structure.

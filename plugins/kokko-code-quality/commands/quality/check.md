---
description: Run pre-commit until it passes, fixing every issue without skipping hooks.
allowed-tools: Bash(pre-commit:*), Read, Edit
---

# Pre-commit Check

Iteratively run `pre-commit run --all-files` and address every reported
linting/formatting issue until the command exits cleanly with no failures.
Do not skip hooks, disable rules, or add ignores/exclusions. Only introduce
an exception if it's truly unavoidable; in that case, document the rationale
and keep the scope as narrow as possible.

---
description: Remove emojis from source files while preserving code functionality.
argument-hint: '[target]'
allowed-tools: Bash, Grep, Read, Edit
disable-model-invocation: true
---

# Remove Emojis

Remove emojis from `$1` (default when empty: current project root) without
changing behavior.

## 1. Find

```bash
rg -n '[\p{Emoji}--\p{ASCII}]' --type py --type ts --type js --type vue --type md
# fallback:
grep -rnP '[\x{1F300}-\x{1F9FF}]|[\x{2600}-\x{26FF}]|[\x{2700}-\x{27BF}]' .
```

## 2. Categorize each hit

- **Remove**: decorative emojis in comments, logs, UI strings.
- **Replace**: semantically meaningful emojis → text equivalent.
- **Keep**: test fixtures/data that intentionally contain emojis.

Skip `node_modules/`, `.venv/`, `venv/`, `__pycache__/`, vendored code, binaries.

## 3. Edit and verify

Preserve surrounding quotes/string meaning to avoid syntax errors. Then:

```bash
rg '[\p{Emoji}--\p{ASCII}]' --type py --type ts --type js   # confirm none remain
uv run pytest   # or npm test
```

If a test expected an emoji in output, update the expectation rather than
re-adding the emoji.

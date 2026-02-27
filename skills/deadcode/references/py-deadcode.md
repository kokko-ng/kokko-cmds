# Python Dead Code Detection with Vulture

## Prerequisites

```bash
uv add --dev vulture
```

## Commands

```bash
# Run dead code analysis
uv run vulture . --exclude .venv,venv,node_modules,__pycache__

# Specific directories
uv run vulture src/ lib/

# With whitelist
uv run vulture . vulture_whitelist.py --exclude .venv
```

## Verification Checklist

For each item detected, **thoroughly verify** it is truly unused:

**Cross-check references:**

- All internal imports across the codebase
- Dynamic imports (`importlib`, `__import__`)
- Entry points in `pyproject.toml` or `setup.py`
- Config-based registries and plugin systems
- Decorator registrations
- Metaprogramming patterns

**Check for indirect usage:**

- Reflection: `getattr()`, `globals()`, `locals()`
- String-based access: `eval()`, `exec()`
- Framework magic (Django models, FastAPI routes, pytest fixtures)
- CLI command definitions
- Template references

## Removal Process

**Only if absolutely certain the code is unused:**

1. Remove the dead code
2. Create a separate commit:

   ```bash
   git add .
   git commit -m "chore(cleanup): remove unused <function_name>"
   ```

## Handle One Item at a Time

Do NOT batch deletions. Process one finding at a time to maintain
traceability and safety.

## Whitelist for False Positives

Create a whitelist file for code used but not detected:

```python
# vulture_whitelist.py
from mymodule import used_by_framework  # noqa: F401
used_by_framework  # Mark as used
```

## Commit Format

```text
chore(cleanup): remove unused <function_name>
```

## Error Recovery

| Issue | Resolution |
| ----- | ---------- |
| Import errors | Check all import paths |
| False positive | Add to whitelist |

## Final Quality Gate

```bash
uv run vulture . vulture_whitelist.py --exclude .venv
```

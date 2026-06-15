---
description: Find oversized files and split them into focused, single-responsibility modules.
argument-hint: [target] [--threshold lines]
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Split Large Files

Find and split large files in `$1` (default: current project) to improve
maintainability. Threshold defaults to 500 lines (override with `--threshold`).

## 1. Identify Candidates

Files over the threshold, with many distinct concerns, or violating SRP.

```bash
# Python
find . -name "*.py" -not -path "./.venv/*" -exec wc -l {} + | sort -rn | head -20
# TS/JS
find . \( -name "*.ts" -o -name "*.js" \) \
  | grep -v node_modules | xargs wc -l | sort -rn | head -20
```

## 2. Plan the Split

For each candidate, count distinct classes/functions, identify separate
concerns, and choose natural split points. Separate by domain (models,
services, utils, validators), cohesion, dependencies (avoid cycles), or feature.

## 3. Execute

1. Create module structure (`mkdir -p module_name/`, add `__init__.py` /
   `index.ts`).
2. Move related code into new files.
3. Update imports across the codebase:
   ```bash
   grep -r "from old_module import" --include="*.py"
   grep -r "import.*from.*old_module" --include="*.ts"
   ```
4. Create an index file exposing a clean public API.
5. Maintain backward compatibility where useful: re-export from the original
   location, add deprecation warnings.

## 4. Verify

```bash
uv run pytest --collect-only   # Python: no circular deps
npx tsc --noEmit               # TS: no import errors
uv run pytest                  # or npm test
```

Commit incrementally: `git commit -m "refactor(<module>): split <file> into <components>"`.

## Notes

- Circular imports: extract shared code into its own module.
- Broken imports after a move: update the index file and test imports.

# Python Type Checking with mypy

## Prerequisites

```bash
uv add --dev mypy
```

Install type stubs as needed:

```bash
uv add --dev types-requests types-PyYAML types-redis
```

## Commands

```bash
# Run type check
uv run mypy . --exclude venv --exclude .venv --exclude node_modules

# Specific directories
uv run mypy src/ tests/
```

## Common Errors and Fixes

| Error Code | Description | Fix |
| ---------- | ----------- | --- |
| `[assignment]` | Incompatible types | Fix type or add proper annotation |
| `[arg-type]` | Argument type mismatch | Fix argument or update signature |
| `[return-value]` | Return type mismatch | Fix return or annotation |
| `[name-defined]` | Name not defined | Import missing type or fix typo |
| `[attr-defined]` | Attribute not defined | Add attribute or fix access |
| `[union-attr]` | Access on Optional | Add None check or use `assert` |
| `[no-untyped-def]` | Missing annotations | Add param and return types |
| `[import]` | Cannot find module | Install stubs or add to ignore list |
| `[misc]` | Various issues | Read message carefully |

## Handle External Dependencies

Add to `pyproject.toml`:

```toml
[tool.mypy]
ignore_missing_imports = true

# Or ignore specific packages
[[tool.mypy.overrides]]
module = ["some_package.*", "another_package"]
ignore_missing_imports = true
```

## Configure Strictness

Add to `pyproject.toml`:

```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
no_implicit_optional = true
```

## Avoiding `Any` Types

**CRITICAL**: Avoid `Any` types unless absolutely necessary.

**Instead of `Any`, use:**

- `object` - for truly unknown types that you won't access
- `TypeVar` - for generic functions preserving type relationships
- `Union[X, Y]` - when value can be one of several types
- `Protocol` - for structural typing (duck typing with safety)
- `Callable[..., T]` - for functions with unknown parameters
- `dict[str, object]` - instead of `dict[str, Any]`

**If `Any` is unavoidable:**

- Add a comment explaining why
- Limit scope as much as possible
- Consider wrapping in a function with proper types at boundaries

## Validation

After each fix:

```bash
uv run mypy path/to/file.py
```

## Commit Format

```text
fix(types): resolve mypy errors in <module>
```

## Final Quality Gate

```bash
uv run mypy . --exclude venv
```

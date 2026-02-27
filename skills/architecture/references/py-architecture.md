# Python Architecture Enforcement with import-linter

## Prerequisites

```bash
uv add --dev import-linter
```

## Configuration

import-linter reads from `pyproject.toml` under `[tool.importlinter]`, or from
a standalone `.importlinter` file.

### Bootstrap (if no config exists)

Add a minimal config to `pyproject.toml`:

```toml
[tool.importlinter]
root_packages = ["<your_package>"]

[[tool.importlinter.contracts]]
name = "Layered architecture"
type = "layers"
layers = [
    "api",
    "services",
    "domain",
    "infrastructure",
]
```

Adjust `root_packages` and `layers` to match the project's actual package
structure. Inspect `src/` or the top-level package to determine real layer
names before generating config.

## Commands

```bash
# Run all contracts
uv run lint-imports

# Verbose output (shows checked imports)
uv run lint-imports --verbose
```

Output is plain text. A passing run prints `SUCCESS` per contract. Violations
print the contract name, violation type, and the offending import chain.

## Contract Types

| Type | Purpose | Example |
| ---- | ------- | ------- |
| `layers` | One-directional layer deps | API -> Services -> Domain |
| `forbidden` | Ban specific import paths | No `domain` importing `api` |
| `independence` | No cross-imports between modules | `billing` / `shipping` |
| `acyclic_siblings` | No sibling package cycles | Subpkgs under `services/` |

### Layers Contract

```toml
[[tool.importlinter.contracts]]
name = "Application layers"
type = "layers"
layers = ["api", "services", "domain", "infrastructure"]
```

Higher layers may import lower layers but not vice versa.

### Forbidden Contract

```toml
[[tool.importlinter.contracts]]
name = "Domain purity"
type = "forbidden"
source_modules = ["myapp.domain"]
forbidden_modules = ["myapp.api", "myapp.infrastructure"]
```

### Independence Contract

```toml
[[tool.importlinter.contracts]]
name = "Module independence"
type = "independence"
modules = ["myapp.billing", "myapp.shipping", "myapp.inventory"]
```

### Acyclic Siblings Contract

```toml
[[tool.importlinter.contracts]]
name = "No sibling cycles"
type = "acyclic_siblings"
source_module = "myapp.services"
```

## Parsing Violations

import-linter outputs text like:

```text
BROKEN CONTRACTS
================

Layered architecture
--------------------
myapp.domain.models imports myapp.api.views (layer 'domain' is not allowed
to import layer 'api')
```

Parse each violation for:

- Contract name
- Source module and imported module
- Violation direction

## Fix Tactics

| Violation | Fix |
| --------- | --- |
| Lower layer imports upper | Move shared types down or add protocol |
| Circular dependency | Extract shared code into a new module |
| Forbidden import | Use dependency injection or events |
| Sibling cycle | Extract shared utilities into a common subpackage |

### Breaking Cycles

1. Identify the shared dependency causing the cycle
2. Extract it into a new module (e.g., `myapp.common.types`)
3. Update both sides to import from the extracted module
4. Remove the direct cross-import

### Introducing Protocols

When a lower layer needs behavior from an upper layer:

```python
# domain/ports.py
from typing import Protocol

class NotificationSender(Protocol):
    def send(self, message: str) -> None: ...

# services/notifications.py
class EmailNotifier:
    def send(self, message: str) -> None:
        ...  # implementation
```

## Validation

After each fix:

```bash
uv run lint-imports
```

## Commit Format

```text
refactor(architecture): <description of structural change>
```

Examples:

- `refactor(architecture): extract shared types to domain.common`
- `refactor(architecture): break cycle between billing and shipping`
- `refactor(architecture): introduce NotificationSender protocol`

## Final Quality Gate

```bash
uv run lint-imports
uv run pre-commit run --all-files
```

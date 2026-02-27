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

### Rich output workaround

import-linter v2.10+ uses Python Rich for output, rendering Unicode
box-drawing characters that are unreadable when captured in non-TTY contexts.
`NO_COLOR=1` and `TERM=dumb` strip ANSI escapes but NOT the Unicode glyphs.

**Use the API directly** to get structured, parseable results:

```python
import io, os, sys
sys.path.insert(0, os.getcwd())

from rich.console import Console as RichConsole
from importlinter import configuration

configuration.configure()

buf = io.StringIO()
capturing_console = RichConsole(
    file=buf, force_terminal=False, no_color=True, width=200
)

import importlinter.application.output as output_mod
output_mod.console = capturing_console

from importlinter.application.use_cases import lint_imports
result = lint_imports()

captured = buf.getvalue()
print(captured)
print(f"Result: {'PASS' if result else 'FAIL'}")
```

This monkey-patches the global Rich Console so output goes to a StringIO
buffer. With `force_terminal=False`, Rich strips control codes and the text
content (contract names, KEPT/BROKEN status) comes through readable.

### Standalone modules

`root_packages` only accepts Python **packages** (directories with
`__init__.py`), not standalone `.py` modules. If the project has standalone
modules like `config.py` or `database.py`, exclude them from `root_packages`.
They cannot be tracked by import-linter but can be imported freely by any
layer.

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

When using the Rich output workaround above, the captured output contains
readable text like:

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

# Python Complexity Analysis with Radon

## Prerequisites

```bash
uv add --dev radon
```

## Commands

```bash
# Cyclomatic complexity (A=best, F=worst)
uv run radon cc -s -a . --exclude "venv/*,.venv/*"

# Maintainability Index (100=best, 0=worst)
uv run radon mi -s . --exclude "venv/*,.venv/*"

# Halstead metrics (optional, for detailed analysis)
uv run radon hal . --exclude "venv/*,.venv/*"
```

## Thresholds

Target functions/classes with:

- Complexity grade >= C (or numeric > 10)
- Maintainability Index < 65

## Prioritization

Rank by:

1. Worst grade (F, E, D first)
2. Frequency of change (`git log -p --follow <file>`)
3. Business criticality

## Refactor Tactics

Apply one tactic at a time:

- **Extract Function/Method** - Break out cohesive blocks
- **Decompose Conditionals** - Use strategy maps, dict dispatch, guard clauses
- **Remove Duplication** - DRY or inline trivial indirections
- **Simplify Boolean Logic** - Early returns, De Morgan's laws
- **Replace Deep Nesting** - Fail-fast exits, extract methods
- **Clarify Names** - Rename unclear variables/functions
- **Isolate Side Effects** - Separate pure logic from I/O
- **Reduce Parameters** - Introduce dataclass or typed object
- **Split Large Classes** - Single Responsibility Principle

## Validation

After each micro-change:

```bash
uv run radon cc -s <target_file>
uv run radon mi -s <target_file>
```

## Commit Format

```text
refactor(radon): reduce complexity in <symbol> (C->B)
```

## When to Stop

- Complexity <= B grade
- Maintainability Index >= 70
- Further changes risk unnecessary churn

## Hard Cases

If complexity resists decomposition:

- Introduce a decision table or data-driven structure
- Split algorithm into phases (parse -> transform -> emit)
- Accept temporary adapter layer while migrating callers

## Final Quality Gate

```bash
uv run radon cc -s -a .
uv run radon mi -s .
uv run pre-commit run --all-files
```

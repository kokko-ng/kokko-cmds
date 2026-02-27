# JavaScript/TypeScript Architecture Enforcement with dependency-cruiser

## Prerequisites

```bash
npm install -D dependency-cruiser
```

## Configuration

dependency-cruiser uses `.dependency-cruiser.cjs` (or `.mjs` / `.json`).

### Bootstrap (if no config exists)

```bash
npx depcruise --init
```

This generates a starter `.dependency-cruiser.cjs` with sensible defaults.
Review and adjust the `forbidden` rules and `allowedSeverity` to match the
project's architecture.

## Commands

```bash
# JSON output for structured parsing
npx depcruise src -T json

# Human-readable error output
npx depcruise src -T err

# With metrics (instability, afferent/efferent coupling)
npx depcruise src -T json --metrics

# Validate against config
npx depcruise src --config .dependency-cruiser.cjs -T err

# Generate baseline for incremental adoption
npx depcruise src -T json > .dependency-cruiser-known-violations.json

# Run ignoring known violations
npx depcruise src --config .dependency-cruiser.cjs --ignore-known -T err
```

## Rule Types

### Circular Dependencies

```javascript
{
  name: "no-circular",
  severity: "error",
  from: {},
  to: { circular: true }
}
```

### Forbidden Dependencies (path-based)

```javascript
{
  name: "no-domain-to-infrastructure",
  severity: "error",
  from: { path: "^src/domain" },
  to: { path: "^src/infrastructure" }
}
```

### Orphan Detection

```javascript
{
  name: "no-orphans",
  severity: "warn",
  from: {
    orphan: true,
    pathNot: ["\\.(test|spec)\\.", "\\.d\\.ts$"]
  },
  to: {}
}
```

### Folder-Level Coupling

```javascript
{
  name: "feature-isolation",
  severity: "error",
  from: { path: "^src/features/([^/]+)/" },
  to: {
    path: "^src/features/([^/]+)/",
    pathNot: "^src/features/$1/"
  }
}
```

## Parsing JSON Output

The JSON output structure:

```json
{
  "modules": [...],
  "summary": {
    "violations": [
      {
        "type": "cycle",
        "from": "src/a.ts",
        "to": "src/b.ts",
        "rule": { "name": "no-circular", "severity": "error" },
        "cycle": ["src/a.ts", "src/b.ts", "src/c.ts"]
      }
    ],
    "error": 2,
    "warn": 1,
    "info": 0,
    "totalCruised": 42
  }
}
```

Parse `summary.violations` array. Each violation has `type`, `from`, `to`,
`rule.name`, and `rule.severity`.

## Metrics

When using `--metrics`, each module includes:

| Metric | Meaning |
| ------ | ------- |
| `Ca` | Afferent coupling (incoming dependencies) |
| `Ce` | Efferent coupling (outgoing dependencies) |
| `I` | Instability = Ce / (Ca + Ce), range 0..1 |

Modules with high `I` (close to 1) are unstable and depend on many others.
Modules with low `I` (close to 0) are stable and depended upon by many others.
Violations of the Stable Dependencies Principle occur when a stable module
depends on an unstable one.

## Fix Tactics

| Violation | Fix |
| --------- | --- |
| Circular dependency | Extract shared code into a new module |
| Forbidden cross-layer import | Move to allowed layer or add facade |
| Feature cross-contamination | Extract shared types to `src/shared/` |
| High coupling (high Ce) | Introduce interfaces, use dependency injection |
| Orphan module | Remove if unused, or integrate into dependency graph |

### Breaking Cycles

1. Run `npx depcruise src -T json` and find `cycle` violations
2. Identify the shared dependency causing the cycle
3. Extract it into `src/shared/` or a common utility module
4. Update imports in both modules to reference the extracted module
5. Re-run to confirm cycle is broken

### Enforcing Layers

Typical layer structure:

```text
src/
  presentation/   (or pages/, routes/, components/)
  application/    (or services/, use-cases/)
  domain/         (or models/, entities/)
  infrastructure/ (or adapters/, lib/)
```

Rules should enforce: presentation -> application -> domain <- infrastructure.
Domain must not import from presentation or application.

### Incremental Adoption

For existing projects with many violations:

1. Generate baseline: `npx depcruise src -T json > .dependency-cruiser-known-violations.json`
2. Add `--ignore-known` to CI runs
3. Fix violations incrementally, removing them from the baseline file
4. Target zero new violations while reducing the baseline over time

## Validation

After each fix:

```bash
npx depcruise src --config .dependency-cruiser.cjs -T err
```

## Commit Format

```text
refactor(architecture): <description of structural change>
```

Examples:

- `refactor(architecture): break cycle between auth and user modules`
- `refactor(architecture): extract shared types to src/common`
- `refactor(architecture): enforce domain layer isolation`

## Final Quality Gate

```bash
npx depcruise src --config .dependency-cruiser.cjs -T err
npx eslint .
```

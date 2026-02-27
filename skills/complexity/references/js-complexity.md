# JavaScript/TypeScript Complexity Analysis

## Prerequisites

- ESLint configured in the project

## Commands

```bash
# Check cyclomatic complexity
npx eslint . --ext .js,.ts,.vue --rule 'complexity: ["warn", 10]'
```

## Thresholds

Target functions with:

- Cyclomatic complexity > 10
- Many branches (if/else, switch)
- Deep nesting levels (> 3)
- High cognitive complexity

## Configure ESLint Rules

Add to ESLint config:

```javascript
{
  rules: {
    'complexity': ['warn', { max: 10 }],
    'max-depth': ['warn', 4],
    'max-nested-callbacks': ['warn', 3],
    'max-lines-per-function': ['warn', { max: 50 }]
  }
}
```

## Refactor Tactics

Apply one tactic at a time:

- **Extract function** for cohesive logic blocks
- **Guard clauses** replace nested conditionals with early returns
- **Object lookup maps** replace switch statements
- **async/await** replace nested callbacks
- **Decompose by responsibility** split large functions
- **Named predicates** extract complex conditions into functions
- **Strategy pattern** for variant behavior
- **Split components** with multiple concerns

## Validation

After each change:

```bash
npx eslint <target_file> --rule 'complexity: ["error", 10]'
```

## Commit Format

```text
refactor(complexity): reduce complexity in <function>
```

## When to Stop

- Complexity <= 10
- Max nesting <= 3
- Function length reasonable
- Further splitting reduces readability

## Final Quality Gate

```bash
npx eslint . --ext .js,.ts,.vue
npm run build 2>/dev/null || npm run build:check 2>/dev/null || true
```

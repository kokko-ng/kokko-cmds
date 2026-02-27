# JavaScript/TypeScript Documentation with JSDoc

## Prerequisites

```bash
npm install -D eslint-plugin-jsdoc
```

## Configure ESLint

Add to ESLint config:

```javascript
{
  plugins: ['jsdoc'],
  extends: ['plugin:jsdoc/recommended-typescript'],
  rules: {
    'jsdoc/require-jsdoc': ['warn', {
      require: {
        FunctionDeclaration: true,
        MethodDefinition: true,
        ClassDeclaration: true,
        ArrowFunctionExpression: false,
        FunctionExpression: false
      }
    }],
    'jsdoc/require-description': 'warn',
    'jsdoc/require-param-description': 'warn',
    'jsdoc/require-returns-description': 'warn'
  }
}
```

## Commands

```bash
# Run JSDoc analysis
npx eslint . --ext .js,.ts,.vue --rule 'jsdoc/require-jsdoc: warn'
```

## Processing Order

Work through files systematically:

1. Public API functions and classes
2. Complex functions in components
3. Store actions and getters
4. Utility functions and helpers
5. Internal/private functions

## JSDoc Standards

**For functions:**

```typescript
/**
 * Short one-line summary ending with period.
 *
 * Longer description if needed. Explain the purpose,
 * not the implementation.
 *
 * @param param1 - Description of first parameter.
 * @param param2 - Description of second parameter.
 * @returns Description of return value.
 * @throws {Error} When param2 is negative.
 *
 * @example
 * ```ts
 * const result = functionName('value', 42);
 * ```
 */
function functionName(param1: string, param2: number): boolean {
  // ...
}
```

**For classes:**

```typescript
/**
 * Short one-line summary.
 *
 * Longer description of the class purpose and usage.
 */
class ClassName {
  /** Description of property. */
  propertyName: string;

  /**
   * Creates an instance of ClassName.
   * @param config - Configuration options.
   */
  constructor(config: Config) {
    // ...
  }
}
```

## Validation

After fixing each file:

```bash
npx eslint <file> --ext .ts,.vue
```

## Commit Format

```text
docs(<module>): add JSDoc to <file>
```

## Error Handling

| Issue | Resolution |
| ----- | ---------- |
| TypeScript conflicts | Use `plugin:jsdoc/recommended-typescript` |
| Too many warnings | Process file by file |
| Vue SFC issues | Focus on script section |

## Final Quality Gate

```bash
npx eslint . --ext .js,.ts,.vue
```

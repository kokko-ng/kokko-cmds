# JavaScript/TypeScript Security Analysis

## Prerequisites

- Node.js project with package.json
- ESLint configured (optional but recommended)

## Commands

### Dependency Vulnerability Scan

```bash
# Check for vulnerable dependencies
npm audit

# Only moderate and above
npm audit --audit-level=moderate

# JSON output for parsing
npm audit --json
```

### ESLint Security Rules

```bash
# Run ESLint with security focus
npx eslint . --ext .js,.ts,.vue --rule 'no-eval: error'
```

### Install Security Plugins (if missing)

```bash
npm install -D eslint-plugin-security @typescript-eslint/eslint-plugin
```

ESLint config addition:

```javascript
{
  plugins: ['security'],
  extends: ['plugin:security/recommended-legacy']
}
```

## Common Issues and Fixes

| Rule | Issue | Risk |
| ---- | ----- | ---- |
| detect-object-injection | Bracket notation with user input | Pollution |
| detect-non-literal-fs-filename | Dynamic file paths | Path traversal |
| detect-non-literal-regexp | User input in regex | ReDoS |
| detect-eval-with-expression | eval() with variables | Code injection |
| detect-no-csrf-before-method-override | CSRF vulnerability | CSRF |
| detect-possible-timing-attacks | String comparison timing | Info leak |

## Fix Patterns

| Issue | Fix |
| ----- | --- |
| `eval()` / `new Function()` | Use safe alternatives, `JSON.parse()` for data |
| `innerHTML` / `dangerouslySetInnerHTML` | Use `textContent` or DOMPurify |
| Dynamic `require()` | Use static imports |
| Unvalidated redirects | Whitelist allowed URLs |
| SQL/NoSQL injection | Use parameterized queries |
| Prototype pollution | Freeze objects, use `Object.create(null)` |

## Suppression Pattern

```javascript
// eslint-disable-next-line security/detect-object-injection
// key is validated enum
const value = obj[validatedKey];
```

## Validation

After each fix:

```bash
npx eslint <affected_files>
```

## Commit Format

```text
security(eslint): mitigate <issue> in <file>
```

## Final Quality Gate

```bash
npm audit --audit-level=high
npx eslint . --ext .js,.ts,.vue
```

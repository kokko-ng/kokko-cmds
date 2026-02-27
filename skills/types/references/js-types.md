# TypeScript Type Checking

## Prerequisites

```bash
npm install -D typescript
```

Requires `tsconfig.json` configured.

## Commands

```bash
# Run type check
npx tsc --noEmit

# Using project's build script
npm run build:check 2>/dev/null \
  || npm run typecheck 2>/dev/null \
  || npx tsc --noEmit

# Specific tsconfig
npx tsc --noEmit -p tsconfig.json
```

## Common Errors and Fixes

| Error Code | Description | Fix |
| ---------- | ----------- | --- |
| TS2339 | Property does not exist | Add to interface or type assertion |
| TS7006 | Parameter has implicit any | Add explicit type annotation |
| TS2345 | Argument type mismatch | Fix the type or use type guard |
| TS2322 | Type not assignable | Ensure types are compatible |
| TS2531 | Object possibly null | Add null check or optional chaining |
| TS2532 | Object possibly undefined | Add undefined check |
| TS18046 | Unknown type | Add type narrowing |
| TS2307 | Cannot find module | Install types or add declaration |
| TS2304 | Cannot find name | Import or declare the type |

## Configure Strict Mode

Ensure `tsconfig.json` includes:

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## Handle Third-Party Types

```bash
# Install type definitions
npm install -D @types/package-name

# Or create declaration file
echo "declare module 'package-name';" > src/types/package-name.d.ts
```

## Avoiding `any` Types

**CRITICAL**: Avoid `any` types unless absolutely necessary.

**Instead of `any`, use:**

- `unknown` - for truly unknown types (requires narrowing before use)
- `never` - for impossible states
- `Record<string, unknown>` - instead of `Record<string, any>`
- Generic types `<T>` - to preserve type relationships
- Union types `X | Y` - when value can be one of several types
- `Parameters<T>` / `ReturnType<T>` - to extract types from functions

**If `any` is unavoidable:**

- Add a comment explaining why
- Limit scope as much as possible
- Consider wrapping in a function with proper types at boundaries
- Use `// eslint-disable-next-line @typescript-eslint/no-explicit-any`
  with explanation

## Validation

After each fix:

```bash
npx tsc --noEmit <file>
```

## Commit Format

```text
fix(types): resolve TS<code> in <file>
```

## Final Quality Gate

```bash
npx tsc --noEmit
npm run build
```

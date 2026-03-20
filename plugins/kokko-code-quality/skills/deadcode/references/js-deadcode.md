# JavaScript/TypeScript Dead Code Detection with Knip

## Prerequisites

```bash
npm install -D knip
```

## Commands

```bash
# Run dead code analysis
npx knip

# Verbose output
npx knip --include files,exports,types,duplicates
```

## What Knip Detects

| Finding | Description |
| ------- | ----------- |
| Unused files | Files not imported anywhere |
| Unused exports | Exported items not imported elsewhere |
| Unused dependencies | Packages in package.json not used |
| Unused devDependencies | Dev packages not referenced |
| Unlisted dependencies | Used but not in package.json |
| Duplicate exports | Same thing exported multiple times |

## Verification Checklist

For each item detected, cross-check references:

**Check for indirect usage:**

- Dynamic imports: `import()`, `require()`
- String-based access: `components[name]`
- Vue/React template references
- Config file references (vite.config.ts, etc.)
- Test file usage
- Entry points in build config
- Plugin registrations
- Global component registration
- Runtime computed property access

## Removal Process

**If certain the code is unused:**

```bash
# Remove unused dependency
npm uninstall <package-name>

# Or remove unused file/export manually
```

## Commit Format

```text
chore(cleanup): remove unused <item>
```

## Configure Knip

Create `knip.json` for project-specific settings:

```json
{
  "entry": ["src/main.ts", "src/index.ts"],
  "project": ["src/**/*.{ts,tsx,vue}"],
  "ignore": ["**/*.d.ts", "**/test/**"],
  "ignoreDependencies": ["@types/*"]
}
```

For monorepos:

```json
{
  "workspaces": {
    "packages/*": {
      "entry": ["src/index.ts"]
    }
  }
}
```

## Error Recovery

| Issue | Resolution |
| ----- | ---------- |
| False positive on entry point | Add to `entry` in knip.json |
| Plugin not detected as used | Add to `ignoreDependencies` |
| Build fails after removal | Revert, investigate |

## Final Quality Gate

```bash
npx knip
npm run build
```

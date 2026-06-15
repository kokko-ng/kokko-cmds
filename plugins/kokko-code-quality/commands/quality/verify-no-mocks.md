---
description: Scan production code for mock/stub/dummy data and unconfigured integrations.
argument-hint: [target]
allowed-tools: Grep, Glob, Read, Bash
---

# Verify No Mocks in Production Code

Scan `$1` (default: project root) to confirm production code uses real
integrations, not mock/stub/dummy data. Exclude test paths: `test/`, `tests/`,
`__tests__/`, `spec/`, `*_test.*`, `*.test.*`, `*.spec.*`.

## Patterns to flag (in non-test files)

- **Filenames**: `*mock*`, `*stub*`, `*fake*`, `*dummy*`
- **Code**: `mock_data`/`mockData` (+ stub/dummy/fake variants), `MOCK_`/`STUB_`/
  `DUMMY_`/`FAKE_`, `unittest.mock` / `jest.mock` / `jest.fn`, `"TODO: replace
  with real"`, `placeholder`, `hardcoded`
- **Hardcoded test values**: fake API keys/tokens, lorem ipsum, static UUIDs as
  ids, far-past/future dates, `test@example.com`, `555-` phone numbers
- **Integrations**: localhost/mock URLs in prod config, in-memory/SQLite
  fallbacks in prod mode, conditional mock returns, secrets hardcoded instead of
  env vars

```bash
grep -r "mock\|stub\|fake\|dummy" .env* config/ \
  --include="*.json" --include="*.yaml" --include="*.toml" 2>/dev/null
# exclude .env.example and .env.test from violations
```

## Report (by severity)

- **Critical (must fix)**: mock data returned to users, hardcoded credentials,
  fake external responses.
- **Warning (review)**: suspicious names, placeholder comments, conditional mock
  logic.
- **Info (likely OK)**: test utilities, dev-only fallbacks with proper env guards.

For each finding: implement the real integration, add an environment guard, or —
if intentional — a comment explaining why (e.g. `# Not a mock: actual default`).

Watch for false positives: a flagged file may just be a mis-excluded test, or a
shared util used by both prod and test (split it).

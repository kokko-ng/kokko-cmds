# Verify No Mocks in Production Code

Scan codebase to ensure production code does not rely on mock, stub, or dummy data. Verify that all features use real integrations.

## When to Use

- Before deploying to production
- After implementing new features
- During code reviews
- To verify feature completeness

## Arguments

Usage: `/quality/verify-no-mocks [target]`

- `target` - Directory to scan (default: current project root)

If `$ARGUMENTS` is provided, use it as the target path.

## Steps

### 1. Scan for Mock Patterns

Search for common mock/stub indicators in non-test files:

**File name patterns to flag:**
- `*mock*`, `*stub*`, `*fake*`, `*dummy*`
- Exclude: `test/`, `tests/`, `__tests__/`, `spec/`, `*_test.*`, `*.test.*`, `*.spec.*`

**Code patterns to flag:**

```
# Python
mock_data, stub_data, dummy_data, fake_data
MOCK_, STUB_, DUMMY_, FAKE_
"TODO: replace with real"
"placeholder", "hardcoded"
unittest.mock (outside test files)

# JavaScript/TypeScript
mockData, stubData, dummyData, fakeData
MOCK_, STUB_, DUMMY_, FAKE_
// TODO: replace with real
"placeholder", "hardcoded"
jest.mock, jest.fn (outside test files)
```

### 2. Check for Hardcoded Test Values

Look for suspicious patterns:

- Hardcoded API keys or tokens (even fake ones)
- Lorem ipsum or sample text in production code
- Static UUIDs used as identifiers
- Hardcoded dates far in past/future
- Email addresses like `test@example.com` in non-test code
- Phone numbers like `555-` patterns

### 3. Verify External Integrations

For each external service the project uses:

**API Clients:**
- Check if real API endpoints are configured
- Verify no localhost/mock URLs in production configs
- Ensure environment variables are used (not hardcoded values)

**Databases:**
- Check connection strings point to real databases
- Verify no in-memory or SQLite fallbacks in production mode

**Third-party Services:**
- Ensure SDK clients are properly initialized
- Check for conditional mock returns

### 4. Review Environment Configuration

Check configuration files:

```bash
# Look for mock indicators in config
grep -r "mock\|stub\|fake\|dummy" .env* config/ --include="*.json" --include="*.yaml" --include="*.toml" 2>/dev/null
```

Exclude `.env.example` and `.env.test` from violations.

### 5. Generate Report

Categorize findings by severity:

**Critical (must fix):**
- Mock data returned to users
- Hardcoded credentials
- Fake external service responses

**Warning (review needed):**
- Suspicious variable names
- Placeholder comments
- Conditional mock logic

**Info (likely acceptable):**
- Test utilities
- Development-only fallbacks with proper guards

### 6. Fix or Document Exceptions

For each finding:
1. If mock data: implement real integration
2. If development fallback: ensure proper environment guards
3. If intentional: add comment explaining why (e.g., `# Not a mock: this is the actual default value`)

## Error Handling

| Issue | Cause | Resolution |
|-------|-------|------------|
| False positive in test file | Test not properly excluded | Verify file path matches test patterns |
| Mock in shared utility | Utility used by both prod and test | Split into separate modules |
| Environment-gated mock | Dev fallback leaking to prod | Add proper NODE_ENV/environment checks |

## Success Criteria

- No mock/stub/dummy data in production code paths
- All external integrations use real endpoints
- Environment variables used for all secrets/endpoints
- Any exceptions are documented with justification
- Report shows zero critical findings

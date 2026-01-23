---
disable-model-invocation: true
---

# Verify Test Specification

Validate that a spec.md file is complete, well-formed, and matches the actual codebase.

## When to Use

- After generating a spec.md with `/analysis/spec`
- Before starting E2E test development
- During spec review

## Arguments

Usage: `/analysis/verify-spec [spec-file]`

- `spec-file` - Path to the spec file (default: ./spec.md)

If `$ARGUMENTS` is provided, use it as the spec file path.

## Steps

### 1. Load and Parse the Spec File

Read the spec.md file and verify it exists. If not found, report an error.

### 2. Validate Structure

Check that the spec file contains required sections:

**Required sections:**

- [ ] `# Application Test Specification` or similar title
- [ ] `## Overview` section with application description
- [ ] `## User Stories` section
- [ ] At least one `### Feature:` subsection

**For each user story, verify:**

- [ ] User story ID format (US-XXX)
- [ ] "As a" statement (user type)
- [ ] "I want to" statement (action)
- [ ] "So that" statement (benefit)
- [ ] Acceptance Criteria section with checkboxes
- [ ] Test Scenarios section
- [ ] "Testable with Playwright" indicator

### 3. Check for Completeness

Identify issues:

```text
STRUCTURE ISSUES:
- Missing overview section
- User story US-005 missing acceptance criteria
- Feature "Authentication" has no test scenarios

FORMATTING ISSUES:
- US-003 missing "So that" statement
- Inconsistent checkbox format in US-007
```

### 4. Cross-Reference with Codebase

For each documented feature, verify it exists in the codebase:

**For web applications:**

- Routes mentioned exist in router configuration
- Components referenced are implemented
- API endpoints documented are defined
- data-testid attributes mentioned exist in templates

**For CLI applications:**

- Commands documented exist in command definitions
- Options and flags are implemented

Report any mismatches:

```text
CODEBASE MISMATCHES:
- US-002 references /admin route but route not found
- US-008 mentions "Delete Account" button but no such element exists
- Feature "Reports" documented but no reports module found
```

### 5. Check for Missing Features

Scan the codebase for features NOT documented in the spec:

```text
UNDOCUMENTED FEATURES:
- Route /settings exists but not in spec
- Component UserProfile has testable interactions not covered
- API endpoint POST /api/export not documented
```

### 6. Validate Test Scenarios

For each test scenario, check:

- Happy path scenario exists
- At least one error/edge case documented
- Prerequisites are clear
- Expected outcomes are specific and measurable

```text
SCENARIO ISSUES:
- US-001: Missing error case scenario
- US-004: Expected outcome is vague ("should work correctly")
- US-006: No prerequisites documented
```

### 7. Generate Verification Report

Output a summary report:

```markdown
# Spec Verification Report

## Summary
- Total User Stories: 15
- Valid: 12
- Issues Found: 8

## Structure Validation
[x] Title present
[x] Overview section present
[x] User Stories section present
[ ] All user stories have required fields (3 issues)

## Codebase Alignment
- Features documented: 15
- Features verified in code: 13
- Missing from code: 2
- Undocumented in spec: 3

## Issues by Severity

### Critical (blocks testing)
1. US-002: Route /admin not found in codebase

### Warning (should fix)
1. US-003: Missing "So that" statement
2. US-007: Vague acceptance criteria

### Info (optional improvements)
1. Route /settings not documented
2. US-010: Could add more edge cases

## Recommendations
1. Remove US-002 or implement /admin route
2. Add missing user type to US-003
3. Document /settings feature
```

## Output Format

The verification produces:

- Console summary of pass/fail status
- Detailed report of all issues found
- Actionable recommendations

## Error Handling

| Issue | Cause | Resolution |
| ----- | ----- | ---------- |
| Spec file not found | Wrong path | Run `/analysis/spec` first |
| Cannot parse spec | Malformed markdown | Check markdown syntax |
| Cannot analyze codebase | Missing files | Verify project structure |

## Success Criteria

- All required sections present and valid
- Every user story has complete fields
- All documented features exist in codebase
- No critical mismatches between spec and code
- Verification report generated with actionable items

---
description: Validate a spec.md for structure, completeness, and alignment with the codebase.
argument-hint: '[spec-file]'
allowed-tools: Read, Grep, Glob, Bash
---

# Verify Test Specification

Validate the spec file `$1` (default: `./spec.md`). Report an error if it is
missing or unparseable.

## Checks

1. **Structure**: title, `## Overview`, `## User Stories`, at least one `### Feature:`.
   Each story has a US-XXX id, "As a / I want to / So that", acceptance-criteria
   checkboxes, test scenarios, and a "Deterministic tests" indicator
   (API / Component / E2E in any combination, or None (visual only)). Treat the
   legacy "Testable with Playwright" indicator as a Warning to migrate, not a
   failure.
2. **Codebase alignment**: every documented route, component, API endpoint, and
   data-testid (or CLI command/flag) actually exists. Flag mismatches.
3. **Missing coverage**: scan the codebase for testable features absent from the spec.
4. **Scenarios**: each story has a happy path, at least one error/edge case,
   clear prerequisites, and specific measurable outcomes.

## Verification Report

```markdown
# Spec Verification Report

## Summary
- Total User Stories: N | Valid: N | Issues: N

## Structure Validation
[x] Title / [x] Overview / [x] User Stories / [ ] All stories complete (N issues)

## Codebase Alignment
- Documented: N | Verified in code: N | Missing from code: N | Undocumented in spec: N

## Issues by Severity
### Critical (blocks testing)
1. US-002: Route /admin not found in codebase
### Warning (should fix)
1. US-003: Missing "So that" statement
### Info (optional)
1. Route /settings not documented

## Recommendations
1. [Actionable item]
```

If the spec file is missing, suggest running `/spec` first.

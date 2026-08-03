---
description: Generate a test specification documenting all testable user stories.
argument-hint: '[target] [--output filename]'
allowed-tools: Read, Write, Glob, Grep
---

# Create Test Specification

Analyze `$1` (default: current project) and write a spec file (default:
`spec.md`, override with `--output`) documenting testable user stories.

## Analyze

Identify user-facing features. Web: routes/pages, forms, navigation,
auth, CRUD, API endpoints. CLI: commands/subcommands, I/O behavior,
config options.

## Rules

- **Document existing features only.** Verify against route definitions,
  component implementations, API endpoints, and rendered UI — no speculative features.
- **Focus on deterministically testable behavior**: API requests/responses,
  auth rules, CRUD and persistence, form/input validation, state transitions,
  upload/download round-trips, component rendering logic. Mark stories whose
  outcome can only be judged visually (layout, styling) as visual-only.
- Organize by priority: critical path (auth, core) → primary → secondary → edge/error cases.
- Map stories to concrete hooks tests can target: routes, endpoints, element
  roles/labels/test ids, prerequisites, and measurable outcomes (status codes,
  response fields, visible text).

## Template

```markdown
# Application Test Specification

## Overview
Brief description of the application and its purpose.

## User Stories

### Feature: [Feature Name]

#### US-001: [User Story Title]
**As a** [user type]
**I want to** [action]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

**Test Scenarios:**
1. Happy path: [description]
2. Edge case: [description]
3. Error case: [description]

**Deterministic tests:** API / Component / API + Component / None (visual only)
```

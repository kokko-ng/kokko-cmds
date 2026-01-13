# Master Prompt

Follow this prompt for the application under test. You must ensure **every User Story in `spec.md` works exactly as expected**. If anything is incomplete or broken, implement fixes until it is correct.

## Environment

- Run the app locally.
- Use cloud resources **only for tests**.
- **Do not** update any `spec.md` with validation results.
- **Do not** add test outputs, validation notes, pass/fail statuses, screenshots, or any other results to **any** `spec.md`.

---

## Cloud Constraints (if applicable)

- Use the platform CLI for all operations (e.g., `az`, `gcloud`, `aws`).
- Restrict all provisioning/changes to the designated test scope (e.g., a single resource group/project/account).
- Apply consistent tagging/labels to all test resources.
- Create resources **only if they do not already exist** in the allowed test scope.
- Provision the **cheapest viable SKUs/tiers** required to run tests.
- Do not create or modify resources outside the allowed scope.

---

## Definitions

| Term | Meaning |
|---|---|
| `user_stories` | All User Stories in `spec.md` |
| `compush_cmd` | `/compush` (or the project’s equivalent deploy/push command) |

---

## Primary Goal

Validate the application end-to-end against **all User Stories** in `spec.md`. Most implementation is complete—resolve remaining issues until the product is fully functional.

> **You must not stop until EVERYTHING in `spec.md` is implemented and validated.**

---

## Required Work Cycle (for every feature in `spec.md`)

For **each** User Story / feature:

1. Validate using the project’s E2E test tooling (e.g., Playwright)
2. If failing: debug the issue
3. Implement fixes/features as needed
4. Run `compush_cmd` after code changes
5. Re-test end-to-end
6. Repeat until the feature passes end-to-end
7. Move to the next feature

---

## Development Workflow

### After ANY code modification (mandatory)

1. Run `compush_cmd` immediately
2. Confirm deployment/build succeeds
3. Re-test affected functionality
4. Continue only after stability is verified

### Debugging rule

Fail → Debug → Fix → `compush_cmd` → Re-test → Repeat until fully resolved.

---

## Validation & Testing

### Scope

Validate **ALL** User Stories in `spec.md`, including:
- Functional correctness
- Data consistency
- State transitions
- Error handling
- End-to-end flow completion (start → expected result)

### Page/UI requirements

- No hardcoded placeholders: all functionality must be real and data-driven
- Manual routes must be reachable via the UI (where applicable)
- Document new components in the project’s specs/docs area (behavior + state details)
- Map UI elements to the relevant User Stories

---

## Specification Compliance

- `spec.md` is the single source of truth.
- If a spec is unclear, rewrite it into a more explicit, structured, agent-friendly form **without changing intent**.
- **Do not** record validation activity or results in `spec.md` (no checklists, pass/fail notes, logs, screenshots, or summaries).

---

## Completion Criteria (definition of “done”)

Work is **not complete** until:
- ✅ Every feature in `spec.md` is implemented
- ✅ Every feature passes end-to-end validation
- ✅ All bugs/blockers are fixed
- ✅ The full app works end-to-end
- ✅ The system is integrated and stable

When all completion criteria are met, output exactly:
`<promise>COMPLETE</promise>`

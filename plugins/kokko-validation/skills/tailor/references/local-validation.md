<!--
TAILORING NOTES (for the /tailor skill -- delete this entire comment in the tailored output)

Placeholders. Every {{...}} must be resolved. Sources, in order: user hints,
repo inspection, read-only `az cli`, then ask the user. Never invent values.

  APP_NAME                    Application name
  PROGRESS_FILE               Progress checklist path, e.g. prompts/local-validation-progress.md
  API_TEST_COMMAND            Runs the API/integration suite against the running backend (e.g. cd backend && pytest -q tests/api)
  FRONTEND_TEST_COMMAND       Runs the frontend unit/component suite (e.g. cd frontend && npx vitest run)
  E2E_TEST_COMMAND            Runs the Playwright E2E suite headlessly (e.g. cd frontend && npx playwright test)
  TEST_DIRS                   Space-separated test directories for the spec-coverage grep (e.g. backend/tests frontend/src frontend/e2e)
  BACKEND_DIR / FRONTEND_DIR  Repo-relative app directories (e.g. backend, frontend)
  BACKEND_FRAMEWORK / FRONTEND_FRAMEWORK
  BACKEND_START_COMMAND / FRONTEND_START_COMMAND
  BACKEND_URL / FRONTEND_URL  Local URLs including ports
  BACKEND_INSTALL_COMMANDS / FRONTEND_INSTALL_COMMANDS
  LOCAL_DB_TYPE / LOCAL_DB_DETAILS
  LOCAL_STORAGE_PATH          Local file-storage root (drop storage rows if the app stores no files)
  LOCAL_AUTH_DESCRIPTION      How local auth works: mechanism, token type, seeded users
  HEALTH_ENDPOINT             Unauthenticated health route, e.g. /api/health
  API_ENDPOINTS_TABLE         Real endpoint rows: | METHOD | path | auth? | purpose |
  TYPE_CHECK_COMMAND          Command(s) that must pass with zero errors
  ADDITIONAL_ENV_VARS         Other required backend env vars (drop the line if none)
  azure-ai block only:        RESOURCE_GROUP, AZURE_REGION, AI_ACCOUNT_NAME,
                              DEPLOYMENT_NAME, MODEL_NAME, TPM, API_ENDPOINT_BASE

Optional blocks. Delete the whole block -- plus every line elsewhere that
starts with the block name in brackets, e.g. "[azure-ai]" -- when it does not
apply. Strip the bracket tags from lines you keep.

  azure-ai      App calls a pre-provisioned Azure AI model. Delete if there is no AI integration.
  websocket     App uses WebSockets.
  registration  App has self-service user registration.

No {{...}} token, no [tag] marker, and none of these notes may remain in the
tailored output.
-->

# {{APP_NAME}} -- Local Validation & Testing Prompt

## Core Definitions

| ID             | Value                                        |
| -------------- | -------------------------------------------- |
| `user_stories` | All User Stories in `spec.md`                |
| `backend`      | {{BACKEND_FRAMEWORK}} on `{{BACKEND_URL}}`   |
| `frontend`     | {{FRONTEND_FRAMEWORK}} on `{{FRONTEND_URL}}` |
| `database`     | {{LOCAL_DB_TYPE}} (local)                    |
| `storage`      | Local filesystem (`{{LOCAL_STORAGE_PATH}}`)  |
| `api_tests`    | `{{API_TEST_COMMAND}}`                       |
| `ui_tests`     | `{{FRONTEND_TEST_COMMAND}}`                  |
| `e2e_tests`    | `{{E2E_TEST_COMMAND}}`                       |
| `progress`     | `{{PROGRESS_FILE}}`                          |

<!-- OPTIONAL: azure-ai -->

| ID               | Value                                                                                              |
| ---------------- | -------------------------------------------------------------------------------------------------- |
| `resource_group` | `{{RESOURCE_GROUP}}` ({{AZURE_REGION}}) -- **already provisioned**                                 |
| `ai_account`     | `{{AI_ACCOUNT_NAME}}` -- Azure AI Services account -- **already provisioned**                      |
| `deployment`     | `{{DEPLOYMENT_NAME}}` (model: {{MODEL_NAME}}, {{TPM}} TPM, GlobalStandard) -- **already deployed** |
| `api_endpoint`   | `{{API_ENDPOINT_BASE}}`                                                                            |

<!-- END OPTIONAL: azure-ai -->

---

## Deterministic Testing -- No Agent-Driven Browsing

Validation in this prompt is performed by deterministic, assertion-based
tests run from the shell -- pass/fail comes from test-runner exit codes and
assertion output, never from interpreting screenshots or driving a browser
by hand.

- **API/integration tests** (`{{API_TEST_COMMAND}}`): real HTTP requests
  against the locally running backend, asserting status codes, response
  shapes, field values, error messages, auth enforcement, and persistence.
- **Frontend unit/component tests** (`{{FRONTEND_TEST_COMMAND}}`): rendering
  logic, form validation, and state transitions asserted at the DOM level
  with the framework's standard testing tools.
- **End-to-end browser tests** (`{{E2E_TEST_COMMAND}}`): Playwright test
  specs (`@playwright/test`) committed to the repo and run headlessly with
  `npx playwright test` -- real user flows through the UI at
  `{{FRONTEND_URL}}`, verified with web-first assertions
  (`await expect(page.getByRole(...)).toBeVisible()` and friends) that
  auto-wait instead of sleeping. If Playwright is not installed, add it
  first (`npm i -D @playwright/test && npx playwright install chromium`).
- If a suite (or the frontend/E2E test setup) does not exist yet, creating
  it is part of this prompt's job -- use the stack's conventional tooling
  and keep it in the repo so later passes re-run it.
- Tests must be deterministic: they seed or reset their own data, poll/await
  conditions instead of sleeping fixed durations (in Playwright: web-first
  assertions and auto-waiting, never `waitForTimeout`), never depend on
  execution order, and produce the same result on every re-run.
- [azure-ai] Assertions on AI-backed endpoints target status codes and
  response structure, never exact model output.
- Browser automation lives ONLY inside those committed Playwright specs.
  Do NOT drive a browser yourself or judge outcomes visually: no ad-hoc
  playwright-cli sessions or one-off page-driving scripts, no Playwright
  MCP server or `mcp__playwright__*` / `browser_*` tools, no
  screenshot-based validation (Playwright's failure screenshots and traces
  are debugging artifacts, not pass evidence). Pixel-level appearance is
  out of scope here -- the aesthetics prompt covers it.

### Spec Coverage -- Every Story Maps to Tests

Tag every test with the literal story ID it validates -- in a describe or
test name (`describe('US-003 login', ...)`), or, where names cannot contain
hyphens (pytest), in the test's docstring or a marker. The ID must appear
verbatim (`US-003`) so the coverage check below can find it. Each story
gets its happy path plus every edge and error scenario listed in `spec.md`
as its own test. Check coverage mechanically -- every story ID in the spec
must appear in the suite:

```bash
comm -23 <(grep -Eoh 'US-[0-9]+' spec.md | sort -u) \
         <(grep -Eroh 'US-[0-9]+' {{TEST_DIRS}} | sort -u)
```

Any ID this prints is an uncovered story -- write its tests before calling
the suite complete.

---

## Primary Goal

Work autonomously to validate the application end-to-end against every feature
and requirement in `spec.md`, running entirely locally ({{BACKEND_FRAMEWORK}}
backend + {{FRONTEND_FRAMEWORK}} frontend). Build out the deterministic test
suites described above, implement what is missing, fix what is broken, and
re-run the tests until everything passes.

`spec.md` is the authoritative source of scope. If a requirement is ambiguous,
refine it to be explicit and testable while preserving its intent.

Completion is defined solely by the checklist in the "Completion, Blockers &
Stopping" section at the end of this prompt -- nothing else.

---

## Progress Tracking -- Read First, Update Always

`{{PROGRESS_FILE}}` is the single source of truth for progress. Conversation
memory does not survive context compaction or fresh-context passes
(multipass); this file does.

- **On start:** if the file exists, read it and resume from the first item not
  marked `passed`. If it does not exist, create it with one line per user
  story in `spec.md` (plus a few setup lines), all `pending`.
- **Line format:** `US-003 | pending / in-progress / passed / blocked | short note`
  -- for `blocked`, the note states exactly what is missing and what was tried.
- **Update immediately** whenever an item changes state -- never in batches,
  never only at the end.
- Append one line to a `## Session log` section at the bottom of the file at
  the start of each pass.

---

## Architecture & Environment

### Local Stack

| Component           | Details                                                                                                |
| ------------------- | ------------------------------------------------------------------------------------------------------ |
| Backend             | {{BACKEND_FRAMEWORK}} in `{{BACKEND_DIR}}/` -- `{{BACKEND_START_COMMAND}}` -- `{{BACKEND_URL}}`        |
| Frontend            | {{FRONTEND_FRAMEWORK}} in `{{FRONTEND_DIR}}/` -- `{{FRONTEND_START_COMMAND}}` -- `{{FRONTEND_URL}}`    |
| Database            | {{LOCAL_DB_TYPE}} -- {{LOCAL_DB_DETAILS}}                                                              |
| File storage        | Local filesystem -- `{{LOCAL_STORAGE_PATH}}`                                                           |
| Dev proxy           | Frontend dev server proxies `/api` requests to the backend                                             |
| [azure-ai] AI model | `{{MODEL_NAME}}` via Azure AI Services in `{{RESOURCE_GROUP}}` ({{AZURE_REGION}})                      |

Both servers auto-reload on code changes; restart them only when a change
requires it (new dependency, config change).

### Dependencies

Backend:

```bash
{{BACKEND_INSTALL_COMMANDS}}
```

Frontend:

```bash
{{FRONTEND_INSTALL_COMMANDS}}
```

### Authentication

{{LOCAL_AUTH_DESCRIPTION}}

### Backend API Endpoints

| Method | Endpoint              | Auth Required | Purpose      |
| ------ | --------------------- | ------------- | ------------ |
| GET    | `{{HEALTH_ENDPOINT}}` | No            | Health check |
{{API_ENDPOINTS_TABLE}}

### Environment Variables

`{{BACKEND_DIR}}/.env` (gitignored -- never commit it, never print its values
into logs or files):

```text
{{ADDITIONAL_ENV_VARS}}
```

[azure-ai] Plus the Azure AI variables listed in the Azure AI section below.

### Type Checking

Backend and frontend MUST pass type checking with zero errors:

```bash
{{TYPE_CHECK_COMMAND}}
```

---

<!-- OPTIONAL: azure-ai -->

## Azure AI -- Pre-Provisioned, Read-Only

The `{{RESOURCE_GROUP}}` resource group ({{AZURE_REGION}}) and the Azure AI
resources in it are **already provisioned**. Verify connectivity and use them
as-is -- never create, recreate, or delete them.

| Resource          | Name                  | Details                                            |
| ----------------- | --------------------- | -------------------------------------------------- |
| Resource group    | `{{RESOURCE_GROUP}}`  | {{AZURE_REGION}}                                   |
| Azure AI Services | `{{AI_ACCOUNT_NAME}}` | OpenAI-compatible endpoint `{{API_ENDPOINT_BASE}}` |
| Model deployment  | `{{DEPLOYMENT_NAME}}` | {{MODEL_NAME}}, {{TPM}} TPM, GlobalStandard        |

Credentials live in `{{BACKEND_DIR}}/.env`, loaded automatically by the
backend config:

```text
AZURE_OPENAI_ENDPOINT={{API_ENDPOINT_BASE}}
AZURE_OPENAI_API_KEY=<key>
AZURE_OPENAI_DEPLOYMENT={{DEPLOYMENT_NAME}}
```

Verify deployment health, or retrieve the key if `.env` is missing:

```bash
az cognitiveservices account deployment show \
  --deployment-name {{DEPLOYMENT_NAME}} -n {{AI_ACCOUNT_NAME}} -g {{RESOURCE_GROUP}} \
  | jq -r '.properties.provisioningState'   # expected: "Succeeded"

az cognitiveservices account keys list -n {{AI_ACCOUNT_NAME}} -g {{RESOURCE_GROUP}} | jq -r '.key1'
```

Rules:

- `az cli` is for inspection and read-only operations in `{{RESOURCE_GROUP}}`
  ONLY. Every command targets `-g {{RESOURCE_GROUP}}` explicitly; no other
  resource group may be used, referenced, or created; never deploy application
  code to Azure -- the app runs locally.
- Key material goes into `{{BACKEND_DIR}}/.env` only -- never into logs,
  commits, or any other file.

Troubleshooting: on 401/403, re-check the key in `.env` against
`az cognitiveservices account keys list` (send it in the `api-key` header).
On a non-`Succeeded` deployment state, wait and re-check -- do not recreate.

<!-- END OPTIONAL: azure-ai -->

---

## Workflow

### Setup (once per session)

1. Install backend and frontend dependencies.
2. [azure-ai] Verify `{{BACKEND_DIR}}/.env` has the Azure AI credentials
   (retrieve them per the Azure AI section if missing).
3. Start the backend, then the frontend dev server.
4. Confirm `{{FRONTEND_URL}}` serves the app shell and
   `{{FRONTEND_URL}}{{HEALTH_ENDPOINT}}` reaches the backend through the dev
   proxy (curl, expect 200).
5. Confirm auth works once with a curl login round-trip: valid credentials
   return a token/session, and an authenticated request succeeds with it.
6. [azure-ai] Exercise one AI endpoint via curl to confirm model connectivity.
7. Confirm all three test suites run at all (`{{API_TEST_COMMAND}}`,
   `{{FRONTEND_TEST_COMMAND}}`, `{{E2E_TEST_COMMAND}}`) -- failing tests are
   fine at this stage, a broken or missing harness is not: create or repair
   it now (including `npx playwright install chromium` if needed).
8. Read or create `{{PROGRESS_FILE}}`, then start the work cycle.

### Work Cycle (per user story)

1. Mark the story `in-progress` in `{{PROGRESS_FILE}}`.
2. Write or extend its deterministic tests first: happy path plus every edge
   and error scenario from `spec.md`, tagged with the story ID.
3. Run the story's tests. If they fail: debug, fix the application code (or
   the test, only when the test itself contradicts `spec.md`), let the
   servers reload, re-run.
4. When the story's tests pass -- API behavior, persistence, error handling,
   edge cases, and UI flows where the story has them -- run the FULL suites
   (`{{API_TEST_COMMAND}}`, `{{FRONTEND_TEST_COMMAND}}`,
   `{{E2E_TEST_COMMAND}}`) to catch regressions, then
   `{{TYPE_CHECK_COMMAND}}`, then mark it `passed` with a short note.
5. Move to the next story. Repeat until every story is `passed` or `blocked`.

### Debugging

- Backend errors: backend terminal logs. Frontend errors: test-runner output
  and dev-server logs. E2E failures: Playwright's failure output, traces,
  and failure screenshots (debugging artifacts, not pass evidence).
- [azure-ai] AI errors: check `.env` credentials first, then deployment health
  via `az cognitiveservices account deployment show`.
- **Stuck rule:** after 3 failed fix attempts on the same issue, record what
  you tried in `{{PROGRESS_FILE}}`, mark the item `blocked`, move on to the
  next story, and revisit blocked items at the end.

---

## Validation Standards

Every user story is validated by deterministic tests that assert, per
`spec.md`:

- The API responds correctly: expected status codes, response shape, and
  field values on the happy path; the specified error status and message for
  invalid input
- Data persists: written through the API, then read back in a separate
  request (and, where sessions matter, from a fresh authenticated session)
- Errors are handled appropriately and edge cases behave as specified --
  each edge/error scenario in `spec.md` is its own test
- Frontend logic is covered where the story has UI behavior: rendering,
  form validation, and state transitions asserted in component tests
- The story's user-visible flow passes end-to-end in a Playwright spec:
  navigate, interact, and assert the rendered result (content, URL/state,
  error messages) with web-first assertions
- UI-critical stories run their E2E specs under both Playwright viewport
  projects: desktop (1280px) and mobile (375px)

Authentication (suite-level, not per-story):

- Valid credentials authenticate; invalid credentials are rejected with the
  specified error
- Protected endpoints reject unauthenticated requests and succeed when
  authenticated
- Logout (or session expiry) clears access: subsequent protected requests fail
- [registration] Registration creates an account that can immediately log in

[websocket] WebSocket features: a scripted test client connects with auth
and asserts the expected messages stream back.

---

## Completion, Blockers & Stopping

**Definition of done -- every box checked:**

- [ ] Every user story in `spec.md` is implemented and marked `passed` in
      `{{PROGRESS_FILE}}`, backed by deterministic tests tagged with its ID
      that cover the happy path and every spec edge/error scenario
- [ ] The spec-coverage check prints no uncovered story IDs
- [ ] `{{API_TEST_COMMAND}}` passes with zero failures
- [ ] `{{FRONTEND_TEST_COMMAND}}` passes with zero failures
- [ ] `{{E2E_TEST_COMMAND}}` passes with zero failures, including the
      desktop (1280px) and mobile (375px) viewport projects
- [ ] Tests prove authentication protects all sensitive endpoints
- [ ] Tests prove data persistence and file handling work correctly
- [ ] [azure-ai] AI integration works end-to-end through the app, asserted
      on status and response structure
- [ ] `{{TYPE_CHECK_COMMAND}}` passes with zero errors
- [ ] `{{PROGRESS_FILE}}` is up to date with no `pending` or `in-progress` items

Work autonomously and persistently toward this checklist. Do not stop because
the task list is large or context is running low -- context is compacted
automatically, and `{{PROGRESS_FILE}}` carries state across passes.

**The only valid reasons to mark an item `blocked` instead of finishing it:**

- Credentials, permissions, or external resources you cannot obtain or create
- A decision that belongs to a human: spending money, deleting data, changing scope
- A contradiction in `spec.md` that cannot be resolved conservatively
- The stuck rule (3 failed fix attempts) fired

Stop only when every item is `passed`, or the only remaining items are
`blocked`. Then report: what passed, and every blocker from
`{{PROGRESS_FILE}}` with what was tried. Never claim success for anything not
actually validated.

<!--
TAILORING NOTES (for the /tailor skill -- delete this entire comment in the tailored output)

Placeholders. Every {{...}} must be resolved. Sources, in order: user hints,
repo inspection, read-only `az cli`, then ask the user. Never invent values.

  APP_NAME                    Application name
  PROGRESS_FILE               Progress checklist path, e.g. prompts/local-validation-progress.md
  BROWSER_TOOL                Browser automation tool actually available (e.g. playwright-cli, Playwright MCP)
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
  theming       App has more than one theme.

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
| `browser_tool` | {{BROWSER_TOOL}}                             |
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

## Primary Goal

Work autonomously to validate the application end-to-end against every feature
and requirement in `spec.md`, running entirely locally ({{BACKEND_FRAMEWORK}}
backend + {{FRONTEND_FRAMEWORK}} frontend). Implement what is missing, fix what
is broken, and re-validate until everything passes.

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
4. Confirm `{{FRONTEND_URL}}` loads and `{{FRONTEND_URL}}{{HEALTH_ENDPOINT}}`
   reaches the backend through the dev proxy.
5. Log in once to confirm auth works.
6. [azure-ai] Exercise one AI feature to confirm model connectivity.
7. Read or create `{{PROGRESS_FILE}}`, then start the work cycle.

### Work Cycle (per user story)

1. Mark the story `in-progress` in `{{PROGRESS_FILE}}`.
2. Validate it against the local app with {{BROWSER_TOOL}}.
3. If it fails: debug, fix the code, let the servers reload, re-validate.
4. When it fully passes -- UI, API, persistence, error handling, edge cases --
   run `{{TYPE_CHECK_COMMAND}}`, then mark it `passed` with a short note.
5. Move to the next story. Repeat until every story is `passed` or `blocked`.

### Debugging

- Backend errors: backend terminal logs. Frontend errors: browser console and
  dev-server output.
- [azure-ai] AI errors: check `.env` credentials first, then deployment health
  via `az cognitiveservices account deployment show`.
- **Stuck rule:** after 3 failed fix attempts on the same issue, record what
  you tried in `{{PROGRESS_FILE}}`, mark the item `blocked`, move on to the
  next story, and revisit blocked items at the end.

---

## Validation Standards

Validate with {{BROWSER_TOOL}} against `{{FRONTEND_URL}}` -- real browser
flows, not just curl.

Authentication:

- Valid credentials log in; invalid credentials are rejected with a visible error
- Protected endpoints reject unauthenticated requests and succeed when authenticated
- Logout clears auth state and returns to the login page
- [registration] Registration creates an account that can immediately log in

Every feature (per `spec.md`):

- The UI renders correctly
- The backend API responds correctly
- Data persists across reloads
- Errors are handled appropriately
- Edge cases behave sensibly

UI & responsiveness:

- Navigation and layout render correctly; interactive elements respond
- Layout adapts to mobile (375px) and desktop (1280px) viewports
- [theming] Each theme renders without bleed from another theme (no hard-coded
  colors, no white flashes on dark theme)
- [websocket] WebSocket features connect and stream correctly

---

## Completion, Blockers & Stopping

**Definition of done -- every box checked:**

- [ ] Every user story in `spec.md` is implemented and marked `passed` in
      `{{PROGRESS_FILE}}` after {{BROWSER_TOOL}} validation
- [ ] Authentication protects all sensitive endpoints
- [ ] Data persistence and file handling work correctly
- [ ] [azure-ai] AI integration works end-to-end through the app
- [ ] UI renders properly at desktop and mobile widths
- [ ] [theming] Every theme renders correctly at both widths
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

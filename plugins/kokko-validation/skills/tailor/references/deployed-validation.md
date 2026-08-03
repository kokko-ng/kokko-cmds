<!--
TAILORING NOTES (for the /tailor skill -- delete this entire comment in the tailored output)

Placeholders. Every {{...}} must be resolved. Sources, in order: user hints,
repo inspection, read-only `az cli`, then ask the user. Never invent values.

  APP_NAME                     Application name
  PROGRESS_FILE                Progress checklist path, e.g. prompts/deployed-validation-progress.md
  API_TEST_COMMAND             Runs the deterministic API suite; must honor the API_BASE_URL env var (e.g. cd backend && pytest -q tests/api)
  TEST_DIRS                    Space-separated test directories for the spec-coverage grep (e.g. backend/tests)
  RESOURCE_GROUP / AZURE_REGION  Fill region from `az group show --name <rg> --query location`
  BACKEND_APP_NAME / FRONTEND_APP_NAME   Container App names
  BACKEND_FRAMEWORK / FRONTEND_FRAMEWORK
  AZURE_DB_TYPE / AZURE_STORAGE_TYPE
  DEPLOYED_AUTH_TYPE           Auth mechanism protecting the deployed app
  HEALTH_ENDPOINT              Unauthenticated health route, e.g. /api/health
  custom-credentials variant:  PROTECTED_ROUTES (space-separated route list for the 401 loop)
  entra-id variant:            ENTRA_TEST_ACCOUNT_SOURCE (where automatable test credentials come from)
  azure-ai block only:         AI_ACCOUNT_NAME, DEPLOYMENT_NAME, MODEL_NAME, TPM, API_ENDPOINT

Optional blocks. Delete the whole block -- plus every line elsewhere that
starts with the block name in brackets, e.g. "[azure-ai]" -- when it does not
apply. Strip the bracket tags from lines you keep.

  azure-ai      App calls an Azure AI model. Delete if there is no AI integration.
  websocket     App uses WebSockets.

Auth variants. The two "AUTH VARIANT" blocks are alternatives: keep exactly
one (whichever matches the deployed auth), delete the other.

No {{...}} token, no [tag] marker, and none of these notes may remain in the
tailored output.
-->

# {{APP_NAME}} -- Deployed Validation & Testing Prompt

## Core Definitions

| ID               | Value                                            |
| ---------------- | ------------------------------------------------ |
| `user_stories`   | All User Stories in `spec.md`                    |
| `resource_group` | `{{RESOURCE_GROUP}}` ({{AZURE_REGION}})          |
| `compute`        | Azure Container Apps (backend + frontend)        |
| `backend`        | {{BACKEND_FRAMEWORK}} (`{{BACKEND_APP_NAME}}`)   |
| `frontend`       | {{FRONTEND_FRAMEWORK}} (`{{FRONTEND_APP_NAME}}`) |
| `database`       | {{AZURE_DB_TYPE}}                                |
| `storage`        | {{AZURE_STORAGE_TYPE}}                           |
| `auth`           | {{DEPLOYED_AUTH_TYPE}}                           |
| `api_tests`      | `{{API_TEST_COMMAND}}`                           |
| `progress`       | `{{PROGRESS_FILE}}`                              |

<!-- OPTIONAL: azure-ai -->

| ID             | Value                                                                      |
| -------------- | -------------------------------------------------------------------------- |
| `ai_account`   | `{{AI_ACCOUNT_NAME}}` -- Azure AI Services account                         |
| `deployment`   | `{{DEPLOYMENT_NAME}}` (model: {{MODEL_NAME}}, {{TPM}} TPM, GlobalStandard) |
| `api_endpoint` | `{{API_ENDPOINT}}`                                                         |

<!-- END OPTIONAL: azure-ai -->

---

## Deterministic Testing -- No Agent-Driven Browsing

Validation runs through deterministic, assertion-based tests executed from
the shell -- pass/fail comes from test-runner exit codes and curl
assertions, never from interpreting screenshots or driving a browser by
hand.

- **API/integration tests** (`{{API_TEST_COMMAND}}`): the suite reads its
  target origin from the `API_BASE_URL` environment variable. Point it at
  the deployed frontend origin so every request also exercises the nginx
  `/api` proxy:

  ```bash
  export API_BASE_URL="https://$FRONTEND_FQDN"
  {{API_TEST_COMMAND}}
  ```

- **Frontend smoke checks** are curl assertions: the frontend origin returns
  200 and serves the app shell (expected title/root element in the HTML),
  and its static assets resolve.
- If no such suite exists yet, creating it is part of this prompt's job --
  build it in the repo and commit it (tests deploy nothing, so they need no
  pipeline run) so later passes re-run it.
- Tests must be deterministic: they create and clean up their own data
  (this is a live deployed database), poll/await conditions instead of
  sleeping fixed durations, never depend on execution order, and produce
  the same result on every re-run.
- [azure-ai] Assertions on AI-backed endpoints target status codes and
  response structure, never exact model output.
- Do NOT drive a browser or judge outcomes visually: no ad-hoc
  playwright-cli sessions, no Playwright MCP server or `mcp__playwright__*` /
  `browser_*` tools, no screenshot-based validation. Visual appearance and
  responsive layout are out of scope here -- the aesthetics prompt covers
  them.

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

Work autonomously to validate the DEPLOYED application end-to-end against
every User Story in `spec.md`. The application is already deployed in the
`{{RESOURCE_GROUP}}` resource group; all validation runs against the deployed
URLs, and all fixes reach it through the GitHub Actions pipeline.

`spec.md` is the authoritative source of scope. Completion is defined solely
by the checklist in the "Completion, Blockers & Stopping" section at the end
of this prompt -- nothing else.

---

## Progress Tracking -- Read First, Update Always

`{{PROGRESS_FILE}}` is the single source of truth for progress. Conversation
memory does not survive context compaction or fresh-context passes
(multipass); this file does.

- **On start:** if the file exists, read it and resume from the first item not
  marked `passed`. If it does not exist, create it with one line per user
  story in `spec.md` (plus discovery/auth setup lines), all `pending`.
- **Line format:** `US-003 | pending / in-progress / passed / blocked | short note`
  -- for `blocked`, the note states exactly what is missing and what was tried.
- **Update immediately** whenever an item changes state -- never in batches,
  never only at the end.
- Append one line to a `## Session log` section at the bottom of the file at
  the start of each pass.

---

## Deployment Architecture

All resources live in `{{RESOURCE_GROUP}}` ({{AZURE_REGION}}) and are
**already deployed** -- verify and use them; never recreate them.

| Resource                   | Purpose                                          |
| -------------------------- | ------------------------------------------------ |
| Container Apps Environment | Container runtime for backend + frontend         |
| Backend Container App      | {{BACKEND_FRAMEWORK}} (`{{BACKEND_APP_NAME}}`)   |
| Frontend Container App     | {{FRONTEND_FRAMEWORK}} (`{{FRONTEND_APP_NAME}}`) |
| {{AZURE_DB_TYPE}}          | Application database                             |
| {{AZURE_STORAGE_TYPE}}     | Application file storage                         |
| Azure Container Registry   | Container image storage                          |
| [azure-ai] Azure AI Services | `{{AI_ACCOUNT_NAME}}` with `{{DEPLOYMENT_NAME}}` ({{TPM}} TPM) |

```text
[Users / Browser] -- {{DEPLOYED_AUTH_TYPE}}
        |
[Frontend Container App: {{FRONTEND_FRAMEWORK}} + nginx]
        |  REST [websocket] + WebSocket
[Backend Container App: {{BACKEND_FRAMEWORK}}]
        |
[{{AZURE_DB_TYPE}}]  [{{AZURE_STORAGE_TYPE}}]  [azure-ai: {{DEPLOYMENT_NAME}}]
```

### Discovery

```bash
az resource list --resource-group {{RESOURCE_GROUP}} --output table
az containerapp list --resource-group {{RESOURCE_GROUP}} --output table

BACKEND_FQDN=$(az containerapp show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv)
FRONTEND_FQDN=$(az containerapp show -g {{RESOURCE_GROUP}} -n {{FRONTEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv)
```

### Azure CLI Rules

- `az cli` is for inspection, discovery, and read-only operations ONLY: logs,
  configuration, resource status.
- Work exclusively inside `{{RESOURCE_GROUP}}`; it already exists -- never
  recreate it, never touch another resource group.
- Never deploy code with `az cli` (`az containerapp update --image` etc.) --
  ALL code changes deploy through GitHub Actions (see Deploying Changes).

---

## Authentication Validation -- Do This First

<!-- AUTH VARIANT: custom-credentials (app-managed login; credentials in Container App env vars) -->

Retrieve credentials from the deployed backend's environment (use the values
for testing only -- never write them into files, commits, or logs):

```bash
az containerapp show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} \
  --query "properties.template.containers[0].env" -o table
```

Validate before any feature testing:

1. Health endpoint is public:

   ```bash
   curl -s -o /dev/null -w "%{http_code}" "https://$BACKEND_FQDN{{HEALTH_ENDPOINT}}"
   # Expected: 200
   ```

2. Every protected route rejects unauthenticated requests:

   ```bash
   for ROUTE in {{PROTECTED_ROUTES}}; do
     STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$BACKEND_FQDN$ROUTE")
     echo "$ROUTE -> $STATUS (expected: 401)"
   done
   ```

3. Wrong credentials are rejected (401); valid credentials succeed.
4. The full login lifecycle passes deterministically through the frontend
   origin (so the nginx proxy is exercised too): the frontend serves the app
   shell (curl 200); login with wrong credentials returns the specified
   error; login with valid credentials returns a token/session; that
   credential makes protected API requests succeed; after logout (or token
   discard) the same requests fail again.

<!-- END AUTH VARIANT: custom-credentials -->

<!-- AUTH VARIANT: entra-id (Microsoft Entra ID / OIDC in front of the app) -->

The deployed app is protected by {{DEPLOYED_AUTH_TYPE}}. With Entra ID the
observable behavior differs from app-managed auth -- confirm the actual
behavior first, then validate against it:

- Browser requests to protected pages redirect (302) to
  `login.microsoftonline.com`; API requests without a valid token typically
  get 401 (or a 302, depending on the middleware).
- Automated sign-in needs an automatable test identity -- a dedicated test
  account with no MFA/conditional-access, or a client-credentials flow for
  API-only checks. Test credentials come from: {{ENTRA_TEST_ACCOUNT_SOURCE}}.
  Use them for testing only -- never write them into files, commits, or logs.

Validate before any feature testing:

1. `https://$BACKEND_FQDN{{HEALTH_ENDPOINT}}` returns 200 with no credentials.
2. An unauthenticated request to a protected page redirects to the Entra
   sign-in page; an unauthenticated API request is rejected.
3. A token acquired non-interactively for the test identity (client
   credentials, or whichever flow {{ENTRA_TEST_ACCOUNT_SOURCE}} supports)
   makes protected API requests succeed; the same requests without the
   token are rejected.
4. The interactive browser sign-in/sign-out experience itself is NOT
   validated here -- the redirect and token assertions above are its
   deterministic proxy.

If no automatable test identity exists, mark auth validation `blocked` in
`{{PROGRESS_FILE}}` (note why), and continue validating whatever is reachable
without it.

<!-- END AUTH VARIANT: entra-id -->

[websocket] After auth validation passes, run a WebSocket test: a scripted
client connects with auth and asserts messages stream back correctly.

---

## Deploying Changes -- GitHub Actions Only

ALL code deployments go through the GitHub Actions pipeline. Never bypass it
with direct `az` deployment commands; if the workflow fails, debug and push a
fix.

```bash
git add <explicit file paths>   # never `git add .` -- it sweeps in untracked files
git commit -m "descriptive commit message"
git push origin main

gh run list --limit 1
gh run watch
gh run view --log-failed
```

After each workflow success, verify deployment health before re-validating:

```bash
curl -s "https://$BACKEND_FQDN{{HEALTH_ENDPOINT}}" | jq .
az containerapp logs show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --tail 100
az containerapp revision list -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --output table
```

Deploy cycles are slow. When several fixes are independent and low-risk,
batch them into one push rather than deploying one-by-one -- but never batch
so much that a failure is hard to attribute.

---

## Work Cycle (per user story)

1. Mark the story `in-progress` in `{{PROGRESS_FILE}}`.
2. Write or extend its deterministic tests (story ID tagged verbatim;
   happy path plus every spec edge/error scenario), then run them against
   the DEPLOYED app (`API_BASE_URL` at the deployed frontend origin).
3. If they fail: debug (container logs, workflow logs, test output), fix the
   code locally, commit and push, wait for the workflow (`gh run watch`),
   verify deployment health.
4. Re-run the tests. When they fully pass -- API behavior, persistence,
   error handling, edge cases -- mark the story `passed` with a short note.
5. Move to the next story. Repeat until every story is `passed` or `blocked`.

**Stuck rule:** after 3 failed fix-and-deploy cycles on the same issue, record
what you tried in `{{PROGRESS_FILE}}`, mark the item `blocked`, move on, and
revisit blocked items at the end.

---

## Validation Standards

Run every story's tests against the deployed app through the frontend
origin (`API_BASE_URL="https://$FRONTEND_FQDN"`), so the nginx proxy path
is what gets validated. Tests assert, per `spec.md`:

- The API responds correctly: expected status codes, response shape, and
  field values on the happy path; the specified errors for invalid input
- Data persists in the deployed database: written in one request, read back
  in a separate request (and, where sessions matter, a fresh authenticated
  session)
- Errors are handled appropriately and edge cases behave as specified --
  each edge/error scenario in `spec.md` is its own test
- The frontend origin serves the app shell and its static assets (curl
  smoke assertions)
- Test data created against the live deployment is cleaned up by the tests
  themselves

---

## Completion, Blockers & Stopping

**Definition of done -- every box checked:**

- [ ] `{{HEALTH_ENDPOINT}}` returns 200 without authentication
- [ ] Authentication validation (section above) fully passes
- [ ] Every user story in `spec.md` is implemented in the deployed app and
      marked `passed` in `{{PROGRESS_FILE}}`, backed by deterministic tests
      run with `API_BASE_URL` at the deployed frontend origin
- [ ] The spec-coverage check prints no uncovered story IDs
- [ ] `{{API_TEST_COMMAND}}` passes with zero failures against the deployed app
- [ ] Database and storage connectivity are confirmed operational
- [ ] [azure-ai] The AI model endpoint is confirmed responsive through the app
- [ ] [websocket] WebSocket features work end-to-end with authentication
- [ ] The GitHub Actions pipeline is green on the latest commit
- [ ] `{{PROGRESS_FILE}}` is up to date with no `pending` or `in-progress` items

Work autonomously and persistently toward this checklist. Do not stop because
the task list is large or context is running low -- context is compacted
automatically, and `{{PROGRESS_FILE}}` carries state across passes.

**The only valid reasons to mark an item `blocked` instead of finishing it:**

- Credentials, permissions, or external resources you cannot obtain or create
  (e.g. no automatable test identity)
- A decision that belongs to a human: spending money, deleting production
  data, changing scope
- A contradiction in `spec.md` that cannot be resolved conservatively
- The stuck rule (3 failed fix-and-deploy cycles) fired

Stop only when every item is `passed`, or the only remaining items are
`blocked`. Then report: what passed, and every blocker from
`{{PROGRESS_FILE}}` with what was tried. Never claim success for anything not
actually validated.

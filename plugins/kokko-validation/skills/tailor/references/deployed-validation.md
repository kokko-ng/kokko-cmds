<!--
TAILORING NOTES (for the /tailor skill -- delete this entire comment in the tailored output)

Placeholders. Every {{...}} must be resolved. Sources, in order: user hints,
repo inspection, read-only `az cli`, then ask the user. Never invent values.

  APP_NAME                     Application name
  PROGRESS_FILE                Progress checklist path, e.g. prompts/deployed-validation-progress.md
  BROWSER_TOOL                 Browser automation tool actually available (e.g. playwright-cli, Playwright MCP)
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
| `browser_tool`   | {{BROWSER_TOOL}}                                 |
| `progress`       | `{{PROGRESS_FILE}}`                              |

<!-- OPTIONAL: azure-ai -->

| ID             | Value                                                                      |
| -------------- | -------------------------------------------------------------------------- |
| `ai_account`   | `{{AI_ACCOUNT_NAME}}` -- Azure AI Services account                         |
| `deployment`   | `{{DEPLOYMENT_NAME}}` (model: {{MODEL_NAME}}, {{TPM}} TPM, GlobalStandard) |
| `api_endpoint` | `{{API_ENDPOINT}}`                                                         |

<!-- END OPTIONAL: azure-ai -->

---

## Browser Automation -- Playwright CLI (NOT the MCP server)

`playwright-cli` in this prompt means the Playwright **command-line interface**,
driven from the shell -- NOT the Playwright MCP server or its `browser_*` tools.

- Drive the browser by writing and running Playwright scripts: ad-hoc Node
  scripts using the `playwright` package, or `.spec` files run with
  `npx playwright test`. Use `npx playwright screenshot <url> <out.png>` for
  one-off captures. Point every script at the deployed URLs.
- If Playwright is not installed, add it first
  (`npm i -D @playwright/test && npx playwright install chromium`).
- Do NOT use the Playwright MCP server or any `mcp__playwright__*` / `browser_*`
  tool for navigation, snapshots, or screenshots. All browser interaction goes
  through the Playwright CLI.

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
4. Frontend login UI via {{BROWSER_TOOL}}: the login page loads; invalid
   credentials show an error and no navigation; valid credentials land in the
   app; subsequent API requests succeed; logout returns to the login page, and
   protected pages then redirect back to login.

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
3. Via {{BROWSER_TOOL}}, the test account completes sign-in and lands in the
   app; subsequent API requests succeed.
4. Sign-out returns to the sign-in flow and protected pages are no longer
   reachable.

If no automatable test identity exists, mark auth validation `blocked` in
`{{PROGRESS_FILE}}` (note why), and continue validating whatever is reachable
without it.

<!-- END AUTH VARIANT: entra-id -->

[websocket] After login, exercise one WebSocket feature: the connection is
established with auth and messages stream back correctly.

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
2. Validate it against the DEPLOYED app with {{BROWSER_TOOL}}.
3. If it fails: debug (container logs, workflow logs, screenshots), fix the
   code locally, commit and push, wait for the workflow (`gh run watch`),
   verify deployment health.
4. Re-validate. When it fully passes -- UI, API, persistence, error handling,
   edge cases -- mark it `passed` with a short note.
5. Move to the next story. Repeat until every story is `passed` or `blocked`.

**Stuck rule:** after 3 failed fix-and-deploy cycles on the same issue, record
what you tried in `{{PROGRESS_FILE}}`, mark the item `blocked`, move on, and
revisit blocked items at the end.

---

## Validation Standards

Validate with {{BROWSER_TOOL}} against the deployed frontend URL -- real
browser flows, not just curl. For each feature in `spec.md`:

- The UI renders correctly
- The backend API responds correctly
- Data persists (survives reload and a new session)
- Errors are handled appropriately
- Edge cases behave sensibly
- UI renders properly at desktop (1280px) and mobile (375px) widths

---

## Completion, Blockers & Stopping

**Definition of done -- every box checked:**

- [ ] `{{HEALTH_ENDPOINT}}` returns 200 without authentication
- [ ] Authentication validation (section above) fully passes
- [ ] Every user story in `spec.md` is implemented in the deployed app and
      marked `passed` in `{{PROGRESS_FILE}}` after {{BROWSER_TOOL}} validation
- [ ] Database and storage connectivity are confirmed operational
- [ ] [azure-ai] The AI model endpoint is confirmed responsive through the app
- [ ] [websocket] WebSocket features work end-to-end with authentication
- [ ] UI renders properly at desktop and mobile widths
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

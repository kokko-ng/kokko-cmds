<!--
TAILORING NOTES (for the /tailor skill -- delete this entire comment in the tailored output)

Placeholders. Every {{...}} must be resolved. Sources, in order: user hints,
repo inspection, read-only `az cli`, then ask the user. Never invent values.

  APP_NAME                     Application name
  PROGRESS_FILE                Progress checklist path, e.g. prompts/azure-deploy-progress.md
  BROWSER_TOOL                 Browser automation tool actually available (e.g. playwright-cli, Playwright MCP)
  RESOURCE_GROUP / AZURE_REGION  Fill region from `az group show --name <rg> --query location`
  BACKEND_DIR / FRONTEND_DIR   Repo-relative app directories (e.g. backend, frontend)
  BACKEND_FRAMEWORK / FRONTEND_FRAMEWORK
  LOCAL_DB_TYPE / AZURE_DB_TYPE
  LOCAL_STORAGE_TYPE / AZURE_STORAGE_TYPE
  DEPLOYED_AUTH_TYPE           Auth mechanism for the deployed app
  HEALTH_ENDPOINT              Unauthenticated health route, e.g. /api/health
  ACR_NAME / CAE_NAME          Container registry / Container Apps environment names
  BACKEND_APP_NAME / FRONTEND_APP_NAME
  If Azure SQL chosen:         SQL_SERVER_NAME, SQL_DB_NAME
  If Blob Storage chosen:      STORAGE_ACCOUNT_NAME, CONTAINER_NAME
  azure-ai block only:         AI_ACCOUNT_NAME, DEPLOYMENT_NAME, MODEL_NAME, TPM, API_ENDPOINT

Optional blocks. Delete the whole block -- plus every line elsewhere that
starts with the block name in brackets, e.g. "[azure-ai]" -- when it does not
apply. Strip the bracket tags from lines you keep. In bash snippets the same
convention appears as `# [azure-ai]` comment markers: delete the marked lines
when the block does not apply, delete just the markers when it does.

  azure-ai      App calls a pre-provisioned Azure AI model. Delete if there is no AI integration.

Adapt the database and storage command examples to the actual
{{AZURE_DB_TYPE}} / {{AZURE_STORAGE_TYPE}} chosen -- the SQL and Blob examples
are illustrations, not mandates.

No {{...}} token, no [tag] marker, and none of these notes may remain in the
tailored output.
-->

# {{APP_NAME}} -- Azure Deployment Prompt

## Core Definitions

| ID               | Value                                              |
| ---------------- | -------------------------------------------------- |
| `user_stories`   | All User Stories in `spec.md`                      |
| `resource_group` | `{{RESOURCE_GROUP}}` ({{AZURE_REGION}})            |
| `compute`        | Azure Container Apps                               |
| `backend`        | {{BACKEND_FRAMEWORK}} -- containerized             |
| `frontend`       | {{FRONTEND_FRAMEWORK}} -- containerized            |
| `database`       | {{AZURE_DB_TYPE}} (replaces local {{LOCAL_DB_TYPE}})       |
| `storage`        | {{AZURE_STORAGE_TYPE}} (replaces local {{LOCAL_STORAGE_TYPE}}) |
| `auth`           | {{DEPLOYED_AUTH_TYPE}}                             |
| `ci_cd`          | GitHub Actions (managed via `gh` CLI)              |
| `browser_tool`   | {{BROWSER_TOOL}}                                   |
| `progress`       | `{{PROGRESS_FILE}}`                                |

<!-- OPTIONAL: azure-ai -->

| ID             | Value                                                                                              |
| -------------- | -------------------------------------------------------------------------------------------------- |
| `ai_account`   | `{{AI_ACCOUNT_NAME}}` -- Azure AI Services account -- **already provisioned**                      |
| `deployment`   | `{{DEPLOYMENT_NAME}}` (model: {{MODEL_NAME}}, {{TPM}} TPM, GlobalStandard) -- **already deployed** |
| `api_endpoint` | `{{API_ENDPOINT}}`                                                                                 |

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

Deploy {{APP_NAME}} to Azure: Container Apps for compute, {{AZURE_DB_TYPE}}
replacing {{LOCAL_DB_TYPE}}, {{AZURE_STORAGE_TYPE}} replacing
{{LOCAL_STORAGE_TYPE}}, secured with {{DEPLOYED_AUTH_TYPE}}, with GitHub
Actions as the only deployment path for code. Then validate the deployed
application end-to-end against `spec.md`.

Completion is defined solely by the checklist in the "Completion, Blockers &
Stopping" section at the end of this prompt -- nothing else.

**Resource group constraint -- ABSOLUTE:** every resource lives in
`{{RESOURCE_GROUP}}` ({{AZURE_REGION}}). No other resource group may be used,
referenced, or created under any circumstances; every `az` command targets
`-g {{RESOURCE_GROUP}}` explicitly.

**Secrets rule:** secret values (keys, passwords, connection strings) exist
only in shell variables, GitHub secrets, and Container App secrets. Never
write them into files, commits, logs, or this prompt.

---

## Progress Tracking -- Read First, Update Always

`{{PROGRESS_FILE}}` is the single source of truth for progress. Conversation
memory does not survive context compaction or fresh-context passes
(multipass); this file does.

- **On start:** if the file exists, read it and resume from the first item not
  marked `passed`. If it does not exist, create it with one line per phase
  step below and one line per user story in `spec.md`, all `pending`.
- **Line format:** `item | pending / in-progress / passed / blocked | short note`
  -- for `blocked`, the note states exactly what is missing and what was tried.
- **Update immediately** whenever an item changes state -- never in batches.
- Append one line to a `## Session log` section at the bottom of the file at
  the start of each pass.

---

## Target Architecture

| Resource                     | Purpose                                           | Status         |
| ---------------------------- | ------------------------------------------------- | -------------- |
| Azure Container Registry     | Container image storage                           | TO BE CREATED  |
| Container Apps Environment   | Container runtime for backend + frontend          | TO BE CREATED  |
| Backend Container App        | {{BACKEND_FRAMEWORK}} (`{{BACKEND_APP_NAME}}`)    | TO BE CREATED  |
| Frontend Container App       | {{FRONTEND_FRAMEWORK}} + nginx (`{{FRONTEND_APP_NAME}}`) | TO BE CREATED  |
| {{AZURE_DB_TYPE}}            | Application database (replaces {{LOCAL_DB_TYPE}}) | TO BE CREATED  |
| {{AZURE_STORAGE_TYPE}}       | Application file storage                          | TO BE CREATED  |
| [azure-ai] Azure AI Services | `{{AI_ACCOUNT_NAME}}` with `{{DEPLOYMENT_NAME}}` ({{TPM}} TPM) | ALREADY EXISTS |

```text
[Users / Browser] -- {{DEPLOYED_AUTH_TYPE}}
        |
[Frontend Container App: {{FRONTEND_FRAMEWORK}} + nginx]
        |  nginx proxies /api (and WebSocket upgrades) to the backend
[Backend Container App: {{BACKEND_FRAMEWORK}}]
        |
[{{AZURE_DB_TYPE}}]  [{{AZURE_STORAGE_TYPE}}]  [azure-ai: {{DEPLOYMENT_NAME}}]
```

**API wiring -- one pattern only:** the frontend calls the API with relative
`/api/...` paths (exactly as it does against the local dev proxy), and nginx
in the frontend container proxies those to the backend's FQDN. Everything
stays same-origin, so no CORS configuration is needed. Do NOT also bake an
absolute API base URL into the frontend build -- pick this one pattern. (Only
if the app genuinely must call the backend origin directly: set the API base
URL at build time AND enable CORS on the backend for the frontend origin --
then keep that consistent everywhere instead.)

---

## Phase 1: Azure Infrastructure Provisioning

### 1.1 Verify Existing Resources

Never recreate resources that already exist.

```bash
az group show --name {{RESOURCE_GROUP}} --output table
az resource list --resource-group {{RESOURCE_GROUP}} --output table

# [azure-ai] Verify the pre-provisioned AI account and model deployment
az cognitiveservices account show -n {{AI_ACCOUNT_NAME}} -g {{RESOURCE_GROUP}} --output table   # [azure-ai]
az cognitiveservices account deployment show \
  --deployment-name {{DEPLOYMENT_NAME}} -n {{AI_ACCOUNT_NAME}} -g {{RESOURCE_GROUP}} --output table   # [azure-ai]
```

### 1.2 Create Azure Container Registry

```bash
az acr create \
  --resource-group {{RESOURCE_GROUP}} \
  --name {{ACR_NAME}} \
  --sku Basic \
  --location {{AZURE_REGION}} \
  --admin-enabled true
```

### 1.3 Create Database Resources

Adapt to the chosen {{AZURE_DB_TYPE}}. Example for Azure SQL -- note the
password is generated, pushed straight into a GitHub secret, and kept only in
the shell variable (used again in Phase 3.3; regenerate the same way if the
shell is lost):

```bash
SQL_ADMIN_PASSWORD="$(openssl rand -base64 24)"
gh secret set AZURE_SQL_PASSWORD --body "$SQL_ADMIN_PASSWORD"

az sql server create \
  --resource-group {{RESOURCE_GROUP}} \
  --name {{SQL_SERVER_NAME}} \
  --location {{AZURE_REGION}} \
  --admin-user sqladmin \
  --admin-password "$SQL_ADMIN_PASSWORD"

az sql db create \
  --resource-group {{RESOURCE_GROUP}} \
  --server {{SQL_SERVER_NAME}} \
  --name {{SQL_DB_NAME}} \
  --service-objective S0

az sql server firewall-rule create \
  --resource-group {{RESOURCE_GROUP}} \
  --server {{SQL_SERVER_NAME}} \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### 1.4 Create Storage Resources

Adapt to the chosen {{AZURE_STORAGE_TYPE}}. Example for Azure Blob Storage:

```bash
az storage account create \
  --resource-group {{RESOURCE_GROUP}} \
  --name {{STORAGE_ACCOUNT_NAME}} \
  --location {{AZURE_REGION}} \
  --sku Standard_LRS \
  --kind StorageV2

az storage container create \
  --account-name {{STORAGE_ACCOUNT_NAME}} \
  --name {{CONTAINER_NAME}} \
  --auth-mode login
```

### 1.5 Create Container Apps Environment

```bash
az containerapp env create \
  --resource-group {{RESOURCE_GROUP}} \
  --name {{CAE_NAME}} \
  --location {{AZURE_REGION}}
```

---

## Phase 2: Application Code Changes for Azure Deployment

The pattern for every concern below: a `DEPLOY_MODE` environment variable
selects the implementation. `DEPLOY_MODE=azure` uses the cloud service;
`DEPLOY_MODE=local` (or unset) keeps the existing local behavior UNCHANGED.

### 2.1 Database Migration

- Route database configuration through the `DEPLOY_MODE` check: Azure
  connection string in `azure` mode, existing {{LOCAL_DB_TYPE}} config in
  `local` mode.
- Ensure schema creation and migrations run correctly against
  {{AZURE_DB_TYPE}}, and all application tables create correctly.

### 2.2 Storage Migration

- Route the storage module through the `DEPLOY_MODE` check: the
  {{AZURE_STORAGE_TYPE}} SDK for upload, download, delete, and serve in
  `azure` mode; the existing local filesystem behavior in `local` mode.
- Update every route that accepts uploads or serves files to use the selected
  storage backend.

### 2.3 Authentication Migration

- Route the auth module through the `DEPLOY_MODE` check: {{DEPLOYED_AUTH_TYPE}}
  in `azure` mode, existing local auth unchanged in `local` mode.
- Always exempt `{{HEALTH_ENDPOINT}}` from authentication.
- Update the frontend login UI and API request interceptors to match the
  deployed auth flow, including WebSocket connections if the app uses them.

### 2.4 Backend Dockerfile

Create `{{BACKEND_DIR}}/Dockerfile`; include system-level dependencies the
database driver or storage SDK needs. Example shape (adapt base image and
commands to {{BACKEND_FRAMEWORK}}):

```dockerfile
FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2.5 Frontend Dockerfile and nginx

Create `{{FRONTEND_DIR}}/Dockerfile` (multi-stage) and
`{{FRONTEND_DIR}}/nginx.conf.template`. The template goes to
`/etc/nginx/templates/`, where the official nginx image's entrypoint runs
`envsubst` on it at startup: `${BACKEND_ORIGIN}` is filled from the Container
App's environment, while nginx runtime variables like `$host` are untouched
(they are not environment variables). The backend FQDN therefore never needs
to be baked into the image -- changing it is just an env-var update.

```dockerfile
FROM node:20-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

`{{FRONTEND_DIR}}/nginx.conf.template`:

```nginx
server {
    listen 80;
    server_name _;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass ${BACKEND_ORIGIN};
        proxy_ssl_server_name on;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_cache off;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }
}
```

Do not add a `proxy_set_header Host ...` line: the default (`$proxy_host`,
i.e. the backend FQDN) is required for Container Apps ingress routing.

---

## Phase 3: GitHub Actions CI/CD Pipeline

### 3.1 Create GitHub Actions Workflow

**File:** `.github/workflows/deploy.yml`. The backend and frontend jobs are
independent (the frontend build does not need the backend FQDN -- nginx
resolves it at runtime from `BACKEND_ORIGIN`).

```yaml
name: Deploy {{APP_NAME}}

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  RESOURCE_GROUP: {{RESOURCE_GROUP}}
  ACR_NAME: {{ACR_NAME}}
  BACKEND_APP: {{BACKEND_APP_NAME}}
  FRONTEND_APP: {{FRONTEND_APP_NAME}}

jobs:
  build-and-deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Login to Azure
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Login to ACR
        run: az acr login --name ${{ env.ACR_NAME }}

      - name: Build and push backend image
        run: |
          cd {{BACKEND_DIR}}
          docker build -t ${{ env.ACR_NAME }}.azurecr.io/${{ env.BACKEND_APP }}:${{ github.sha }} .
          docker push ${{ env.ACR_NAME }}.azurecr.io/${{ env.BACKEND_APP }}:${{ github.sha }}

      - name: Deploy backend Container App
        run: |
          az containerapp update \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --name ${{ env.BACKEND_APP }} \
            --image ${{ env.ACR_NAME }}.azurecr.io/${{ env.BACKEND_APP }}:${{ github.sha }}

  build-and-deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Login to Azure
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Login to ACR
        run: az acr login --name ${{ env.ACR_NAME }}

      - name: Build and push frontend image
        run: |
          cd {{FRONTEND_DIR}}
          docker build -t ${{ env.ACR_NAME }}.azurecr.io/${{ env.FRONTEND_APP }}:${{ github.sha }} .
          docker push ${{ env.ACR_NAME }}.azurecr.io/${{ env.FRONTEND_APP }}:${{ github.sha }}

      - name: Deploy frontend Container App
        run: |
          az containerapp update \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --name ${{ env.FRONTEND_APP }} \
            --image ${{ env.ACR_NAME }}.azurecr.io/${{ env.FRONTEND_APP }}:${{ github.sha }}

  verify-deployment:
    runs-on: ubuntu-latest
    needs: [build-and-deploy-backend, build-and-deploy-frontend]
    steps:
      - name: Login to Azure
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Verify backend health
        run: |
          BACKEND_FQDN=$(az containerapp show \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --name ${{ env.BACKEND_APP }} \
            --query "properties.configuration.ingress.fqdn" -o tsv)
          for i in {1..10}; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$BACKEND_FQDN{{HEALTH_ENDPOINT}}" || true)
            if [ "$STATUS" = "200" ]; then
              echo "Backend is healthy"
              exit 0
            fi
            echo "Attempt $i: Backend returned $STATUS, retrying in 15s..."
            sleep 15
          done
          echo "Backend health check failed after 10 attempts"
          exit 1

      - name: Verify frontend health
        run: |
          FRONTEND_FQDN=$(az containerapp show \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --name ${{ env.FRONTEND_APP }} \
            --query "properties.configuration.ingress.fqdn" -o tsv)
          for i in {1..10}; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$FRONTEND_FQDN/" || true)
            if [ "$STATUS" = "200" ]; then
              echo "Frontend is healthy"
              exit 0
            fi
            echo "Attempt $i: Frontend returned $STATUS, retrying in 15s..."
            sleep 15
          done
          echo "Frontend health check failed after 10 attempts"
          exit 1
```

### 3.2 Set GitHub Secrets

```bash
# Azure Service Principal credentials for azure/login
gh secret set AZURE_CREDENTIALS < azure-credentials.json
```

(`AZURE_SQL_PASSWORD` was already set in Phase 1.3. Add further secrets the
workflow needs the same way -- always via `gh secret set`, never committed.)

### 3.3 Create Container Apps with Placeholder Images

Create the apps once with placeholder images; GitHub Actions replaces the
images from then on. Create the backend first, then the frontend (which needs
the backend FQDN for its `BACKEND_ORIGIN` env var).

```bash
# [azure-ai] Retrieve the AI key into the shell only -- never into a file
AI_KEY="$(az cognitiveservices account keys list -n {{AI_ACCOUNT_NAME}} -g {{RESOURCE_GROUP}} | jq -r '.key1')"   # [azure-ai]

az containerapp create \
  --resource-group {{RESOURCE_GROUP}} \
  --name {{BACKEND_APP_NAME}} \
  --environment {{CAE_NAME}} \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 8000 \
  --ingress external \
  --secrets sql-password="$SQL_ADMIN_PASSWORD" openai-key="$AI_KEY" \
  --env-vars \
    DEPLOY_MODE=azure \
    AZURE_SQL_SERVER={{SQL_SERVER_NAME}} \
    AZURE_SQL_DATABASE={{SQL_DB_NAME}} \
    AZURE_SQL_USERNAME=sqladmin \
    AZURE_SQL_PASSWORD=secretref:sql-password \
    AZURE_STORAGE_ACCOUNT={{STORAGE_ACCOUNT_NAME}} \
    AZURE_OPENAI_ENDPOINT={{API_ENDPOINT}} \
    AZURE_OPENAI_API_KEY=secretref:openai-key \
    AZURE_OPENAI_DEPLOYMENT={{DEPLOYMENT_NAME}}
# [azure-ai] The three AZURE_OPENAI_* lines and the openai-key secret belong to the azure-ai block.
# Adapt the AZURE_SQL_* / AZURE_STORAGE_* lines to the chosen database and storage types.

BACKEND_FQDN=$(az containerapp show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv)

az containerapp create \
  --resource-group {{RESOURCE_GROUP}} \
  --name {{FRONTEND_APP_NAME}} \
  --environment {{CAE_NAME}} \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 80 \
  --ingress external \
  --env-vars BACKEND_ORIGIN="https://$BACKEND_FQDN"
```

Give both apps pull access to the registry, or the first real deployment will
fail to pull its image:

```bash
for APP in {{BACKEND_APP_NAME}} {{FRONTEND_APP_NAME}}; do
  az containerapp registry set \
    --resource-group {{RESOURCE_GROUP}} \
    --name "$APP" \
    --server {{ACR_NAME}}.azurecr.io \
    --username "$(az acr credential show -n {{ACR_NAME}} --query username -o tsv)" \
    --password "$(az acr credential show -n {{ACR_NAME}} --query 'passwords[0].value' -o tsv)"
done
```

---

## Phase 4: Deployment Execution

Direct `az` deployment of code is allowed ONLY for the Phase 3.3 placeholder
creation above. From here on, ALL code deployments go through GitHub Actions:
commit, push, wait for the workflow. If the workflow fails, debug and push a
fix -- never bypass the pipeline.

```bash
git add <explicit file paths>   # never `git add .` -- it sweeps in untracked files
git commit -m "configure Azure deployment"
git push origin main

gh run list --limit 1
gh run watch
gh run view --log-failed
```

Post-deployment verification:

```bash
BACKEND_FQDN=$(az containerapp show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv)
FRONTEND_FQDN=$(az containerapp show -g {{RESOURCE_GROUP}} -n {{FRONTEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv)

curl -s "https://$BACKEND_FQDN{{HEALTH_ENDPOINT}}" | jq .

az containerapp logs show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --tail 100
az containerapp logs show -g {{RESOURCE_GROUP}} -n {{FRONTEND_APP_NAME}} --tail 100

az containerapp revision list -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --output table
az containerapp revision list -g {{RESOURCE_GROUP}} -n {{FRONTEND_APP_NAME}} --output table
```

---

## Phase 5: Post-Deployment Validation

### 5.1 Authentication

- `{{HEALTH_ENDPOINT}}` is publicly accessible (no auth)
- All protected backend routes reject unauthenticated and invalid requests
- Valid credentials grant access; the frontend login UI works end-to-end;
  logout clears credentials and prevents further access
- WebSocket connections authenticate correctly (if the app uses them)

### 5.2 Feature Validation

Validate every feature in `spec.md` against the deployed application with
{{BROWSER_TOOL}}, tracking each story in `{{PROGRESS_FILE}}`: UI renders,
API responds, data persists in {{AZURE_DB_TYPE}}, files round-trip through
{{AZURE_STORAGE_TYPE}}, errors are handled, and the UI works at desktop
(1280px) and mobile (375px) widths.

### 5.3 Iterative Fix Cycle

1. Debug (container logs, workflow logs, screenshots).
2. Fix the code locally; commit and push to trigger GitHub Actions.
3. Wait for workflow success (`gh run watch`); verify deployment health.
4. Re-validate against the deployed app; update `{{PROGRESS_FILE}}`.

**Stuck rule:** after 3 failed fix-and-deploy cycles on the same issue, record
what you tried in `{{PROGRESS_FILE}}`, mark the item `blocked`, move on, and
revisit blocked items at the end.

---

## Completion, Blockers & Stopping

**Definition of done -- every box checked:**

- [ ] All Azure infrastructure is provisioned in `{{RESOURCE_GROUP}}` and
      nowhere else
- [ ] The GitHub Actions pipeline deploys both apps successfully and is green
      on the latest commit
- [ ] `{{HEALTH_ENDPOINT}}` returns 200 without authentication
- [ ] Authentication ({{DEPLOYED_AUTH_TYPE}}) is enforced on all protected routes
- [ ] Database and storage connectivity are confirmed operational (CRUD and
      file round-trips work in the deployed app)
- [ ] [azure-ai] The AI model endpoint is confirmed responsive through the app
- [ ] Local mode still works: `DEPLOY_MODE=local` behavior is unchanged
- [ ] Every user story in `spec.md` is validated against the deployed app with
      {{BROWSER_TOOL}} and marked `passed` in `{{PROGRESS_FILE}}`
- [ ] `{{PROGRESS_FILE}}` is up to date with no `pending` or `in-progress` items

Work autonomously and persistently toward this checklist. Do not stop because
the task list is large or context is running low -- context is compacted
automatically, and `{{PROGRESS_FILE}}` carries state across passes.

**The only valid reasons to mark an item `blocked` instead of finishing it:**

- Credentials, permissions, or quota you cannot obtain (e.g. subscription
  limits on creating a resource)
- A decision that belongs to a human: notable spend beyond the resources this
  prompt names, deleting data, changing scope
- A contradiction in `spec.md` that cannot be resolved conservatively
- The stuck rule (3 failed fix-and-deploy cycles) fired

Stop only when every item is `passed`, or the only remaining items are
`blocked`. Then report: what was deployed and validated, and every blocker
from `{{PROGRESS_FILE}}` with what was tried. Never claim success for anything
not actually verified.

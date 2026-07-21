# {{APP_NAME}} -- Azure Deployment Prompt

## Core Definitions

| ID               | Value                                                                                              |
| ---------------- | -------------------------------------------------------------------------------------------------- |
| `user_stories`   | All User Stories in `spec.md`                                                                      |
| `resource_group` | `{{RESOURCE_GROUP}}` (East US 2)                                                                   |
| `ai_account`     | `{{AI_ACCOUNT_NAME}}` -- Azure AI Services account -- **already provisioned**                      |
| `deployment`     | `{{DEPLOYMENT_NAME}}` (model: {{MODEL_NAME}}, {{TPM}} TPM, GlobalStandard) -- **already deployed** |
| `model`          | `{{MODEL_NAME}}` via Azure AI Services                                                             |
| `api_endpoint`   | `{{API_ENDPOINT}}`                                                                                 |
| `database`       | {{AZURE_DB_TYPE}} (replaces local {{LOCAL_DB_TYPE}})                                               |
| `storage`        | {{AZURE_STORAGE_TYPE}} (replaces local {{LOCAL_STORAGE_TYPE}})                                     |
| `compute`        | Azure Container Apps                                                                               |
| `auth`           | {{DEPLOYED_AUTH_TYPE}}                                                                             |
| `ci_cd`          | GitHub Actions (managed via `gh` CLI)                                                              |
| `backend`        | {{BACKEND_FRAMEWORK}} -- containerized                                                             |
| `frontend`       | {{FRONTEND_FRAMEWORK}} -- containerized                                                            |

---

## Primary Goal

Deploy {{APP_NAME}} to Azure using Container Apps, {{AZURE_DB_TYPE}} (replacing {{LOCAL_DB_TYPE}}), {{AZURE_STORAGE_TYPE}} (replacing {{LOCAL_STORAGE_TYPE}}), and the existing `{{DEPLOYMENT_NAME}}` deployment. Secure the application with {{DEPLOYED_AUTH_TYPE}}. Use GitHub Actions (managed via `gh` CLI) for CI/CD. Validate the deployed application end-to-end per all features in `spec.md`.

**YOU CANNOT STOP UNTIL THE APPLICATION IS FULLY DEPLOYED, SECURED WITH {{DEPLOYED_AUTH_TYPE}}, AND VALIDATED END-TO-END.**

---

## Deployment Architecture -- Target State

### Azure Resources (all in `{{RESOURCE_GROUP}}`, East US 2)

| Resource                     | Purpose                                              | Status          |
| ---------------------------- | ---------------------------------------------------- | --------------- |
| Azure AI Services account    | `{{AI_ACCOUNT_NAME}}` with `{{DEPLOYMENT_NAME}}`     | ALREADY EXISTS  |
| `{{DEPLOYMENT_NAME}}` model  | Chat completions + tool calling ({{TPM}} TPM)        | ALREADY EXISTS  |
| Azure Container Apps Env     | Container runtime for backend + frontend             | TO BE CREATED   |
| Backend Container App        | {{BACKEND_FRAMEWORK}} backend                        | TO BE CREATED   |
| Frontend Container App       | {{FRONTEND_FRAMEWORK}} frontend (nginx)              | TO BE CREATED   |
| {{AZURE_DB_TYPE}}            | Application database (replaces {{LOCAL_DB_TYPE}})    | TO BE CREATED   |
| {{AZURE_STORAGE_TYPE}}       | Application file storage                             | TO BE CREATED   |
| Azure Container Registry     | Container image storage for backend + frontend       | TO BE CREATED   |

### Architecture Diagram

```
                    [{{DEPLOYED_AUTH_TYPE}}]
                          |
                [Users / Browser]
                          |
               [Frontend Container App]
                  ({{FRONTEND_FRAMEWORK}} + nginx)
                    |         |
               [WebSocket]  [REST]
                    |         |
               [Backend Container App]
                  ({{BACKEND_FRAMEWORK}})
                 /        |        \
     [{{AZURE_DB_TYPE}}] [{{AZURE_STORAGE_TYPE}}] [Azure AI Services]
     (application       (application              ({{DEPLOYMENT_NAME}}
      data)              files)                    endpoint)
```

---

## Phase 1: Azure Infrastructure Provisioning

### 1.1 Verify Existing Resources

Confirm the existing `{{DEPLOYMENT_NAME}}` deployment is healthy before proceeding. **NEVER recreate resources that already exist.**

```bash
# Verify resource group
az group show --name {{RESOURCE_GROUP}} --output table

# List existing resources
az resource list --resource-group {{RESOURCE_GROUP}} --output table

# Verify AI account
az cognitiveservices account show -n {{AI_ACCOUNT_NAME}} -g {{RESOURCE_GROUP}} --output table

# Verify model deployment
az cognitiveservices account deployment show \
  --deployment-name {{DEPLOYMENT_NAME}} \
  -n {{AI_ACCOUNT_NAME}} \
  -g {{RESOURCE_GROUP}} \
  --output table
```

### 1.2 Create Azure Container Registry

```bash
ACR_NAME="{{ACR_NAME}}"

az acr create \
  --resource-group {{RESOURCE_GROUP}} \
  --name $ACR_NAME \
  --sku Basic \
  --location eastus2 \
  --admin-enabled true
```

### 1.3 Create Database Resources

Create the Azure database to replace the local development database.

```bash
# -- Adapt commands to match your chosen Azure database type --
# Example for Azure SQL:
SQL_SERVER_NAME="{{SQL_SERVER_NAME}}"
SQL_DB_NAME="{{SQL_DB_NAME}}"
SQL_ADMIN_USER="sqladmin"

az sql server create \
  --resource-group {{RESOURCE_GROUP}} \
  --name $SQL_SERVER_NAME \
  --location eastus2 \
  --admin-user $SQL_ADMIN_USER \
  --admin-password "<STRONG_PASSWORD>"

az sql db create \
  --resource-group {{RESOURCE_GROUP}} \
  --server $SQL_SERVER_NAME \
  --name $SQL_DB_NAME \
  --service-objective S0

az sql server firewall-rule create \
  --resource-group {{RESOURCE_GROUP}} \
  --server $SQL_SERVER_NAME \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### 1.4 Create Storage Resources

Create the Azure storage to replace the local development storage.

```bash
# -- Adapt commands to match your chosen Azure storage type --
# Example for Azure Blob Storage:
STORAGE_ACCOUNT_NAME="{{STORAGE_ACCOUNT_NAME}}"

az storage account create \
  --resource-group {{RESOURCE_GROUP}} \
  --name $STORAGE_ACCOUNT_NAME \
  --location eastus2 \
  --sku Standard_LRS \
  --kind StorageV2

# Create containers as needed for your application
az storage container create \
  --account-name $STORAGE_ACCOUNT_NAME \
  --name {{CONTAINER_NAME}} \
  --auth-mode login
```

### 1.5 Create Container Apps Environment

```bash
CAE_NAME="{{CAE_NAME}}"

az containerapp env create \
  --resource-group {{RESOURCE_GROUP}} \
  --name $CAE_NAME \
  --location eastus2
```

---

## Phase 2: Application Code Changes for Azure Deployment

### 2.1 Database Migration

Replace the local development database with the Azure database service.

**Required changes:**

- Add `DEPLOY_MODE` environment variable check to database configuration
- When `DEPLOY_MODE=azure`: use Azure database connection string
- When `DEPLOY_MODE=local`: keep existing local database configuration unchanged
- Ensure all schema creation and migrations work against the Azure database
- Test that all application tables create correctly in the Azure database

### 2.2 Storage Migration

Replace all local filesystem operations with Azure storage.

**Required changes:**

- Add `DEPLOY_MODE` environment variable check to storage module
- When `DEPLOY_MODE=azure`: use Azure storage SDK for all file operations (upload, download, delete, serve)
- When `DEPLOY_MODE=local`: keep existing local filesystem behavior unchanged
- Update all routes that serve files to read from Azure storage in deployed mode
- Update all routes that accept uploads to write to Azure storage in deployed mode

### 2.3 Backend Dockerfile

Create a `Dockerfile` for the backend application. Include any system-level dependencies required by the Azure database driver or storage SDK.

```dockerfile
FROM python:3.12-slim

# Install system dependencies (adapt as needed for your database driver)
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

### 2.4 Frontend Dockerfile

Create a `Dockerfile` for the frontend application using a multi-stage build.

```dockerfile
FROM node:20-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Create `frontend/nginx.conf`:

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
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
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

**Note:** In Container Apps, the backend URL will be the internal FQDN of the backend container app. Update the `proxy_pass` directive accordingly at deploy time.

### 2.5 Authentication Migration

Adapt the authentication mechanism for the deployed environment.

**Required changes:**

- Add `DEPLOY_MODE` environment variable check to the auth module
- When `DEPLOY_MODE=azure`: switch to the deployed auth mechanism ({{DEPLOYED_AUTH_TYPE}})
- When `DEPLOY_MODE=local`: keep existing local auth unchanged
- Always exempt `/api/health` from authentication
- Update the frontend login UI to match the deployed auth flow
- Update all API request interceptors to attach the correct auth headers
- Update WebSocket connections to pass authentication appropriately

---

## Phase 3: GitHub Actions CI/CD Pipeline

### 3.1 Create GitHub Actions Workflow

**File:** `.github/workflows/deploy.yml`

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
  CAE_NAME: {{CAE_NAME}}

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
          cd backend
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
    needs: build-and-deploy-backend
    steps:
      - uses: actions/checkout@v4

      - name: Login to Azure
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Login to ACR
        run: az acr login --name ${{ env.ACR_NAME }}

      - name: Get backend FQDN
        id: backend
        run: |
          FQDN=$(az containerapp show \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --name ${{ env.BACKEND_APP }} \
            --query "properties.configuration.ingress.fqdn" -o tsv)
          echo "fqdn=$FQDN" >> $GITHUB_OUTPUT

      - name: Build and push frontend image
        run: |
          cd frontend
          echo "VITE_API_BASE_URL=https://${{ steps.backend.outputs.fqdn }}" > .env.production
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
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$BACKEND_FQDN/api/health" || true)
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
# Azure Service Principal credentials
gh secret set AZURE_CREDENTIALS < azure-credentials.json

# Or set individual secrets as needed by your workflow
gh secret set ACR_USERNAME --body "$(az acr credential show -n {{ACR_NAME}} --query username -o tsv)"
gh secret set ACR_PASSWORD --body "$(az acr credential show -n {{ACR_NAME}} --query 'passwords[0].value' -o tsv)"
```

### 3.3 Create Container Apps with Placeholder Images

Before the first GitHub Actions run, create the Container Apps with placeholder images:

```bash
az containerapp create \
  --resource-group {{RESOURCE_GROUP}} \
  --name {{BACKEND_APP_NAME}} \
  --environment {{CAE_NAME}} \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 8000 \
  --ingress external \
  --env-vars \
    DEPLOY_MODE=azure \
    AZURE_OPENAI_ENDPOINT={{API_ENDPOINT}} \
    AZURE_OPENAI_API_KEY=secretref:openai-key \
    AZURE_OPENAI_DEPLOYMENT={{DEPLOYMENT_NAME}}

az containerapp create \
  --resource-group {{RESOURCE_GROUP}} \
  --name {{FRONTEND_APP_NAME}} \
  --environment {{CAE_NAME}} \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 80 \
  --ingress external
```

---

## Phase 4: Deployment Execution

### 4.1 Initial Deployment

```bash
git add <explicit file paths>   # never `git add .` -- it sweeps in untracked files
git commit -m "configure Azure deployment"
git push origin main
```

### 4.2 Monitor Workflow

```bash
gh run list --limit 1
gh run watch
gh run view --log-failed
```

### 4.3 Post-Deployment Verification

```bash
BACKEND_FQDN=$(az containerapp show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv)
FRONTEND_FQDN=$(az containerapp show -g {{RESOURCE_GROUP}} -n {{FRONTEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv)

# Health check
curl -s "https://$BACKEND_FQDN/api/health" | jq .

# Check container logs
az containerapp logs show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --tail 100
az containerapp logs show -g {{RESOURCE_GROUP}} -n {{FRONTEND_APP_NAME}} --tail 100

# Revision status
az containerapp revision list -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --output table
az containerapp revision list -g {{RESOURCE_GROUP}} -n {{FRONTEND_APP_NAME}} --output table
```

---

## Phase 5: Post-Deployment Validation

### 5.1 Authentication Validation

Verify that the deployed authentication mechanism is working correctly:

- Health endpoint is publicly accessible (no auth required)
- All protected backend routes reject unauthenticated requests
- Valid credentials grant access to all protected routes
- Invalid credentials are rejected
- Frontend login UI works correctly
- WebSocket authentication works correctly
- Logout clears credentials and prevents further access

### 5.2 End-to-End Feature Validation

Validate every feature defined in `spec.md` against the deployed application using playwright-cli.

### 5.3 Iterative Fix Cycle

For any issues found during validation:

1. Debug the issue (container logs, GitHub Actions logs, Playwright screenshots).
2. Fix the code locally.
3. Commit and push to trigger GitHub Actions.
4. Wait for workflow success (`gh run watch`).
5. Re-validate the fix against the deployed application.
6. Repeat until resolved.

---

## Environment Variables

### Backend Container App

| Variable                      | Purpose                                    |
| ----------------------------- | ------------------------------------------ |
| `DEPLOY_MODE`                 | `azure` -- enables cloud service paths     |
| `AZURE_OPENAI_ENDPOINT`       | Azure AI Services endpoint URL             |
| `AZURE_OPENAI_API_KEY`        | Azure AI Services API key                  |
| `AZURE_OPENAI_DEPLOYMENT`     | Model deployment name                      |
| `AZURE_SQL_SERVER`            | Azure SQL server name (if using SQL)       |
| `AZURE_SQL_DATABASE`          | Azure SQL database name (if using SQL)     |
| `AZURE_SQL_USERNAME`          | Azure SQL admin username (if using SQL)    |
| `AZURE_SQL_PASSWORD`          | Azure SQL admin password (if using SQL)    |
| `AZURE_STORAGE_ACCOUNT`       | Azure Storage account name                 |
| `AZURE_STORAGE_KEY`           | Azure Storage account key                  |

---

## Resource Group Constraint -- ABSOLUTE

- All resources MUST be in resource group `{{RESOURCE_GROUP}}` (East US 2).
- **NO OTHER RESOURCE GROUP MAY BE USED, REFERENCED, OR CREATED UNDER ANY CIRCUMSTANCES.**
- Every `az cli` command MUST target `-g {{RESOURCE_GROUP}}` explicitly.

---

## Autonomous Work Expectations -- CRITICAL

### Context Window Management

Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off.

### Completion Mandate -- ABSOLUTE

- **YOU CANNOT STOP** until the application is FULLY DEPLOYED and VALIDATED.
- **DO NOT** stop early -- work until EVERYTHING is FLESHED OUT COMPLETELY.
- Do NOT stop tasks due to token budget concerns.
- Complete tasks FULLY, even if end of budget is approaching.
- NEVER artificially stop any task early regardless of context remaining.

### Work Cycle

1. Provision Azure infrastructure (Phase 1).
2. Adapt application code for Azure (Phase 2).
3. Configure GitHub Actions CI/CD (Phase 3).
4. Deploy and verify (Phase 4).
5. Validate end-to-end per `spec.md` (Phase 5).
6. Debug and fix any issues -- commit, push, wait for workflow, re-validate.
7. Repeat until ALL features are deployed and working.

---

## Deployment Rules -- MANDATORY

- **NEVER** deploy code changes using `az cli`, `az containerapp update`, or any direct Azure deployment command outside of initial placeholder creation.
- **ALWAYS** use `git push` to trigger GitHub Actions for ALL code deployments.
- Wait for the GitHub Actions workflow to complete before testing deployed changes.
- If the GitHub Actions workflow fails, debug the failure and push a fix -- do NOT bypass the pipeline.

---

## Execution Plan

1. Verify existing Azure resources in `{{RESOURCE_GROUP}}` (AI account + model deployment).
2. Create Azure Container Registry.
3. Create Azure database resources.
4. Create Azure storage resources.
5. Create Container Apps Environment.
6. Adapt backend code for `DEPLOY_MODE=azure` (database, storage, auth).
7. Create backend Dockerfile.
8. Adapt frontend code for deployed auth and API configuration.
9. Create frontend Dockerfile and nginx.conf.
10. Create GitHub Actions workflow (`.github/workflows/deploy.yml`).
11. Set GitHub secrets.
12. Create Container Apps with placeholder images and environment variables.
13. Push code to trigger first deployment.
14. Monitor GitHub Actions workflow (`gh run watch`).
15. Verify deployment health (backend, frontend, logs, revisions).
16. Validate authentication end-to-end.
17. Validate all features in `spec.md` with playwright-cli against deployed URLs.
18. Debug and fix any issues (commit, push, wait, re-validate).
19. Repeat until ALL features pass validation.
20. Final end-to-end pass confirming complete deployment.

---

## Final Mandate -- ABSOLUTE

**YOU CANNOT STOP WORKING UNTIL:**

- All Azure infrastructure is provisioned in `{{RESOURCE_GROUP}}`
- GitHub Actions CI/CD pipeline deploys successfully
- Backend and frontend Container Apps are running and accessible
- Authentication is enforced on all protected routes
- `/api/health` returns 200 without authentication
- Database connectivity is confirmed operational
- Storage connectivity is confirmed operational
- AI model endpoint is confirmed responsive
- Every feature in `spec.md` is implemented in the deployed application
- Every feature is validated with playwright-cli against deployed URLs
- Every bug is debugged and fixed in production
- The entire deployed application works end-to-end
- EVERYTHING is FLESHED OUT COMPLETELY

| Concern             | Directive                                                                                              |
| ------------------- | ------------------------------------------------------------------------------------------------------ |
| **AZURE RESOURCES** | AI account and model ALREADY EXIST in `{{RESOURCE_GROUP}}` -- verify, do not recreate                  |
| **DATABASE**        | {{AZURE_DB_TYPE}} is the production database -- ensure all CRUD and persistence work correctly          |
| **STORAGE**         | {{AZURE_STORAGE_TYPE}} for application files -- ensure upload, download, delete all work correctly      |
| **AI MODEL**        | `{{MODEL_NAME}}` via Azure AI Services -- verify connectivity and model functionality                   |
| **AUTH**            | {{DEPLOYED_AUTH_TYPE}} is MANDATORY -- verify all protected routes reject unauthenticated requests      |
| **DEPLOYMENT**      | ALL code changes deploy via GitHub Actions (`git push`) -- NEVER via `az cli` direct deployment         |

**DO NOT STOP EARLY. WORK CONTINUOUSLY UNTIL COMPLETE.**

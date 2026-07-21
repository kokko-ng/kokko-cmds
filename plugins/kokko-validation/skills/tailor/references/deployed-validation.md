

# {{APP_NAME}} -- Deployed Validation & Testing Prompt

## Core Definitions

| ID               | Value                                                                                                                    |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `user_stories`   | All User Stories in `spec.md`                                                                                            |
| `resource_group` | `{{RESOURCE_GROUP}}` (East US 2)                                                                                         |
| `ai_account`     | `{{AI_ACCOUNT_NAME}}` -- Azure AI Services account                                                                       |
| `deployment`     | `{{DEPLOYMENT_NAME}}` (model: {{MODEL_NAME}}, {{TPM}} TPM, GlobalStandard)                                               |
| `model`          | `{{MODEL_NAME}}` via Azure AI Services                                                                                   |
| `api_endpoint`   | `{{API_ENDPOINT}}`                                                                                                       |
| `database`       | {{AZURE_DB_TYPE}}                                                                                                        |
| `storage`        | {{AZURE_STORAGE_TYPE}}                                                                                                   |
| `compute`        | Azure Container Apps (backend + frontend)                                                                                |
| `auth`           | {{DEPLOYED_AUTH_TYPE}}                                                                                                   |
| `backend`        | {{BACKEND_FRAMEWORK}} -- containerized                                                                                   |
| `frontend`       | {{FRONTEND_FRAMEWORK}} -- containerized                                                                                  |

---

## Primary Goal

Work autonomously to validate the DEPLOYED application end-to-end per all User Stories in `spec.md`. The application is already deployed in the `{{RESOURCE_GROUP}}` resource group using Azure Container Apps, {{AZURE_DB_TYPE}}, {{AZURE_STORAGE_TYPE}}, and `{{MODEL_NAME}}` via Azure AI Services. The application is secured with {{DEPLOYED_AUTH_TYPE}}. Resolve all remaining issues until fully functional.

**YOU CANNOT STOP UNTIL EVERYTHING IN `spec.md` IS IMPLEMENTED AND VALIDATED.**

---

## Deployment Architecture -- REQUIRED

### Deployed Application

- The application is **ALREADY DEPLOYED** in Azure resource group: `{{RESOURCE_GROUP}}`
- All validation and testing runs against the DEPLOYED application.
- Use the deployed application URLs for all playwright-cli testing.

### Azure Resources (all in `{{RESOURCE_GROUP}}`, East US 2)

| Resource                     | Purpose                                              | Status    |
| ---------------------------- | ---------------------------------------------------- | --------- |
| Azure AI Services account    | `{{AI_ACCOUNT_NAME}}` with `{{DEPLOYMENT_NAME}}`     | DEPLOYED  |
| `{{DEPLOYMENT_NAME}}` model  | Chat completions + tool calling ({{TPM}} TPM)        | DEPLOYED  |
| Container Apps Environment   | Container runtime for backend + frontend             | DEPLOYED  |
| Backend Container App        | {{BACKEND_FRAMEWORK}} (`{{BACKEND_APP_NAME}}`)       | DEPLOYED  |
| Frontend Container App       | {{FRONTEND_FRAMEWORK}} (`{{FRONTEND_APP_NAME}}`)     | DEPLOYED  |
| {{AZURE_DB_TYPE}}            | Application database                                 | DEPLOYED  |
| {{AZURE_STORAGE_TYPE}}       | Application file storage                             | DEPLOYED  |
| Azure Container Registry     | Container image storage                              | DEPLOYED  |

### Architecture Summary

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

## Authentication -- ENFORCED

### Current State

- Authentication is **ALREADY CONFIGURED** on the deployed backend.
- All backend routes except `/api/health` require valid authentication.
- The frontend provides a custom login page.

### Credential Retrieval

Retrieve credentials from the deployed Container App environment variables:

```bash
az containerapp show \
  -g {{RESOURCE_GROUP}} \
  -n {{BACKEND_APP_NAME}} \
  --query "properties.template.containers[0].env" \
  -o table
```

Use the retrieved credentials for all authentication testing.

### Authentication Validation -- MANDATORY

Validate the following before any other testing begins:

**1. Health endpoint is publicly accessible (no auth required):**

```bash
BACKEND_FQDN=$(az containerapp show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv)

curl -s -o /dev/null -w "%{http_code}" "https://$BACKEND_FQDN/api/health"
# Expected: 200
```

**2. All protected backend routes reject unauthenticated requests:**

```bash
for ROUTE in {{PROTECTED_ROUTES}}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$BACKEND_FQDN$ROUTE")
  echo "$ROUTE -> $STATUS (expected: 401)"
  if [ "$STATUS" != "401" ]; then
    echo "FAIL: $ROUTE returned $STATUS instead of 401"
  fi
done
```

**3. Valid credentials grant access.**

**4. Invalid credentials return 401.**

**5. Frontend login UI:**

Use playwright-cli to validate the login UI:

- Navigate to the frontend URL -- verify the custom login page loads
- Enter invalid credentials -- verify an error message is displayed and no navigation occurs
- Enter valid credentials -- verify the user is redirected to the main application
- After login, verify requests to the backend succeed
- Click logout -- verify the user is redirected back to the login page

**6. WebSocket authentication (if applicable):**

- Log in with valid credentials
- Perform an action that uses WebSocket
- Verify the WebSocket connection is established successfully
- Verify messages are streamed back correctly

---

## Azure CLI Permissions

### Authorization

You MAY use `az cli` for Azure resource INSPECTION and READ-ONLY queries.

### Resource Group Constraint -- STRICT

- The application is deployed in resource group: `{{RESOURCE_GROUP}}`
- You are RESTRICTED to working with resources in this resource group ONLY.
- The resource group ALREADY EXISTS -- do NOT recreate it.

### Discovery Workflow

1. List all resources in `{{RESOURCE_GROUP}}` to understand the deployment.
2. Identify the deployed Container App URLs/endpoints.
3. Identify supporting services (AI, database, storage, etc.).
4. Use discovered endpoints for validation testing.

**Discovery Commands:**

```bash
az resource list --resource-group {{RESOURCE_GROUP}} --output table
az containerapp list --resource-group {{RESOURCE_GROUP}} --output table
az containerapp show -g {{RESOURCE_GROUP}} -n {{BACKEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv
az containerapp show -g {{RESOURCE_GROUP}} -n {{FRONTEND_APP_NAME}} --query "properties.configuration.ingress.fqdn" -o tsv
```

### CLI Usage Restrictions -- MANDATORY

- Use `az cli` ONLY for inspection, discovery, and read-only operations.
- Do NOT use `az cli` for deploying code changes or managing application deployments.
- All code deployments MUST go through GitHub Actions.
- `az cli` may still be used to check logs, inspect configuration, and verify resource status.

---

## GitHub Actions Deployment -- CRITICAL

**Principle:** ALL code deployments to Azure MUST go through GitHub Actions CI/CD pipelines.

### Deployment Workflow

1. Make code changes locally.
2. Commit changes to the repository.
3. Push commits to the appropriate branch (typically `main`) to trigger GitHub Actions.
4. Monitor the GitHub Actions workflow run for success or failure.
5. Once the workflow completes successfully, the deployed Container Apps are updated.
6. Validate the deployed application using playwright-cli after the workflow finishes.

### Deployment Commands

```bash
git add <explicit file paths>   # never `git add .` -- it sweeps in untracked files
git commit -m "descriptive commit message"
git push origin main
```

### Monitoring Workflow

```bash
gh run list --limit 1
gh run watch
gh run view --log
gh run view --log-failed
```

### Post-Deployment Verification

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

### Rules -- MANDATORY

- **NEVER** deploy code changes using `az cli`, `az containerapp update`, or any direct Azure deployment command.
- **ALWAYS** use `git push` to trigger GitHub Actions for ALL deployments.
- Wait for the GitHub Actions workflow to complete before testing deployed changes.
- If the GitHub Actions workflow fails, debug the failure and push a fix -- do NOT bypass the pipeline.

---

## Autonomous Work Expectations -- CRITICAL

### Context Window Management

Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off.

### Completion Mandate -- ABSOLUTE

- **YOU CANNOT STOP** until EVERYTHING in `spec.md` is implemented and validated.
- **DO NOT** stop early -- work until EVERYTHING is FLESHED OUT COMPLETELY.
- Do NOT stop tasks due to token budget concerns.
- Complete tasks FULLY, even if end of budget is approaching.
- NEVER artificially stop any task early regardless of context remaining.

### Work Cycle

For EACH and EVERY feature in `spec.md`:

1. Validate against the DEPLOYED application using playwright-cli.
2. Debug any issues found.
3. Code and implement fixes/features as needed.
4. Commit and push to trigger GitHub Actions deployment.
5. Wait for GitHub Actions workflow to succeed (`gh run watch`).
6. Verify deployment health (backend, frontend, logs).
7. Re-validate until feature is fully functional.
8. Move to next feature -- repeat until ALL features complete.

---

## Development Workflow

### Initial Discovery

1. Discover all resources in `{{RESOURCE_GROUP}}`.
2. Identify and document deployed Container App URLs (backend + frontend).
3. Retrieve authentication credentials from Container App environment variables.
4. Verify backend health endpoint is accessible.
5. Verify authentication is enforced on all protected routes.
6. Verify the frontend login UI loads and functions correctly.
7. Confirm database connectivity, storage connectivity, and AI endpoint responsiveness.

### Code Changes

**Trigger:** After ANY code modification.

1. Commit and push changes to trigger GitHub Actions deployment.
2. Monitor GitHub Actions workflow until it completes successfully (`gh run watch`).
3. Verify deployment health (container logs, revision status).
4. Re-test functionality against deployed application after workflow succeeds.
5. Proceed only after verifying stability in production.

### Debugging

- **On failure:** Debug --> Fix --> `git push` (trigger GitHub Actions) --> `gh run watch` --> Wait for workflow success --> Confirm resolution on deployed app
- **Container logs:** `az containerapp logs show -g {{RESOURCE_GROUP}} -n <APP_NAME> --tail 200`
- **GitHub Actions logs:** `gh run view --log-failed`
- **Persistence:** Continue debugging and fixing until issue is COMPLETELY resolved in deployment.

---

## Validation & Testing

### Scope

- **Source:** ALL User Stories in `spec.md` -- EVERY SINGLE ONE must be validated
- **Target:** DEPLOYED application in `{{RESOURCE_GROUP}}`
- **Aspects:** Authentication security, functional correctness, data persistence, AI model integration, file handling, UI responsiveness

### Feature-Specific Validation

#### Authentication Security -- VALIDATE FIRST

- `/api/health` returns 200 without any credentials
- Every other backend route returns 401 when called without credentials
- Every other backend route returns 401 when called with wrong credentials
- Every other backend route returns correct response when called with valid credentials
- Frontend login page renders correctly
- Login with invalid credentials displays an error message; the user stays on the login page
- Login with valid credentials navigates to the main application
- All subsequent API requests from the frontend include proper auth headers
- WebSocket connections authenticate correctly (if applicable)
- Logout clears credentials and redirects to the login page
- After logout, navigating to a protected route redirects back to the login page

#### Application Features -- per spec.md

Validate every feature defined in `spec.md` systematically. For each feature:

- Verify the UI renders correctly
- Verify the backend API responds correctly
- Verify data persistence works
- Verify error handling is appropriate
- Verify edge cases are handled

### Method

**Tool:** playwright-cli against deployed Azure application

**Workflow:**

1. Discover and confirm deployed application URLs.
2. Retrieve authentication credentials.
3. Validate authentication security (unauthenticated = rejected, authenticated = granted, invalid = rejected).
4. Use playwright-cli to log in via the frontend login UI and test all features.
5. If issues found: debug, fix code, commit and push to trigger GitHub Actions.
6. Wait for GitHub Actions workflow to complete successfully (`gh run watch`).
7. Verify deployment health (container logs, revision status).
8. Re-validate with playwright-cli against deployed application.
9. Repeat until feature is FULLY functional.
10. Move to next feature.

### Completion Criteria

Work is **NOT** complete until:

- `/api/health` returns 200 without authentication
- All protected backend routes reject unauthenticated and invalid requests
- All protected backend routes return correct responses with valid credentials
- Frontend login UI works: invalid credentials show error, valid credentials grant access
- Logout clears credentials and prevents further access
- Every feature in `spec.md` is implemented in the deployed app
- Every feature passes playwright-cli validation against deployed URL
- Database connectivity and persistence are confirmed operational
- Storage connectivity is confirmed operational
- AI model endpoint is confirmed responsive
- UI renders properly on both large and small screens
- No bugs or blockers remain in production

---

## Execution Plan

### Initial Steps

1. Discover all resources in `{{RESOURCE_GROUP}}`.
2. Identify deployed Container App URLs (backend + frontend).
3. Retrieve authentication credentials from Container App environment variables.
4. Verify backend health and authentication enforcement via `curl`.
5. Verify frontend login UI via playwright-cli.
6. Confirm database, storage, and AI connectivity.
7. Begin systematic validation of all User Stories.

### Priorities

| Level | Priority                                                                                 |
| ----- | ---------------------------------------------------------------------------------------- |
| 1     | Discover deployed application in `{{RESOURCE_GROUP}}`                                    |
| 2     | Verify authentication is enforced on all protected routes                                |
| 3     | Verify frontend login UI works with valid and invalid credentials                        |
| 4     | Verify database, storage, and AI connectivity                                            |
| 5     | Verify WebSocket authentication (if applicable)                                          |
| 6     | Complete EVERYTHING in `spec.md` -- no exceptions                                        |
| 7     | Validate each feature with playwright-cli against deployed app                           |
| 8     | Debug and fix all issues immediately                                                     |
| 9     | Commit and push to trigger GitHub Actions after each code update                         |
| 10    | Wait for GitHub Actions success (`gh run watch`) before re-validating                    |
| 11    | DO NOT STOP until all User Stories are done                                              |

---

## Final Mandate -- ABSOLUTE

**YOU CANNOT STOP WORKING UNTIL:**

- Deployed application in `{{RESOURCE_GROUP}}` is discovered and accessible
- `/api/health` returns 200 without authentication
- All protected backend routes reject unauthenticated requests
- All protected backend routes reject invalid credentials
- Frontend login UI rejects invalid credentials with an error message
- Frontend login UI grants access with valid credentials
- Logout clears credentials and redirects to the login page
- Database connectivity is confirmed operational
- Storage connectivity is confirmed operational
- AI model endpoint is confirmed responsive
- Every User Story in `spec.md` is implemented in the deployed app
- Every feature is validated with playwright-cli against deployed URL
- Every bug is debugged and fixed in production
- The entire deployed application works end-to-end
- EVERYTHING is FLESHED OUT COMPLETELY

| Concern             | Directive                                                                                              |
| ------------------- | ------------------------------------------------------------------------------------------------------ |
| **AZURE RESOURCES** | ALL resources are ALREADY DEPLOYED in `{{RESOURCE_GROUP}}` -- verify, do not recreate                  |
| **DATABASE**        | {{AZURE_DB_TYPE}} is the production database -- ensure all CRUD and persistence work correctly          |
| **STORAGE**         | {{AZURE_STORAGE_TYPE}} for application files -- ensure upload, download, delete all work correctly      |
| **AI MODEL**        | `{{MODEL_NAME}}` via Azure AI Services -- verify connectivity and model functionality                   |
| **AUTH**            | {{DEPLOYED_AUTH_TYPE}} is MANDATORY -- verify all protected routes reject unauthenticated requests      |
| **DEPLOYMENT**      | ALL code changes deploy via GitHub Actions (`git push`) -- NEVER via `az cli` direct deployment         |

**DO NOT STOP EARLY. WORK CONTINUOUSLY UNTIL COMPLETE.**

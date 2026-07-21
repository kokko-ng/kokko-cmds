
# {{APP_NAME}} -- Local Validation & Testing Prompt

## Core Definitions

| ID               | Value                                                                                              |
| ---------------- | -------------------------------------------------------------------------------------------------- |
| `user_stories`   | All User Stories in `spec.md`                                                                      |
| `resource_group` | `{{RESOURCE_GROUP}}` (East US 2) -- **already provisioned**                                        |
| `ai_account`     | `{{AI_ACCOUNT_NAME}}` -- Azure AI Services account -- **already provisioned**                      |
| `deployment`     | `{{DEPLOYMENT_NAME}}` (model: {{MODEL_NAME}}, {{TPM}} TPM, GlobalStandard) -- **already deployed** |
| `model`          | `{{MODEL_NAME}}` via Azure AI Services                                                             |
| `api_endpoint`   | `{{API_ENDPOINT}}`                                                                                 |
| `database`       | {{LOCAL_DB_TYPE}} (local)                                                                          |
| `backend`        | {{BACKEND_FRAMEWORK}} on `{{BACKEND_URL}}`                                                         |
| `frontend`       | {{FRONTEND_FRAMEWORK}} on `{{FRONTEND_URL}}`                                                       |
| `storage`        | Local filesystem (`{{LOCAL_STORAGE_PATH}}`)                                                        |

---

## Primary Goal

Work autonomously to validate the application end-to-end per all features and requirements in `spec.md`. The application runs **locally** -- {{BACKEND_FRAMEWORK}} backend + {{FRONTEND_FRAMEWORK}} frontend -- with `{{MODEL_NAME}}` accessed via a **pre-provisioned** Azure AI Services endpoint in the `{{RESOURCE_GROUP}}` resource group. Resolve all remaining issues and validate until fully functional.

**YOU CANNOT STOP UNTIL EVERYTHING IN `spec.md` IS IMPLEMENTED AND VALIDATED.**

---

## Azure Resources -- Pre-Provisioned

**Principle:** The `{{RESOURCE_GROUP}}` resource group and all required Azure AI resources are **already provisioned**. Do NOT re-create them. Verify connectivity and use as-is.

### Provisioned Resources

| Resource           | Name                       | Details                                            |
| ------------------ | -------------------------- | -------------------------------------------------- |
| Resource Group     | `{{RESOURCE_GROUP}}`       | East US 2                                          |
| Azure AI Services  | `{{AI_ACCOUNT_NAME}}`      | Azure AI Services                                  |
| Model Deployment   | `{{DEPLOYMENT_NAME}}`      | {{MODEL_NAME}}, {{TPM}} TPM, GlobalStandard        |
| Endpoint           | `{{API_ENDPOINT_BASE}}`    | OpenAI-compatible                                  |

### Credential Storage

Credentials are stored in `backend/.env` (gitignored). The backend config loads `.env` automatically.

```
# backend/.env (gitignored -- already exists at backend root)
AZURE_OPENAI_ENDPOINT={{API_ENDPOINT_BASE}}
AZURE_OPENAI_API_KEY=<key>
AZURE_OPENAI_DEPLOYMENT={{DEPLOYMENT_NAME}}
```

### Verification Commands

If you need to verify the deployment is healthy:

```bash
az cognitiveservices account deployment show \
  --deployment-name {{DEPLOYMENT_NAME}} \
  -n {{AI_ACCOUNT_NAME}} \
  -g {{RESOURCE_GROUP}} \
| jq -r '.properties.provisioningState'
# Expected: "Succeeded"
```

If you need to retrieve the API key (e.g., `.env` is missing):

```bash
az cognitiveservices account keys list \
  -n {{AI_ACCOUNT_NAME}} \
  -g {{RESOURCE_GROUP}} \
| jq -r '.key1'
```

### Resource Group Constraint -- ABSOLUTE

- You are **STRICTLY RESTRICTED** to the resource group `{{RESOURCE_GROUP}}`. **NO OTHER RESOURCE GROUP MAY BE USED, REFERENCED, OR CREATED UNDER ANY CIRCUMSTANCES.**
- Every Azure resource you interact with MUST be inside `{{RESOURCE_GROUP}}`.
- If you discover resources in other resource groups, IGNORE THEM -- they are out of scope.
- All `az cli` commands MUST target `--resource-group {{RESOURCE_GROUP}}` or `-g {{RESOURCE_GROUP}}` explicitly.

### CLI Restrictions -- MANDATORY

- You MAY use `az cli` for inspection and read-only operations within `{{RESOURCE_GROUP}}`.
- **NEVER** create, use, or reference any resource group other than `{{RESOURCE_GROUP}}`.
- **NEVER** deploy application code to Azure -- the app runs locally only.
- **NEVER** delete the resource group, AI account, or model deployment.

### Troubleshooting

- **401/403 on API call:** Verify the API key in `backend/.env` matches `az cognitiveservices account keys list`. Use the `api-key` header.
- **Deployment shows non-`Succeeded` state:** Check provisioning status and wait. Do NOT delete and recreate.
- **`.env` missing:** Recreate it using the verification commands above to retrieve endpoint and key.

---

## Application Architecture -- Local Development

### Local Stack

- **Backend:** {{BACKEND_FRAMEWORK}} running locally via `{{BACKEND_START_COMMAND}}` on `{{BACKEND_URL}}`
- **Frontend:** {{FRONTEND_FRAMEWORK}} dev server via `{{FRONTEND_START_COMMAND}}` on `{{FRONTEND_URL}}`
- **Database:** {{LOCAL_DB_TYPE}} -- {{LOCAL_DB_DETAILS}}
- **Storage:** Local filesystem -- `{{LOCAL_STORAGE_PATH}}`
- **AI Model:** `{{MODEL_NAME}}` via Azure AI Services endpoint in `{{RESOURCE_GROUP}}` RG
- **Proxy:** Dev server proxies `/api` requests to backend

### Architecture Summary

| Component         | Location | Details                                                                            |
| ----------------- | -------- | ---------------------------------------------------------------------------------- |
| Backend           | Local    | `{{BACKEND_URL}}` -- {{BACKEND_START_COMMAND}}                                     |
| Frontend          | Local    | `{{FRONTEND_URL}}` -- {{FRONTEND_START_COMMAND}}                                   |
| Database          | Local    | {{LOCAL_DB_DETAILS}}                                                               |
| File storage      | Local    | `{{LOCAL_STORAGE_PATH}}`                                                           |
| AI Model          | Azure    | `{{RESOURCE_GROUP}}` RG, East US 2                                                 |

### Authentication

{{LOCAL_AUTH_DESCRIPTION}}

### Backend API Endpoints

| Method | Endpoint                         | Auth Required | Purpose                                |
| ------ | -------------------------------- | ------------- | -------------------------------------- |
| GET    | `/api/health`                    | No            | Health check                           |
{{API_ENDPOINTS_TABLE}}

---

## Environment Configuration

### Dependencies

**Backend:**

```bash
{{BACKEND_INSTALL_COMMANDS}}
```

**Frontend:**

```bash
{{FRONTEND_INSTALL_COMMANDS}}
```

### Backend `.env`

`backend/.env` (gitignored, already exists):

```
AZURE_OPENAI_ENDPOINT={{API_ENDPOINT_BASE}}
AZURE_OPENAI_API_KEY=<key>
AZURE_OPENAI_DEPLOYMENT={{DEPLOYMENT_NAME}}
{{ADDITIONAL_ENV_VARS}}
```

### Type Checking

Both backend and frontend MUST pass type checking with zero errors:

```bash
{{TYPE_CHECK_COMMAND}}
```

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

1. Validate against the LOCAL application using playwright-cli.
2. Debug any issues found.
3. Code and implement fixes/features as needed.
4. Restart the local servers if code changes require it.
5. Re-validate until feature is fully functional.
6. Move to next feature -- repeat until ALL features complete.

### Expectation

CONTINUE and DO NOT STOP until the entire local app is validated end-to-end. You are expected to work autonomously for a VERY LONG PERIOD OF TIME to complete this task.

The work is NOT complete until EVERY feature in `spec.md` is:

- Fully implemented in the local application
- Thoroughly validated with playwright-cli against local URLs
- Debugged and working correctly
- Integrated and stable

### Planning Approach

Be ambitious with task lists and planning -- context management allows for extensive work sessions. Break down ALL features comprehensively and work through EVERY SINGLE ONE without stopping.

---

## Development Workflow

### Initial Setup

1. Verify `backend/.env` exists with Azure AI credentials. If missing, retrieve the API key using `az cognitiveservices account keys list -n {{AI_ACCOUNT_NAME}} -g {{RESOURCE_GROUP}}`.
2. Install backend dependencies.
3. Install frontend dependencies.
4. Start the backend server.
5. Start the frontend dev server.
6. Verify both servers are running and the frontend can reach the backend API via `{{FRONTEND_URL}}/api/health`.
7. Verify authentication works (register, login, access protected routes).
8. Verify Azure AI connectivity by testing the AI integration.
9. Begin systematic validation of features.

### Code Changes

**Trigger:** After ANY code modification.

1. Save changes -- backend auto-reloads; frontend hot-reloads.
2. Re-test affected functionality against local application.
3. Proceed only after verifying stability locally.
4. Ensure type checking still passes after changes.

### Debugging

- **On failure:** Debug --> Fix --> Verify locally --> Confirm resolution
- **Backend errors:** Check backend server logs in terminal.
- **Frontend errors:** Check browser console and dev server output.
- **AI errors:** Verify `backend/.env` credentials; check Azure AI endpoint health via `az cognitiveservices account deployment show`.
- **Persistence:** Continue debugging and fixing until issue is COMPLETELY resolved.

---

## Validation & Testing

### Scope

- **Source:** ALL features and requirements in `spec.md` -- EVERY SINGLE ONE must be validated
- **Target:** LOCAL application (backend `{{BACKEND_URL}}`, frontend `{{FRONTEND_URL}}`)
- **Aspects:** Functional correctness, authentication flows, data persistence, AI model integration, file handling, UI responsiveness

### Feature-Specific Validation

#### Authentication

- Verify login with valid credentials succeeds
- Verify login with invalid credentials is rejected
- Verify protected endpoints reject unauthenticated requests
- Verify authenticated requests succeed
- Verify logout clears auth state

#### Application Features -- per spec.md

Validate every feature defined in `spec.md` systematically. For each feature:

- Verify the UI renders correctly
- Verify the backend API responds correctly
- Verify data persistence works
- Verify error handling is appropriate
- Verify edge cases are handled

#### UI & Responsiveness

- Navigation and layout render correctly
- Interactive elements respond appropriately
- Dark theme renders correctly (no white flashes, proper contrast) (if applicable)
- Responsive: layout adapts to mobile viewports
- Sign out clears auth state and redirects to login

### Method

**Tool:** playwright-cli against local application

**Workflow:**

1. Start local backend and frontend servers.
2. Use playwright-cli to test each feature against `{{FRONTEND_URL}}`.
3. If issues found: debug, fix code, servers auto-reload, re-validate.
4. Repeat until feature is FULLY functional.
5. Move to next feature.

### Completion Criteria

Work is **NOT** complete until:

- Every feature in `spec.md` is implemented in the local app
- Every feature passes playwright-cli validation against local URLs
- Authentication protects all sensitive endpoints
- AI model integration works end-to-end
- Data persistence works correctly
- UI renders properly on both large and small screens
- Type checking passes with zero errors
- No bugs or blockers remain
- All flows work end-to-end locally

---

## Specifications Compliance

**Source:** `spec.md` is the authoritative source -- ALL items must be completed.

**Refinement Guideline:** If specifications are unclear, refine them to be:

- Explicit and structured
- Consistent and agent-friendly
- While preserving original intent

---

## Execution Plan

### Initial Steps

1. Verify `backend/.env` exists with Azure credentials (retrieve key via `az cli` if missing).
2. Verify local development environment setup.
3. Install backend and frontend dependencies.
4. Start backend and frontend servers.
5. Verify application loads in browser at `{{FRONTEND_URL}}`.
6. Verify authentication flow works.
7. Test Azure AI connectivity through the application.
8. Begin systematic validation of all features.

### Approach

Decompose ALL features in `spec.md` into a comprehensive, ambitious task list. Work through EVERY SINGLE task without stopping until complete. Context management supports extensive planning -- be thorough and complete.

### Priorities

| Level | Priority                                                                                                    |
| ----- | ----------------------------------------------------------------------------------------------------------- |
| 1     | Verify `backend/.env` and Azure AI connectivity (resources are pre-provisioned in `{{RESOURCE_GROUP}}` RG)  |
| 2     | Verify local dev environment and server startup                                                             |
| 3     | Complete EVERYTHING in `spec.md` -- no exceptions                                                           |
| 4     | Validate each feature with playwright-cli against local app                                                 |
| 5     | Verify AI integration works end-to-end                                                                      |
| 6     | Verify data persistence and file handling                                                                   |
| 7     | Ensure type checking passes with zero errors                                                                |
| 8     | Debug and fix all issues immediately                                                                        |
| 9     | DO NOT STOP until all features are done                                                                     |

### Work Style

AUTONOMOUS execution WITHOUT STOPPING until ALL features are:

- Implemented completely in the local application
- Validated end-to-end with playwright-cli against local URLs
- Debugged and working correctly
- Integrated and stable

Work PERSISTENTLY for as long as needed. DO NOT stop early. EVERYTHING must be FLESHED OUT COMPLETELY before stopping.

---

## Final Mandate -- ABSOLUTE

**YOU CANNOT STOP WORKING UNTIL:**

- Azure AI connectivity is verified (pre-provisioned `{{RESOURCE_GROUP}}` RG with `{{AI_ACCOUNT_NAME}}` account and `{{DEPLOYMENT_NAME}}` deployment)
- `backend/.env` exists with valid Azure AI credentials
- Local backend and frontend are running and accessible
- Authentication works end-to-end
- Database is created with all required tables
- AI model integration works end-to-end
- Data persistence works correctly
- File handling works correctly
- UI renders properly on both large and small screens
- Type checking passes with zero errors
- Every feature in `spec.md` is implemented and validated
- Every bug is debugged and fixed
- The entire local application works end-to-end
- EVERYTHING is FLESHED OUT COMPLETELY

| Concern             | Directive                                                                                                                                         |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **AZURE RESOURCES** | Pre-provisioned in `{{RESOURCE_GROUP}}` RG (`{{AI_ACCOUNT_NAME}}` + `{{DEPLOYMENT_NAME}}`). Verify connectivity only. **NEVER use any other RG.** |
| **DATABASE**        | {{LOCAL_DB_TYPE}} -- ensure all CRUD and persistence work correctly                                                                               |
| **AI MODEL**        | `{{MODEL_NAME}}` via Azure AI Services -- verify connectivity and model functionality                                                             |
| **STORAGE**         | Local filesystem `{{LOCAL_STORAGE_PATH}}` -- ensure file operations work correctly                                                                |
| **RESPONSIVE**      | UI must render properly on large screens and mobile viewports                                                                                     |
| **TYPE CHECKING**   | Type checking MUST pass with zero errors                                                                                                          |
| **CODE CHANGES**    | Apply locally -- servers auto-reload -- no deployment pipeline needed                                                                             |

**DO NOT STOP EARLY. WORK CONTINUOUSLY UNTIL COMPLETE.**

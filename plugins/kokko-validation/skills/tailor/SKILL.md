---
name: tailor
description: Instantiate a generic validation/deployment master prompt for the current repo and save it to prompts/
argument-hint: "<local|deployed|azure-deploy|aesthetics> [hints, e.g. resource group name, app name]"
---

# Tailor Skill

Turn a generic master prompt template into a repo-specific prompt file.
The templates are deliberately generic — full of `{{PLACEHOLDER}}` tokens —
and the entire point is to modify them to fit THIS repo: fill every
placeholder from what the codebase actually contains, cut sections that do
not apply, and add repo-specific detail the template could not know.

## Templates

All in `${CLAUDE_PLUGIN_ROOT}/skills/tailor/references/`:

| Argument       | Template                 | Purpose                                              |
| -------------- | ------------------------ | ---------------------------------------------------- |
| `local`        | `local-validation.md`    | Validate the app end-to-end running locally          |
| `deployed`     | `deployed-validation.md` | Validate the deployed app end-to-end                 |
| `azure-deploy` | `azure-deploy.md`        | Deploy to Azure Container Apps with CI/CD            |
| `aesthetics`   | `aesthetics.md`          | Screenshot-driven visual defect hunt and fix         |

## Workflow

### 1. Inspect the repo

Determine, from the code and configuration (not by guessing):

- App name, backend framework and start command, frontend framework and
  start command, local URLs and ports
- Database type (local and/or cloud), storage paths/accounts
- Auth mechanism (local and deployed, if distinguishable)
- Type-check / lint / test commands
- API endpoints (route files), protected vs public routes
- Whether `spec.md` exists (several templates treat it as the source of
  truth — if it is missing, note that `/spec` can generate it)
- Existing Azure config: workflow files, bicep/terraform, `.env.example`,
  CLAUDE.md notes, existing `prompts/*.md`

### 2. Resolve placeholders

Fill EVERY `{{PLACEHOLDER}}`. Sources, in order: user-supplied hints in
`$ARGUMENTS`, repo inspection, then existing Azure resources discovered
read-only via `az cli` (never create anything while tailoring). If a value
is genuinely unknowable (e.g. a resource group that does not exist yet and
was not named in the hints), ask the user rather than inventing one.

No `{{...}}` token may remain in the output file.

### 3. Adapt, don't just substitute

- Delete sections that do not apply (e.g. WebSocket auth when the app has
  no WebSocket; register page when there is no registration)
- Expand generics with repo detail: real endpoint tables, real protected
  route lists, real desktop/mobile page states for aesthetics passes
- Keep the template's autonomous-work framing and completion criteria
- Keep browser automation on the **Playwright CLI**, never the Playwright
  MCP server: preserve each template's "Browser Automation -- Playwright CLI"
  section and its `playwright-cli` references. Do not rewrite them to use
  `mcp__playwright__*` / `browser_*` tools
- Keep git usage safe: staging must name explicit file paths (never
  `git add .` or bare directory adds); no history rewrites; nothing force

### 4. Save

Write to `prompts/<template>-<qualifier>.md` in the repo root (create
`prompts/` if needed), e.g. `prompts/local-validation.md`,
`prompts/deployed-validation-entra.md`. If a file with the same purpose
already exists, update it in place rather than creating a near-duplicate.

Report: the file written, every placeholder value chosen and its source,
sections removed or added, and any values that need the user's
confirmation before the prompt is run.

## Running the result

Tailored prompts are run directly (paste or `@prompts/<file>.md`) or in
repeated fresh-context passes via `/kokko-janitor:multipass` from the
kokko-janitor plugin (e.g. `2 passes of prompts/deployed-validation.md`).

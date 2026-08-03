---
name: tailor
description: Instantiate a generic validation/deployment master prompt for the current repo and save it to prompts/. Specify which template to tailor (local, deployed, azure-deploy, or aesthetics) plus optional hints such as the resource group or app name.
---

# Tailor Skill

Turn a generic master prompt template into a repo-specific prompt file.
The templates are deliberately generic — full of `{{PLACEHOLDER}}` tokens
and optional blocks — and the entire point is to modify them to fit THIS
repo: fill every placeholder from what the codebase actually contains,
cut blocks that do not apply, and add repo-specific detail the template
could not know.

## Templates

All in `${CLAUDE_PLUGIN_ROOT}/skills/tailor/references/`. Each template
starts with a `TAILORING NOTES` comment: the full placeholder manifest
(with the expected source for each value) plus its optional blocks and
variants. Read it first — it is the authoritative checklist for that
template.

| Argument       | Template                 | Purpose                                                 |
| -------------- | ------------------------ | ------------------------------------------------------- |
| `local`        | `local-validation.md`    | Validate the local app with deterministic tests         |
| `deployed`     | `deployed-validation.md` | Validate the deployed app with deterministic tests      |
| `azure-deploy` | `azure-deploy.md`        | Deploy to Azure Container Apps with CI/CD               |
| `aesthetics`   | `aesthetics.md`          | Screenshot-driven visual defect hunt and fix            |

## Workflow

### 1. Resolve the argument

The first word of `$ARGUMENTS` selects the template; the remaining words
are hints (resource group, app name, auth style, ...). If no template is
named, or the word matches none of the four, ask which one to use
(AskUserQuestion, one option per template) instead of guessing.

### 2. Check for spec.md

`local`, `deployed`, and `azure-deploy` treat `spec.md` as the source of
truth for what to validate. If it is missing, ask before continuing:
generate it now with `/spec` (recommended), proceed anyway, or abort.

### 3. Inspect the repo

Determine, from the code and configuration (not by guessing):

- App name; backend and frontend frameworks, directories, start
  commands, install commands, local URLs and ports
- Database type (local and/or cloud), storage paths/accounts
- Auth mechanism (local and deployed, if distinguishable)
- Health endpoint route; API endpoints (route files), protected vs
  public routes
- Type-check / lint / test commands — confirm they actually exist in
  package.json / pyproject / Makefile; do not invent them
- Test tooling for the deterministic-test placeholders (`local`, `deployed`,
  `azure-deploy`): which runners actually exist (pytest, vitest, jest, ...),
  where the suites live, and the exact commands that run them. If the repo
  has no test setup yet, pick the stack's conventional tooling and fill the
  placeholders with the commands the suite will use once the prompt creates
  it — the templates make creating a missing suite part of the prompt's job
- `aesthetics` only: which browser automation tool is actually available
  (playwright-cli) for its `{{BROWSER_TOOL}}` placeholder
- Existing Azure config: workflow files, bicep/terraform, `.env.example`,
  CLAUDE.md notes, existing `prompts/*.md`

### 4. Resolve placeholders

Fill EVERY placeholder in the template's manifest. Sources, in order:
user-supplied hints in `$ARGUMENTS`, repo inspection, then existing Azure
resources discovered read-only via `az cli` — never create anything while
tailoring (e.g. fill `{{AZURE_REGION}}` from
`az group show --name <rg> --query location`). If a value is genuinely
unknowable (e.g. a resource group that does not exist yet and was not
named in the hints), ask the user rather than inventing one.

Never write secret VALUES into the output file. Resource and account
names are fine; API keys, passwords, and connection strings are not —
the tailored prompt gets committed to the repo. Where the template shows
a secret, keep the retrieval command, not the retrieved value.

### 5. Adapt, don't just substitute

- Delete optional blocks that do not apply (`<!-- OPTIONAL: name -->` ...
  `<!-- END OPTIONAL: name -->`) together with every stray line tagged
  `[name]`; strip the `[name]` tags from lines you keep. Where a template
  offers variants (e.g. the deployed template's auth variants), keep
  exactly one and delete the rest.
- Expand generics with repo detail: real endpoint tables, real protected
  route lists, real desktop/mobile page states for aesthetics passes.
- Keep the template's autonomous-work framing, progress-file mechanism,
  blocker rules, and completion checklist.
- Keep validation deterministic in `local`, `deployed`, and `azure-deploy`
  outputs: preserve each template's "Deterministic Testing" section, its
  test-command placeholders, and the spec-coverage check. Never rewrite
  validation into agent-driven browsing — no ad-hoc playwright-cli driving,
  no Playwright MCP server or `mcp__playwright__*` / `browser_*` tools, no
  judging outcomes from screenshots.
- `aesthetics` is screenshot-driven by design: keep its browser automation
  on the **Playwright CLI**, never the Playwright MCP server — preserve its
  "Browser Automation -- Playwright CLI" section and its `playwright-cli`
  references.
- Keep git usage safe: staging must name explicit file paths (never
  `git add .` or bare directory adds); no history rewrites; nothing force.

### 6. Save

Write to `prompts/<template>-<qualifier>.md` in the repo root (create
`prompts/` if needed), e.g. `prompts/local-validation.md`,
`prompts/deployed-validation-entra.md`. Fill `{{PROGRESS_FILE}}` with the
output path plus a `-progress` suffix (e.g.
`prompts/local-validation-progress.md`). If a file with the same purpose
already exists, update it in place rather than creating a near-duplicate.

Start the file with a short generation-header comment: source template,
date, and a table of every placeholder value chosen — it makes future
re-tailoring a diff instead of a redo.

### 7. Verify the output

Mechanical checks before reporting — all must be clean:

- `grep -n '{{' prompts/<file>.md` returns nothing (no unresolved
  placeholders)
- Grepping for `TAILORING NOTES`, `OPTIONAL:`, `AUTH VARIANT`, and each
  `[tag]` named in the template's manifest returns nothing (no template
  scaffolding left)
- Every command the prompt tells its agent to run exists in this repo:
  the type-check script is defined, the start commands and directories
  are real, referenced routes exist
- No secret values anywhere in the file

### 8. Report

Report: the file written, every placeholder value chosen and its source,
blocks and variants removed or kept, sections expanded, and any values
that need the user's confirmation before the prompt is run.

## Running the result

Tailored prompts are run directly (paste or `@prompts/<file>.md`) or in
repeated fresh-context passes via `/kokko-janitor:multipass` from the
kokko-janitor plugin (e.g. `2 passes of prompts/deployed-validation.md`).
Each pass resumes from the prompt's progress file, so completed items are
skipped and blocked ones get revisited.

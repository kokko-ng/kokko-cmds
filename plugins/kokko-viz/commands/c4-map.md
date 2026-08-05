---
description: Generate a hierarchical C4 architecture map (context/containers/components) from a codebase.
argument-hint: '[target-directory]'
allowed-tools: Task, Bash, Read, Write, Glob, Grep
---

# C4 Architecture Mapping

Map the codebase architecture as a hierarchical C4 model
(Context -> Containers -> Components). No existing model required.
`$1`, when given, is the directory to map (default when empty: the current
project root) — scope every search to it and state it in every phase prompt
below.

## Orchestration

```text
Phase 1: Context -> Phase 2: Containers -> Phase 3: Components ->
Phase 4: Synthesis -> Phase 5: Files
```

Each level depends on the previous. Execute sequentially, passing outputs
forward.

**Subagents cannot read this plugin's files.** Whenever a phase prompt below
cites a `c4-templates.md#...` anchor, read that section yourself first and
paste the schema or template into the Task prompt you spawn — a bare anchor
citation gives the subagent nothing to follow, and phases then invent
mismatched shapes that Phase 4 has to reconcile.

The Task blocks below are pseudo-code. Do not pin model names in them —
model ids go stale; inherit the session model unless a step is marked
mechanical, where a smaller/faster model is fine if the harness supports
per-Task selection.

**Read the `c4` skill first:** `${CLAUDE_PLUGIN_ROOT}/skills/c4/SKILL.md`. It
holds the authoring rules every generated document must follow — mandatory
source-file hyperlinks and the ban on validation report files — and indexes the
shared templates.

Templates and schemas live at:
!`echo "${CLAUDE_PLUGIN_ROOT}/skills/c4/references/c4-templates.md"`

Read the relevant section of that file whenever a step below cites a
`c4-templates.md#...` anchor (if the path above is empty, locate the file with
Glob: `**/kokko-viz/skills/c4/references/c4-templates.md` under
`~/.claude/plugins/`). Output structure: see `c4-templates.md#output-structure`.

---

## Phase 1: System Context

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Map C4 system context"
  prompt: |
    Map SYSTEM CONTEXT level (C4 Level 1).

    GOALS:
    1. Identify system name, create kebab-case SYSTEM_ID
    2. Define system boundary and purpose
    3. Find actors (auth patterns, API consumers, user roles)
    4. Map external systems (SDK imports, env vars, HTTP clients)
    5. Identify preliminary containers (deployable units)

    SEARCH:
    - Glob: **/*.env*, **/pyproject.toml, **/package.json
    - Grep: "requests\.", "httpx\.", "import.*azure", "import.*aws"
    - Check docker-compose.yml for external services

    OUTPUT: JSON matching the schema below
    <paste the c4-templates.md#context-phase-output schema here before spawning>
    Include C4-PlantUML context diagram
```

Wait for Phase 1. Store: `SYSTEM_ID`, `EXTERNAL_SYSTEMS`, `PRELIMINARY_CONTAINERS`.

---

## Phase 2: Containers

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Map C4 containers"
  prompt: |
    Map CONTAINER level (C4 Level 2).

    CONTEXT FROM PHASE 1:
    - SYSTEM_ID: <insert>
    - EXTERNAL_SYSTEMS: <insert>
    - PRELIMINARY_CONTAINERS: <insert>

    GOALS:
    For each preliminary container:
    1. Validate it's a distinct deployable unit
    2. Identify technology stack (framework, runtime)
    3. Map inter-container communication (protocols)
    4. Identify preliminary components within each
    5. Validate external system boundaries

    SEARCH:
    - Glob: **/Dockerfile, **/docker-compose.yml, **/main.py
    - Grep: "FastAPI", "Express", "Flask"
    - Analyze directory structure per container

    OUTPUT: JSON matching the schema below
    <paste the c4-templates.md#container-phase-output schema here before spawning>
    Include C4-PlantUML container diagram
```

Wait for Phase 2. Store: `CONTAINERS` (with `PRELIMINARY_COMPONENTS`),
`CONTAINER_RELATIONSHIPS`.

---

## Phase 3: Components

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Map C4 components"
  prompt: |
    Map COMPONENT level (C4 Level 3).

    CONTEXT FROM PHASE 2:
    - SYSTEM_ID: <insert>
    - CONTAINERS: <insert full array>

    GOALS:
    For each component in each container:
    1. Validate coherent module with clear responsibility
    2. Identify internal dependencies (same container)
    3. Identify cross-container dependencies
    4. Map component interfaces/contracts

    SEARCH:
    - Read __init__.py or index.ts for exports
    - Grep: "class \w+"
    - Analyze import statements

    OUTPUT: JSON matching the schema below
    <paste the c4-templates.md#component-phase-output schema here before spawning>
    Include C4-PlantUML component diagrams (one per container)
```

Wait for Phase 3. Store: `COMPONENTS_BY_CONTAINER`.

---

## Phase 4: Synthesis

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Synthesize C4 model"
  prompt: |
    Validate cross-level consistency before file generation.

    PHASE OUTPUTS:
    - Phase 1 (Context): <insert>
    - Phase 2 (Containers): <insert>
    - Phase 3 (Components): <insert>

    VALIDATION CHECKS:
    1. ID Consistency: Every element traces to parent level
    2. Relationship Consistency: Dependencies match imports
    3. Coverage Gaps: Missing elements, empty containers
    4. Naming Conflicts: Duplicate IDs, invalid folder names
    5. Structural Issues: Empty containers, deep nesting

    OUTPUT:
    {
      "VALIDATION_PASSED": true/false,
      "ISSUES": [<issues in the schema below>],
    <paste the c4-templates.md#validation-issue-schema definition here before spawning>
      "FINAL_STRUCTURE": {corrected model}
    }
```

If validation fails with errors, report to user before proceeding.

---

## Phase 5: File Generation

Using `FINAL_STRUCTURE` from Phase 4.

**Source links are mandatory:** every source file, module, or code element
named in any generated `.md` must be a markdown hyperlink to the actual file,
per `c4-templates.md#source-file-links` — repo-relative so it resolves on
GitHub. Verify each link target exists before writing it.

### Step 0: Provision the C4-PlantUML Library

The four library files ship with this plugin — copy them in; no network
access needed:

```bash
mkdir -p codemap/.c4-plantuml
cp "${CLAUDE_PLUGIN_ROOT}/skills/c4/assets/c4-plantuml/"*.puml codemap/.c4-plantuml/
```

Fallback only if the bundled copies are missing (older plugin install):

```bash
BASE_URL="https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master"
for f in C4 C4_Context C4_Container C4_Component; do
  [ -f codemap/.c4-plantuml/$f.puml ] || \
    curl -sL -o codemap/.c4-plantuml/$f.puml "$BASE_URL/$f.puml"
done
```

### Step 1: Create Folders

```bash
SYSTEM_ID="<from FINAL_STRUCTURE>"
mkdir -p codemap/$SYSTEM_ID/containers
for CONTAINER_ID in <containers>; do
  mkdir -p codemap/$SYSTEM_ID/containers/$CONTAINER_ID/components
  for COMPONENT_ID in <components>; do
    mkdir -p codemap/$SYSTEM_ID/containers/$CONTAINER_ID/components/$COMPONENT_ID
  done
done
```

### Step 2: Write Files

Use templates from the reference file's `#markdown-templates` section:

| Level | Files |
| ----- | ----- |
| System | `context.puml`, `context.md` |
| Container | `container.puml`, `container.md` |
| Component | `component.puml`, `component.md` |

Each markdown file must include a parent navigation link, a drill-down table
to children, and a `<!-- Last updated: YYYY-MM-DD -->` timestamp.

### Step 3: Generate PNGs

```bash
find codemap -name "*.puml" ! -path "*/\.c4-plantuml/*" \
  -exec plantuml -DRELATIVE_INCLUDE="." -tpng {} \;
```

### Step 4: Write README

Create `codemap/README.md` with entry point to `<system-id>/context.md`.

### Step 5: Confirm

```bash
find codemap -type f | sort
```

---

## Output Summary

```markdown
# C4 Mapping Complete

## System: <system-id>

## Structure Generated
- Context level: 1 diagram
- Containers: X containers
- Components: Y components

## Files Created
- Total files: N (PlantUML: X, Markdown: Y, PNG: Z)

## Entry Point
`codemap/<system-id>/context.md`

## Validation
- Status: PASSED/FAILED
- Issues: [list if any]
```

If any phase fails, report it and do not proceed to dependent phases.

---
disable-model-invocation: true
---

# C4 Architecture Mapping

Map the codebase architecture using a hierarchical C4 model (Context -> Containers -> Components).

## Arguments

Usage: `/c4-map [target-directory]`

- `target-directory` - Directory to analyze (default: current working directory)

If `$ARGUMENTS` is provided, use it as the target directory to analyze.

## Prerequisites

A codebase to analyze. No existing C4 model required - this command generates the initial map.

## Orchestration

```
Phase 1: Context ──> Phase 2: Containers ──> Phase 3: Components ──> Phase 4: Synthesis ──> Phase 5: Files
```

Each level depends on outputs from the previous level. Execute sequentially, passing outputs forward.

**Output structure:** See [c4-templates.md](./c4-templates.md#output-structure)

---

## Phase 1: System Context

```
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

    OUTPUT: JSON per c4-templates.md#context-phase-output
    Include C4-PlantUML context diagram
```

**WAIT for Phase 1 to complete.**

Store: `SYSTEM_ID`, `EXTERNAL_SYSTEMS`, `PRELIMINARY_CONTAINERS`

---

## Phase 2: Containers

```
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

    OUTPUT: JSON per c4-templates.md#container-phase-output
    Include C4-PlantUML container diagram
```

**WAIT for Phase 2 to complete.**

Store: `CONTAINERS` with `PRELIMINARY_COMPONENTS`, `CONTAINER_RELATIONSHIPS`

---

## Phase 3: Components

```
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

    OUTPUT: JSON per c4-templates.md#component-phase-output
    Include C4-PlantUML component diagrams (one per container)
```

**WAIT for Phase 3 to complete.**

Store: `COMPONENTS_BY_CONTAINER`

---

## Phase 4: Synthesis

```
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
      "ISSUES": [<per c4-templates.md#validation-issue-schema>],
      "FINAL_STRUCTURE": {corrected model}
    }
```

**If validation fails with errors, report to user before proceeding.**

---

## Phase 5: File Generation

Using `FINAL_STRUCTURE` from Phase 4:

### Step 0: Download C4-PlantUML Library

Download the C4-PlantUML library files if not already present:

```bash
mkdir -p codemap/.c4-plantuml

# Download only if files don't exist
[ -f codemap/.c4-plantuml/C4.puml ] || curl -sL -o codemap/.c4-plantuml/C4.puml https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4.puml
[ -f codemap/.c4-plantuml/C4_Context.puml ] || curl -sL -o codemap/.c4-plantuml/C4_Context.puml https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml
[ -f codemap/.c4-plantuml/C4_Container.puml ] || curl -sL -o codemap/.c4-plantuml/C4_Container.puml https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml
[ -f codemap/.c4-plantuml/C4_Component.puml ] || curl -sL -o codemap/.c4-plantuml/C4_Component.puml https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml
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

Use templates from [c4-templates.md](./c4-templates.md#markdown-templates):

| Level | Files |
|-------|-------|
| System | `context.puml`, `context.md` |
| Container | `container.puml`, `container.md` |
| Component | `component.puml`, `component.md` |

Each markdown file must include:
- Parent navigation link
- Drill-down table to children
- `<!-- Last updated: YYYY-MM-DD -->` timestamp

### Step 3: Generate PNGs

```bash
find codemap -name "*.puml" ! -path "*/\.c4-plantuml/*" -exec plantuml -DRELATIVE_INCLUDE="." -tpng {} \;
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
- Total files: N
- PlantUML diagrams: X
- Markdown docs: Y
- PNG images: Z

## Entry Point
`codemap/<system-id>/context.md`

## Validation
- Status: PASSED/FAILED
- Issues: [list if any]
```

---

## Error Handling

See [c4-templates.md](./c4-templates.md#error-handling)

- If any phase fails: Report failure, do not proceed to dependent phases
- If Phase 4 validation fails: List errors, ask user to proceed or fix

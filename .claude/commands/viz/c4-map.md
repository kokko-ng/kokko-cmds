# C4 Architecture Mapping

Map the codebase architecture using a hierarchical C4 model (Context -> Containers -> Components -> Code).

## Orchestration Strategy

This command uses **multi-phase sequential orchestration** because each C4 level depends on outputs from the previous level:

```
Phase 1: Context (foundation) ─────────────────────────────────────────────┐
                                                                           │
Phase 2: Containers (receives SYSTEM_ID, external systems from Phase 1) ───┤
                                                                           │
Phase 3: Components (receives container IDs, boundaries from Phase 2) ─────┤
                                                                           │
Phase 4: Code (receives component IDs, key classes from Phase 3) ──────────┤
                                                                           │
Phase 5: Synthesis (receives ALL outputs, checks cross-level consistency) ─┘
```

**Why sequential?** Each level requires context from previous levels:
- Containers need SYSTEM_ID for folder naming and external system boundaries
- Components need container IDs to know where they belong
- Code needs component IDs and key class hints from component analysis
- Synthesis needs all outputs to find inconsistencies

## Hierarchical Output Structure

```
codemap/
└── <system-id>/                    # Level 1: System Context
    ├── context.puml                # Context diagram
    ├── context.md                  # Context documentation
    └── containers/                 # Level 2: Containers
        ├── <container-1>/
        │   ├── container.puml
        │   ├── container.md
        │   └── components/         # Level 3: Components
        │       ├── <component-a>/
        │       │   ├── component.puml
        │       │   ├── component.md
        │       │   └── code/       # Level 4: Code
        │       │       ├── classes.puml
        │       │       └── classes.md
        │       └── <component-b>/
        │           └── ...
        └── <container-2>/
            └── ...
```

## Instructions

Execute phases sequentially, passing outputs forward to dependent phases.

---

## PHASE 1: System Context (Foundation)

This phase establishes the foundation. All subsequent phases depend on its output.

```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Map C4 system context"
  prompt: |
    TASK: Map the SYSTEM CONTEXT level (C4 Level 1) of this codebase.

    This is the ROOT of the C4 hierarchy. Your output will be passed to subsequent
    phases, so be precise with identifiers.

    EXPLORATION GOALS:
    1. Identify the system name and create a kebab-case identifier
       - Read pyproject.toml, package.json, or README for project name
       - Example: "ingenious-agent-framework" -> SYSTEM_ID
    2. Define the system boundary - what this software system does
    3. Find all users/actors:
       - Authentication/authorization code patterns
       - API consumer documentation
       - User role definitions
    4. Map external systems:
       - HTTP clients (requests, httpx, axios, fetch)
       - SDK imports (azure, aws, stripe, etc.)
       - Environment variables for external URLs/keys
       - Database connections to external DBs
    5. Identify HIGH-LEVEL containers (deployable units):
       - You're not analyzing containers in depth yet
       - Just identify what will become container folders

    SEARCH STRATEGY:
    - Glob: **/*.env*, **/config.*, **/settings.*, **/pyproject.toml
    - Grep: "requests\.", "httpx\.", "import.*azure", "import.*aws"
    - Check docker-compose.yml for external service dependencies
    - Look for main entry points to understand deployment units

    OUTPUT FORMAT (CRITICAL - this format is consumed by Phase 2):
    ```json
    {
      "SYSTEM_ID": "kebab-case-identifier",
      "SYSTEM_NAME": "Human Readable Name",
      "SYSTEM_DESCRIPTION": "One paragraph description",
      "EXTERNAL_SYSTEMS": [
        {"id": "azure-openai", "name": "Azure OpenAI", "type": "AI Service", "evidence": "file:line"}
      ],
      "ACTORS": [
        {"id": "api-user", "name": "API User", "description": "External system consuming API"}
      ],
      "PRELIMINARY_CONTAINERS": [
        {"id": "api-server", "name": "API Server", "type": "Application"},
        {"id": "database", "name": "Database", "type": "Database"}
      ]
    }
    ```

    Also provide:
    - C4-PlantUML Context diagram
    - List of evidence files examined
```

**WAIT for Phase 1 to complete before proceeding to Phase 2.**

Store Phase 1 output in memory. Extract:
- `SYSTEM_ID` - used for folder creation
- `EXTERNAL_SYSTEMS` - passed to container phase for boundary validation
- `PRELIMINARY_CONTAINERS` - passed to container phase for detailed analysis

---

## PHASE 2: Containers (Depends on Phase 1)

This phase drills into deployable units. Receives context from Phase 1.

```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Map C4 containers"
  prompt: |
    TASK: Map the CONTAINER level (C4 Level 2) of this codebase.

    CONTEXT FROM PHASE 1 (use these values):
    - SYSTEM_ID: <insert from Phase 1>
    - SYSTEM_NAME: <insert from Phase 1>
    - EXTERNAL_SYSTEMS: <insert array from Phase 1>
    - PRELIMINARY_CONTAINERS: <insert array from Phase 1>

    Your job is to analyze each preliminary container in detail and identify
    what components they contain.

    EXPLORATION GOALS:
    For each container in PRELIMINARY_CONTAINERS:
    1. Validate it's actually a distinct deployable unit
    2. Identify its technology stack (framework, runtime)
    3. Map inter-container communication:
       - Which containers talk to which?
       - What protocols? (HTTP, SQL, gRPC, message queue)
    4. Identify PRELIMINARY COMPONENTS within each container:
       - Major modules/packages
       - Don't analyze component internals yet
    5. Validate boundaries with EXTERNAL_SYSTEMS:
       - Which containers call which external systems?

    SEARCH STRATEGY:
    - Glob: **/Dockerfile, **/docker-compose.yml, **/main.py, **/app.py
    - For each preliminary container, analyze its directory structure
    - Grep for server setup: "FastAPI", "Express", "Flask"
    - Find inter-service communication: queue consumers, HTTP clients

    OUTPUT FORMAT (CRITICAL - consumed by Phase 3):
    ```json
    {
      "SYSTEM_ID": "<from Phase 1>",
      "CONTAINERS": [
        {
          "id": "api-server",
          "name": "API Server",
          "technology": "FastAPI",
          "description": "Handles HTTP requests",
          "source_path": "ingenious/",
          "external_deps": ["azure-openai", "azure-search"],
          "container_deps": ["chat-database"],
          "PRELIMINARY_COMPONENTS": [
            {"id": "auth", "name": "Authentication", "path": "ingenious/auth"},
            {"id": "chat-services", "name": "Chat Services", "path": "ingenious/services/chat_services"}
          ]
        }
      ],
      "CONTAINER_RELATIONSHIPS": [
        {"from": "api-server", "to": "chat-database", "protocol": "SQL", "description": "Persists data"}
      ]
    }
    ```

    Also provide:
    - C4-PlantUML Container diagram (showing all containers)
    - Individual container diagrams showing relationships
```

**WAIT for Phase 2 to complete before proceeding to Phase 3.**

Store Phase 2 output. Extract:
- `CONTAINERS` array with nested `PRELIMINARY_COMPONENTS`
- `CONTAINER_RELATIONSHIPS` for cross-referencing

---

## PHASE 3: Components (Depends on Phase 2)

This phase analyzes module structure within containers. Receives container context.

```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Map C4 components"
  prompt: |
    TASK: Map the COMPONENT level (C4 Level 3) of this codebase.

    CONTEXT FROM PHASE 2 (use these values):
    - SYSTEM_ID: <insert from Phase 2>
    - CONTAINERS: <insert full array from Phase 2>

    For each container, analyze its PRELIMINARY_COMPONENTS in detail.

    EXPLORATION GOALS:
    For each component in each container:
    1. Validate it's a coherent module with clear responsibility
    2. Identify internal dependencies (within same container)
    3. Identify cross-container dependencies
    4. List KEY CLASSES that deserve Level 4 documentation:
       - Core business logic classes
       - Important patterns (Repository, Factory, Service)
       - NOT every utility class
    5. Map component interfaces/contracts

    SEARCH STRATEGY:
    For each component path:
    - Read __init__.py or index.ts for exports
    - Grep for class definitions: "class \w+"
    - Analyze import statements for dependencies
    - Find interface/protocol definitions

    OUTPUT FORMAT (CRITICAL - consumed by Phase 4):
    ```json
    {
      "SYSTEM_ID": "<from context>",
      "COMPONENTS_BY_CONTAINER": {
        "api-server": [
          {
            "id": "auth",
            "name": "Authentication Module",
            "parent_container": "api-server",
            "source_path": "ingenious/auth",
            "responsibility": "JWT and Basic auth handling",
            "internal_deps": ["config", "logging"],
            "cross_container_deps": [],
            "KEY_CLASSES": [
              {"name": "JWTHandler", "file": "ingenious/auth/jwt.py", "importance": "core"},
              {"name": "BasicAuthMiddleware", "file": "ingenious/auth/middleware.py", "importance": "core"}
            ]
          }
        ]
      },
      "COMPONENT_RELATIONSHIPS": [
        {"from": "auth", "to": "config", "type": "internal", "container": "api-server"},
        {"from": "chat-services", "to": "chat-database", "type": "cross-container"}
      ]
    }
    ```

    Also provide:
    - C4-PlantUML Component diagrams (one per container)
    - Module dependency matrix
```

**WAIT for Phase 3 to complete before proceeding to Phase 4.**

Store Phase 3 output. Extract:
- `COMPONENTS_BY_CONTAINER` with nested `KEY_CLASSES`
- `COMPONENT_RELATIONSHIPS`

---

## PHASE 4: Code (Depends on Phase 3)

This phase analyzes key classes. Receives component context with class hints.

```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Map C4 code structure"
  prompt: |
    TASK: Map the CODE level (C4 Level 4) of this codebase.

    CONTEXT FROM PHASE 3 (use these values):
    - SYSTEM_ID: <insert from context>
    - COMPONENTS_BY_CONTAINER: <insert full structure from Phase 3>

    For each component, analyze its KEY_CLASSES in detail.
    Do NOT document every class - only those marked in KEY_CLASSES.

    EXPLORATION GOALS:
    For each KEY_CLASS in each component:
    1. Read the actual class implementation
    2. Document:
       - Public methods and their purposes
       - Key attributes/properties
       - Class relationships (inheritance, composition)
    3. Identify design patterns:
       - Repository, Factory, Strategy, Observer, etc.
    4. Map class hierarchies within component

    SEARCH STRATEGY:
    For each KEY_CLASS:
    - Read the file at the specified path
    - Grep for method definitions
    - Analyze inheritance: "class X(Base)", "extends"
    - Find pattern implementations

    OUTPUT FORMAT:
    ```json
    {
      "SYSTEM_ID": "<from context>",
      "CODE_BY_COMPONENT": {
        "api-server": {
          "auth": {
            "component_id": "auth",
            "container_id": "api-server",
            "classes": [
              {
                "name": "JWTHandler",
                "file": "ingenious/auth/jwt.py:15",
                "purpose": "Creates and validates JWT tokens",
                "methods": ["validate_token", "create_token", "decode_payload"],
                "inherits": null,
                "pattern": "Factory"
              }
            ],
            "patterns_found": ["Factory", "Middleware"],
            "class_relationships": [
              {"from": "BasicAuthMiddleware", "to": "JWTHandler", "type": "uses"}
            ]
          }
        }
      }
    }
    ```

    Also provide:
    - PlantUML class diagrams for each component (only for components with KEY_CLASSES)
    - Design pattern summary
```

**WAIT for Phase 4 to complete before proceeding to Phase 5.**

---

## PHASE 5: Synthesis and Cross-Validation

This phase receives ALL outputs and checks for consistency across levels.

```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Synthesize C4 model"
  prompt: |
    TASK: Validate cross-level consistency of the C4 model.

    You have outputs from all 4 phases. Your job is to find inconsistencies,
    gaps, and issues BEFORE writing files.

    PHASE OUTPUTS TO VALIDATE:
    - Phase 1 (Context): <insert full output>
    - Phase 2 (Containers): <insert full output>
    - Phase 3 (Components): <insert full output>
    - Phase 4 (Code): <insert full output>

    VALIDATION CHECKS:

    1. ID CONSISTENCY:
       - Every container in Phase 2 should trace to Phase 1 PRELIMINARY_CONTAINERS
       - Every component in Phase 3 should trace to Phase 2 PRELIMINARY_COMPONENTS
       - Every class in Phase 4 should trace to Phase 3 KEY_CLASSES
       - Flag orphans that don't trace back

    2. RELATIONSHIP CONSISTENCY:
       - Container relationships in Phase 2 should align with external_deps
       - Component cross-container deps should have corresponding container relationships
       - Class relationships should be within same component

    3. COVERAGE GAPS:
       - Containers mentioned but not analyzed
       - Components with no KEY_CLASSES (is this intentional?)
       - External systems not referenced by any container

    4. NAMING CONFLICTS:
       - Duplicate IDs across levels
       - IDs that would create invalid folder names
       - Inconsistent naming (same thing called different names)

    5. STRUCTURAL ISSUES:
       - Empty containers (no components)
       - Single-component containers (should merge?)
       - Overly deep nesting

    OUTPUT FORMAT:
    ```json
    {
      "VALIDATION_PASSED": true/false,
      "ISSUES": [
        {
          "severity": "error|warning|info",
          "category": "id_consistency|relationship|coverage|naming|structure",
          "description": "Detailed description",
          "affected_elements": ["container:api-server", "component:auth"],
          "suggested_fix": "How to resolve"
        }
      ],
      "CORRECTIONS": {
        "id_renames": [{"from": "old-id", "to": "new-id", "level": "container"}],
        "orphans_to_remove": ["element-id"],
        "missing_relationships": [{"from": "a", "to": "b", "type": "..."}]
      },
      "FINAL_STRUCTURE": {
        "SYSTEM_ID": "validated-id",
        "CONTAINERS": [...validated and corrected...],
        "COMPONENTS_BY_CONTAINER": {...validated...},
        "CODE_BY_COMPONENT": {...validated...}
      }
    }
    ```

    If VALIDATION_PASSED is false and there are error-severity issues,
    list them clearly so they can be addressed before file generation.
```

**Review Phase 5 output:**
- If `VALIDATION_PASSED: false` with errors, report issues to user before proceeding
- If `VALIDATION_PASSED: true` or only warnings, proceed to file generation

---

## PHASE 6: File Generation

Using the `FINAL_STRUCTURE` from Phase 5, create the hierarchical folder structure.

### Step 1: Create folder structure

```bash
SYSTEM_ID="<from FINAL_STRUCTURE>"

# Create root
mkdir -p codemap/$SYSTEM_ID/containers

# For each container
for CONTAINER_ID in <container IDs from FINAL_STRUCTURE>; do
  mkdir -p codemap/$SYSTEM_ID/containers/$CONTAINER_ID/components

  # For each component in this container
  for COMPONENT_ID in <component IDs for this container>; do
    # Only create code folder if component has KEY_CLASSES
    if <component has classes>; then
      mkdir -p codemap/$SYSTEM_ID/containers/$CONTAINER_ID/components/$COMPONENT_ID/code
    else
      mkdir -p codemap/$SYSTEM_ID/containers/$CONTAINER_ID/components/$COMPONENT_ID
    fi
  done
done
```

### Step 2: Write files at each level

**Level 1 - System Context:**
- `codemap/<system-id>/context.puml` - From Phase 1 diagram
- `codemap/<system-id>/context.md` - Include navigation to containers

**Level 2 - Containers:**
For each container:
- `codemap/<system-id>/containers/<container-id>/container.puml`
- `codemap/<system-id>/containers/<container-id>/container.md` - Include parent link and component navigation

**Level 3 - Components:**
For each component:
- `codemap/<system-id>/containers/<container-id>/components/<component-id>/component.puml`
- `codemap/<system-id>/containers/<container-id>/components/<component-id>/component.md`

**Level 4 - Code (only if KEY_CLASSES exist):**
- `codemap/<system-id>/containers/<container-id>/components/<component-id>/code/classes.puml`
- `codemap/<system-id>/containers/<container-id>/components/<component-id>/code/classes.md`

### Step 3: Write navigation in each markdown file

Each file must include:
- **Parent link**: Link UP the hierarchy
- **Drill Down section**: Links DOWN to children
- **Last updated timestamp**

Example patterns provided in the file templates section below.

### Step 4: Generate PNG exports

```bash
find codemap -name "*.puml" -exec plantuml -tpng {} \;
```

### Step 5: Write README

Create `codemap/README.md` with entry point link to `<system-id>/context.md`.

### Step 6: Confirm output

```bash
find codemap -type f | sort
```

---

## File Templates

### context.md template
```markdown
# System Context: [System Name]

<!-- Last updated: YYYY-MM-DD -->
<!-- Generated by: c4-map Phase 1 -->

[System description]

## Diagram

![System Context](./context.png)

## Actors

| Actor | Description |
|-------|-------------|
| [Name] | [Description] |

## External Systems

| System | Type | Description |
|--------|------|-------------|
| [Name] | [Type] | [Description] |

## Drill Down - Containers

| Container | Technology | Description | Details |
|-----------|------------|-------------|---------|
| API Server | FastAPI | Handles HTTP | [View](./containers/api-server/container.md) |
```

### container.md template
```markdown
# Container: [Container Name]

<!-- Last updated: YYYY-MM-DD -->

**Parent:** [System Context](../../context.md)

[Container description]

## Diagram

![Container](./container.png)

## Technology

| Aspect | Value |
|--------|-------|
| Framework | [Framework] |
| Runtime | [Runtime] |

## Drill Down - Components

| Component | Responsibility | Details |
|-----------|----------------|---------|
| Auth | Authentication | [View](./components/auth/component.md) |

## Dependencies

### External Systems
- [List external systems this container uses]

### Other Containers
- [List container dependencies]
```

### component.md template
```markdown
# Component: [Component Name]

<!-- Last updated: YYYY-MM-DD -->

**Parent:** [Container Name](../../container.md)
**System:** [System Context](../../../../context.md)

[Component description]

## Diagram

![Component](./component.png)

## Responsibility

[Detailed responsibility description]

## Drill Down - Code

| Class | Purpose | Details |
|-------|---------|---------|
| JWTHandler | Token handling | [View](./code/classes.md) |

## Dependencies

### Internal (same container)
- [List internal dependencies]

### Cross-Container
- [List cross-container dependencies]
```

### classes.md template
```markdown
# Code: [Component Name] Classes

<!-- Last updated: YYYY-MM-DD -->

**Parent:** [Component Name](../component.md)
**Container:** [Container Name](../../../container.md)
**System:** [System Context](../../../../../context.md)

## Class Diagram

![Classes](./classes.png)

## Classes

| Class | File | Purpose | Pattern |
|-------|------|---------|---------|
| JWTHandler | auth/jwt.py:15 | Token validation | Factory |

## Design Patterns

| Pattern | Implementation | Description |
|---------|----------------|-------------|
| Factory | JWTHandler | Creates token instances |

## Key Methods

### JWTHandler
- `validate_token(token)` - Validates JWT signature and claims
- `create_token(payload)` - Creates new JWT token
```

---

## Error Handling

If any phase fails:
1. Report which phase failed and why
2. Do NOT proceed to subsequent phases
3. Suggest how to address the issue

If Phase 5 validation finds errors:
1. List all error-severity issues
2. Ask user whether to proceed with warnings or fix issues first

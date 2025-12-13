# C4 Architecture Update

Update the existing hierarchical C4 model based on code changes since it was last generated.

## Prerequisites

Hierarchical C4 model must exist in `codemap/<system-id>/` folder. If not, run `/viz/c4-map` first.

## Orchestration Strategy

This command uses **impact-aware multi-phase orchestration** with dependency-ordered execution:

```
Phase 1: Change Detection ─────────────────────────────────────────────────┐
         (Analyze git diff/file changes, categorize by C4 level)           │
                                                                           │
Phase 2: Impact Analysis ──────────────────────────────────────────────────┤
         (Determine update order based on change types)                    │
                                                                           │
Phase 3: Cascading Updates (order depends on change type) ─────────────────┤
         ADDITIONS:    Context → Container → Component → Code (top-down)   │
         DELETIONS:    Code → Component → Container → Context (bottom-up)  │
         MODIFICATIONS: Affected level + adjacent levels                   │
                                                                           │
Phase 4: Cross-Level Consistency ──────────────────────────────────────────┤
         (Verify all cross-references between levels)                      │
                                                                           │
Phase 5: Navigation Repair ────────────────────────────────────────────────┘
         (Fix broken links, update navigation tables)
```

**Why this order?**
- **Additions** need parent context first (can't create component without container)
- **Deletions** must remove children before parents (avoid orphan references)
- **Modifications** may ripple to adjacent levels (renamed container affects context and components)

---

## PHASE 1: Change Detection

First, gather information about changes. This phase MUST complete before others.

### Step 1A: Identify System and Read Existing State

```bash
# Find the system folder
SYSTEM_ID=$(ls codemap/ | head -1)
echo "System ID: $SYSTEM_ID"

# Read key metadata timestamps
stat codemap/$SYSTEM_ID/context.md | grep Modify

# List full hierarchy
find codemap/$SYSTEM_ID -type f \( -name "*.md" -o -name "*.puml" \) | sort
```

### Step 1B: Analyze Source Code Changes

```bash
# Get last codemap update commit
LAST_UPDATE=$(git log -1 --format="%H" -- codemap/)

# Files changed since last update
git diff --name-status $LAST_UPDATE..HEAD -- . ':!codemap' ':!*.md' | head -50

# If no git history, use file timestamps
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
  -newer codemap/$SYSTEM_ID/context.md 2>/dev/null | \
  grep -v node_modules | grep -v __pycache__ | head -50
```

### Step 1C: Launch Change Detection Subagent

```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Detect C4 changes"
  prompt: |
    TASK: Analyze code changes and categorize their impact on the C4 hierarchy.

    EXISTING C4 STRUCTURE:
    - SYSTEM_ID: <from Step 1A>
    - Hierarchy: <file listing from Step 1A>

    CHANGED FILES:
    <insert git diff output or file list from Step 1B>

    ANALYSIS GOALS:
    For each changed file, determine:
    1. Which C4 LEVEL is affected:
       - CONTEXT: External integrations, actors, system boundary
       - CONTAINER: New/removed services, technology changes
       - COMPONENT: New/removed modules, responsibility changes
       - CODE: Class changes within existing components

    2. What CHANGE TYPE occurred:
       - ADDITION: New element that doesn't exist in codemap
       - DELETION: Removed element that exists in codemap
       - MODIFICATION: Changed element that exists in codemap
       - RENAME: Element moved or renamed

    3. CASCADE EFFECTS:
       - Does this change affect parent levels? (child added -> parent needs update)
       - Does this change affect child levels? (parent renamed -> children need update)

    SEARCH STRATEGY:
    - Read existing codemap files to understand current state
    - Compare against changed file contents
    - Map changed files to C4 elements using source_path fields

    OUTPUT FORMAT (CRITICAL - drives Phase 2):
    ```json
    {
      "SYSTEM_ID": "existing-system-id",
      "CHANGE_SUMMARY": {
        "total_files_changed": 15,
        "context_impacts": 2,
        "container_impacts": 3,
        "component_impacts": 8,
        "code_impacts": 5
      },
      "CHANGES": [
        {
          "id": "change-001",
          "type": "ADDITION|DELETION|MODIFICATION|RENAME",
          "level": "CONTEXT|CONTAINER|COMPONENT|CODE",
          "affected_element": {
            "id": "element-id",
            "current_path": "codemap/.../component.md",
            "source_path": "ingenious/new_module/"
          },
          "description": "Added new authentication module",
          "evidence_files": ["ingenious/auth/oauth.py", "ingenious/auth/__init__.py"],
          "cascade_up": true,
          "cascade_down": false,
          "parent_element": "container:api-server",
          "priority": "high|medium|low"
        }
      ],
      "STRUCTURAL_CHANGES": {
        "new_containers": [{"id": "new-container", "parent": "system"}],
        "removed_containers": [],
        "new_components": [{"id": "oauth", "parent": "api-server"}],
        "removed_components": [],
        "renamed_elements": [{"from": "old-id", "to": "new-id", "level": "component"}]
      },
      "UPDATE_PLAN": {
        "phase_order": ["deletions", "modifications", "additions"],
        "deletion_order": ["code", "component", "container", "context"],
        "addition_order": ["context", "container", "component", "code"]
      }
    }
    ```
```

**WAIT for Phase 1 to complete. Store output for Phase 2.**

---

## PHASE 2: Impact Analysis and Update Planning

Based on Phase 1 output, determine the exact update sequence.

```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Plan C4 updates"
  model: "haiku"
  prompt: |
    TASK: Create a precise update execution plan based on detected changes.

    PHASE 1 OUTPUT:
    <insert full Change Detection output>

    PLANNING RULES:

    1. DELETION SEQUENCE (bottom-up):
       - First: Remove code/ folders for deleted components
       - Then: Remove component folders for deleted modules
       - Then: Remove container folders for deleted services
       - Finally: Update context if containers removed

    2. MODIFICATION SEQUENCE (level-specific):
       - Update the directly affected level
       - If element renamed: update all child navigation links
       - If element renamed: update parent's drill-down table

    3. ADDITION SEQUENCE (top-down):
       - First: Update context if new containers
       - Then: Create container folders for new services
       - Then: Create component folders for new modules
       - Finally: Create code/ folders for new classes

    4. PARALLEL OPPORTUNITIES:
       - Multiple deletions at same level can run in parallel
       - Multiple additions at same level can run in parallel
       - NEVER parallelize across levels when there are dependencies

    OUTPUT FORMAT:
    ```json
    {
      "EXECUTION_PLAN": [
        {
          "step": 1,
          "phase": "deletion",
          "parallel_tasks": [
            {
              "task_id": "del-001",
              "action": "remove_folder",
              "path": "codemap/.../components/old-module",
              "reason": "Module deleted from codebase"
            }
          ]
        },
        {
          "step": 2,
          "phase": "deletion",
          "depends_on": [1],
          "parallel_tasks": [
            {
              "task_id": "del-002",
              "action": "update_navigation",
              "path": "codemap/.../container.md",
              "changes": ["Remove old-module from components table"]
            }
          ]
        },
        {
          "step": 3,
          "phase": "modification",
          "parallel_tasks": [...]
        },
        {
          "step": 4,
          "phase": "addition",
          "depends_on": [3],
          "parallel_tasks": [
            {
              "task_id": "add-001",
              "action": "create_folder",
              "path": "codemap/.../components/new-module"
            },
            {
              "task_id": "add-002",
              "action": "spawn_subagent",
              "level": "component",
              "element_id": "new-module",
              "context_needed": ["parent container info"]
            }
          ]
        }
      ],
      "SUBAGENT_SPAWNS": {
        "sequential": [
          {"level": "context", "reason": "new external system added"},
          {"level": "container", "reason": "new container added", "depends_on": "context"}
        ],
        "parallel_safe": [
          {"level": "component", "elements": ["oauth", "metrics"], "parent": "api-server"}
        ]
      }
    }
    ```
```

**Review the execution plan before proceeding to Phase 3.**

---

## PHASE 3: Cascading Updates

Execute updates in dependency order. This phase may spawn multiple subagents,
but always respects the execution plan from Phase 2.

### Step 3A: Execute Deletions (Bottom-Up)

For each deletion in the execution plan:

```bash
# Remove folders in order: code -> component -> container
rm -rf <path from execution plan>
```

After deletions, update navigation links in parent files.

### Step 3B: Execute Modifications

For modified elements, spawn level-specific subagents:

**Context Modification Subagent:**
```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Update C4 context"
  prompt: |
    TASK: Update the CONTEXT level for detected modifications.

    CURRENT CONTEXT:
    <Read and insert codemap/<system-id>/context.md and context.puml>

    MODIFICATIONS DETECTED:
    <Insert relevant changes from Phase 1 where level=CONTEXT>

    UPDATE GOALS:
    1. Update external systems list if integrations changed
    2. Update actors if authentication patterns changed
    3. Update container list in diagram if containers added/removed
    4. Preserve unchanged content exactly

    OUTPUT:
    - Updated context.puml (full file)
    - Updated context.md (full file, with updated navigation table)
    - List of changes made
```

**Container Modification Subagent:**
```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Update C4 container"
  prompt: |
    TASK: Update CONTAINER level for detected modifications.

    CONTAINER TO UPDATE: <container-id>
    CURRENT STATE:
    <Read and insert codemap/<system-id>/containers/<container-id>/container.md>

    MODIFICATIONS DETECTED:
    <Insert relevant changes from Phase 1 where level=CONTAINER>

    UPDATE GOALS:
    1. Update technology stack if dependencies changed
    2. Update component list if components added/removed
    3. Update relationships if inter-container communication changed
    4. Ensure parent link to context.md is correct

    OUTPUT:
    - Updated container.puml (full file)
    - Updated container.md (full file)
    - Child navigation links that need updating
```

**Component Modification Subagent:**
```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Update C4 component"
  prompt: |
    TASK: Update COMPONENT level for detected modifications.

    COMPONENT TO UPDATE: <component-id>
    PARENT CONTAINER: <container-id>
    CURRENT STATE:
    <Read and insert component.md and component.puml>

    MODIFICATIONS DETECTED:
    <Insert relevant changes from Phase 1 where level=COMPONENT>

    SOURCE FILES TO ANALYZE:
    <Insert changed files that map to this component>

    UPDATE GOALS:
    1. Update responsibility description if module purpose changed
    2. Update dependencies if imports changed
    3. Update KEY_CLASSES list if new important classes added
    4. Update class drill-down table

    OUTPUT:
    - Updated component.puml (full file)
    - Updated component.md (full file)
    - Whether code/ folder needs updating (true/false)
```

**Code Modification Subagent:**
```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Update C4 code"
  prompt: |
    TASK: Update CODE level for detected modifications.

    COMPONENT: <component-id>
    CONTAINER: <container-id>
    CURRENT STATE:
    <Read and insert code/classes.md and classes.puml>

    MODIFICATIONS DETECTED:
    <Insert relevant changes from Phase 1 where level=CODE>

    SOURCE FILES TO ANALYZE:
    <Insert changed class files>

    UPDATE GOALS:
    1. Add new key classes if important classes added
    2. Update class methods/attributes if signatures changed
    3. Update design patterns if new patterns introduced
    4. Remove deleted classes

    OUTPUT:
    - Updated classes.puml (full file)
    - Updated classes.md (full file)
```

### Step 3C: Execute Additions (Top-Down)

For new elements, create folders first, then spawn analysis subagents:

**For new containers:**
1. Create folder: `mkdir -p codemap/<system-id>/containers/<new-container-id>/components`
2. Spawn Container Analysis subagent (similar to c4-map Phase 2 but focused on single container)
3. Wait for completion
4. Update context.md navigation table

**For new components:**
1. Create folder: `mkdir -p codemap/<system-id>/containers/<container-id>/components/<new-component-id>/code`
2. Spawn Component Analysis subagent (similar to c4-map Phase 3 but focused on single component)
3. Wait for completion
4. Update container.md navigation table

**For new code documentation:**
1. Ensure code/ folder exists
2. Spawn Code Analysis subagent (similar to c4-map Phase 4 but focused on single component's classes)
3. Wait for completion
4. Update component.md navigation table

---

## PHASE 4: Cross-Level Consistency Check

After all updates, verify consistency across levels.

```
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Verify C4 consistency"
  prompt: |
    TASK: Verify cross-level consistency after updates.

    UPDATED FILES:
    <List all files modified in Phase 3>

    VERIFICATION CHECKS:

    1. CONTAINER-CONTEXT ALIGNMENT:
       - Every container folder has entry in context.md drill-down table
       - Every entry in context.md table has corresponding folder
       - Container IDs in context.puml match folder names

    2. COMPONENT-CONTAINER ALIGNMENT:
       - Every component folder has entry in parent container.md
       - Every entry in container.md table has corresponding folder
       - Component IDs in container.puml match folder names

    3. CODE-COMPONENT ALIGNMENT:
       - Every code/ folder has entry in parent component.md
       - Classes in classes.puml are documented in classes.md

    4. NAVIGATION INTEGRITY:
       - All parent links resolve to existing files
       - All drill-down links resolve to existing folders

    5. ID CONSISTENCY:
       - No duplicate IDs across levels
       - All IDs are valid folder names (kebab-case)

    SEARCH STRATEGY:
    - Read all updated .md files
    - Extract navigation links using regex
    - Verify each link target exists
    - Compare folder names to diagram element IDs

    OUTPUT FORMAT:
    ```json
    {
      "CONSISTENCY_PASSED": true/false,
      "ISSUES": [
        {
          "type": "broken_link|missing_entry|id_mismatch|orphan_folder",
          "location": "codemap/.../container.md",
          "description": "Link to removed component still exists",
          "fix": "Remove entry from navigation table"
        }
      ],
      "FIXES_REQUIRED": [
        {
          "file": "codemap/.../container.md",
          "action": "remove_table_row",
          "details": "Remove 'old-module' from components table"
        }
      ]
    }
    ```
```

**If issues found, apply fixes before proceeding.**

---

## PHASE 5: Navigation Repair and Finalization

Apply any remaining fixes and regenerate diagrams.

### Step 5A: Apply Consistency Fixes

For each fix from Phase 4:
- Update markdown files to fix navigation links
- Remove orphan entries from tables
- Add missing entries to tables

### Step 5B: Update Timestamps

Update `<!-- Last updated: YYYY-MM-DD -->` in all modified files.

### Step 5C: Regenerate PNG Diagrams

```bash
# Regenerate only modified diagrams
SYSTEM_ID="<system-id>"

# If context changed
plantuml -tpng codemap/$SYSTEM_ID/context.puml

# For each modified container
plantuml -tpng codemap/$SYSTEM_ID/containers/<container-id>/container.puml

# For each modified component
plantuml -tpng codemap/$SYSTEM_ID/containers/<container-id>/components/<component-id>/component.puml

# For each modified code
plantuml -tpng codemap/$SYSTEM_ID/containers/<container-id>/components/<component-id>/code/classes.puml
```

### Step 5D: Update README

Update `codemap/README.md` with:
- New last-updated timestamp
- Brief change summary

---

## Output Summary

```markdown
# C4 Update Complete

## Change Summary
- Files changed in codebase: X
- C4 levels affected: [context, container, component, code]

## Structural Changes
| Change Type | Element | Action |
|-------------|---------|--------|
| ADDITION | component:oauth | Created new component folder |
| DELETION | component:legacy-auth | Removed folder and references |
| MODIFICATION | container:api-server | Updated technology stack |

## Files Modified

### Deletions (Phase 3A)
- [ ] Removed: codemap/.../components/legacy-auth/

### Modifications (Phase 3B)
- [ ] codemap/<system-id>/context.puml - Updated external systems
- [ ] codemap/<system-id>/containers/api-server/container.md - Updated components table

### Additions (Phase 3C)
- [ ] Created: codemap/.../components/oauth/
- [ ] codemap/.../components/oauth/component.puml - New component diagram
- [ ] codemap/.../components/oauth/component.md - New component docs

### Navigation Fixes (Phase 5A)
- [ ] Fixed broken link in container.md

## Diagrams Regenerated
- [ ] context.png
- [ ] api-server/container.png
- [ ] oauth/component.png

## Verification
- [ ] Cross-level consistency: PASSED
- [ ] Navigation integrity: PASSED
- [ ] ID consistency: PASSED

## Render All Diagrams
```bash
find codemap -name "*.puml" -exec plantuml -tpng {} \;
```
```

---

## Error Handling

**If Phase 1 finds no changes:**
- Report "No code changes detected since last C4 update"
- Exit without modifications

**If Phase 3 subagent fails:**
- Report which update failed and why
- DO NOT proceed with dependent updates
- Suggest manual intervention if needed

**If Phase 4 finds critical inconsistencies:**
- List all issues
- Apply automatic fixes where possible
- Flag issues requiring manual review

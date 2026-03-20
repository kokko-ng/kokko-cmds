---
disable-model-invocation: true
---

# C4 Architecture Update

Update the existing hierarchical C4 model based on code changes.

## Arguments

Usage: `/c4-update [system-id]`

- `system-id` - System ID to update (default: auto-detected from codemap/)

If `$ARGUMENTS` is provided, use it as the system-id to update.

## Prerequisites

Existing model in `codemap/<system-id>/`. If not present, run `/viz/c4-map` first.

## Orchestration

```text
Phase 1: Detect Changes -> Phase 2: Plan Updates -> Phase 3: Apply ->
Phase 4: Verify -> Phase 5: Finalize
```

**Update order:**

- Deletions: Component -> Container -> Context (bottom-up)
- Additions: Context -> Container -> Component (top-down)
- Modifications: Affected level + adjacent levels

---

## Phase 1: Change Detection

### Step 1A: Identify System

```bash
SYSTEM_ID=$(ls codemap/ | head -1)
echo "System ID: $SYSTEM_ID"
find codemap/$SYSTEM_ID -type f \( -name "*.md" -o -name "*.puml" \) | sort
```

### Step 1B: Analyze Changes

```bash
LAST_UPDATE=$(git log -1 --format="%H" -- codemap/)
git diff --name-status $LAST_UPDATE..HEAD -- . ':!codemap' ':!*.md' | head -50
```

### Step 1C: Categorize Changes

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Detect C4 changes"
  prompt: |
    Analyze code changes and categorize by C4 level.

    EXISTING HIERARCHY: <from Step 1A>
    CHANGED FILES: <from Step 1B>

    GOALS:
    For each changed file:
    1. Determine C4 LEVEL: CONTEXT|CONTAINER|COMPONENT
    2. Determine CHANGE TYPE: ADDITION|DELETION|MODIFICATION|RENAME
    3. Identify CASCADE effects (parent/child impacts)

    OUTPUT:
    {
      "SYSTEM_ID": "...",
      "CHANGE_SUMMARY": {counts by level},
      "CHANGES": [<per c4-templates.md#change-detection-schema>],
      "STRUCTURAL_CHANGES": {
        "new_containers": [], "removed_containers": [],
        "new_components": [], "removed_components": [],
        "renamed_elements": []
      }
    }
```

**WAIT for Phase 1 to complete.**

---

## Phase 2: Impact Analysis

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Plan C4 updates"
  model: "haiku"
  prompt: |
    Create update execution plan.

    PHASE 1 OUTPUT: <insert>

    PLANNING RULES:
    1. DELETIONS (bottom-up): component -> container -> context
    2. MODIFICATIONS: affected level + adjacent levels
    3. ADDITIONS (top-down): context -> container -> component
    4. PARALLEL: Same-level operations can run in parallel

    OUTPUT:
    {
      "EXECUTION_PLAN": [
        {"step": N, "phase": "...", "depends_on": [], "tasks": [...]}
      ],
      "SUBAGENT_SPAWNS": {"sequential": [], "parallel_safe": []}
    }
```

---

## Phase 3: Apply Updates

### Step 3A: Deletions (Bottom-Up)

```bash
# Remove folders in order: component -> container
rm -rf <paths from execution plan>
```

Update navigation links in parent files after deletions.

### Step 3B: Modifications

For each modified element, spawn level-specific subagent:

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Update C4 <level>"
  prompt: |
    Update <LEVEL> for modifications.

    ELEMENT: <element-id>
    CURRENT STATE: <read existing .md and .puml>
    MODIFICATIONS: <changes from Phase 1>

    GOALS:
    - Update only changed aspects
    - Preserve unchanged content exactly
    - Update navigation if children added/removed
    - Ensure parent links correct

    OUTPUT: Full updated files (puml and md)
```

### Step 3C: Additions (Top-Down)

For new elements:

1. Create folder structure
2. Spawn analysis subagent (similar to c4-map phases)
3. Update parent's drill-down table

```bash
# Create new container
mkdir -p codemap/$SYSTEM_ID/containers/<new-id>/components

# Create new component
mkdir -p codemap/$SYSTEM_ID/containers/<container>/components/<new-id>
```

---

## Phase 4: Cross-Level Consistency

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Verify C4 consistency"
  prompt: |
    Verify cross-level consistency after updates.

    UPDATED FILES: <list>

    CHECKS:
    1. Container-Context: Folders match context.md table entries
    2. Component-Container: Folders match container.md table entries
    3. Navigation: All links resolve to existing files
    4. IDs: No duplicates, valid folder names

    OUTPUT:
    {
      "CONSISTENCY_PASSED": true/false,
      "ISSUES": [...],
      "FIXES_REQUIRED": [{"file": "...", "action": "...", "details": "..."}]
    }
```

**Apply fixes if issues found.**

---

## Phase 5: Finalization

### Step 5A: Apply Consistency Fixes

Fix navigation links, remove orphan entries, add missing entries.

### Step 5B: Update Timestamps

Update `<!-- Last updated: YYYY-MM-DD -->` in modified files.

### Step 5C: Regenerate PNGs

```bash
# Regenerate modified diagrams (with local C4-PlantUML library)
plantuml -DRELATIVE_INCLUDE="." -tpng codemap/$SYSTEM_ID/context.puml
plantuml -DRELATIVE_INCLUDE="." -tpng codemap/$SYSTEM_ID/containers/<id>/container.puml
# etc.
```

### Step 5D: Update README

Update `codemap/README.md` with timestamp and change summary.

---

## Output Summary

```markdown
# C4 Update Complete

## Changes
- Files changed in codebase: X
- C4 levels affected: [list]

## Structural Changes
| Type | Element | Action |
| ---- | ------- | ------ |
| ADDITION | component:oauth | Created folder |
| DELETION | component:legacy | Removed folder |

## Files Modified
- Deletions: [list]
- Modifications: [list]
- Additions: [list]

## Verification: PASSED/FAILED
```

---

## Error Handling

- **No changes detected:** Report and exit
- **Subagent failure:** Report which update failed, skip dependent updates
- **Consistency issues:** List issues, apply automatic fixes where possible

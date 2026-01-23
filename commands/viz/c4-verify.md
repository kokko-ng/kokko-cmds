---
disable-model-invocation: true
---

# C4 Architecture Verification

Validate accuracy and completeness of the hierarchical C4 architecture map.

## Arguments

Usage: `/c4-verify [system-id]`

- `system-id` - System ID to verify (default: auto-detected from codemap/)

If `$ARGUMENTS` is provided, use it as the system-id to verify.

## Prerequisites

Existing model in `codemap/<system-id>/`. If not present, run `/viz/c4-map` first.

## Orchestration

```text
Phase 1: Preparation -> Phase 2: Parallel Verification -> Phase 3: Synthesis
-> Phase 4: Apply Fixes -> Phase 5: Re-Verification -> Phase 6: Finalization
```

Phase 2 runs five checks in parallel: Completeness, Accuracy, Hierarchy,
Diagram Quality, and Image Pairing.

---

## Phase 1: Preparation

```bash
SYSTEM_ID=$(ls codemap/ | head -1)
echo "System ID: $SYSTEM_ID"
find codemap/$SYSTEM_ID -type f \
  \( -name "*.md" -o -name "*.puml" -o -name "*.png" \) | sort
echo "Containers: $(find codemap/$SYSTEM_ID/containers \
  -maxdepth 1 -type d | wc -l)"
echo "Components: $(find codemap/$SYSTEM_ID -type d -name components \
  -exec ls {} \; | wc -l)"
```

---

## Phase 2: Parallel Verification

Launch ALL FIVE subagents IN PARALLEL in a single message.

### Subagent 1: Completeness Check

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Verify C4 completeness"
  prompt: |
    Verify COMPLETENESS against actual codebase.

    SYSTEM_ID: <from Phase 0>
    HIERARCHY: <file listing>

    CHECKS:
    1. Container Completeness: All deployable units have folders
    2. Component Completeness: All major modules documented
    3. External System Completeness: All integrations in context.puml

    SEARCH:
    - Glob: **/Dockerfile, **/docker-compose.yml (containers)
    - Grep: "class \w+", "import.*azure" (components, externals)

    OUTPUT:
    {
      "check_type": "completeness",
      "score": "X/3",
      "findings": {containers, components, external_systems},
      "issues": [<per c4-templates.md#validation-issue-schema>]
    }
```

### Subagent 2: Accuracy Check

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Verify C4 accuracy"
  prompt: |
    Verify ACCURACY against actual codebase.

    SYSTEM_ID: <from Phase 0>
    HIERARCHY: <file listing>

    CHECKS:
    1. Relationship Accuracy: Documented deps match code imports
    2. Technology Labels: Versions match pyproject.toml/package.json
    3. Hierarchy Placement: Elements in correct parent folders
    4. Naming Accuracy: Names match actual module/class names

    SEARCH:
    - Read .puml files, extract relationships
    - Grep for imports to verify deps
    - Check file paths exist

    OUTPUT:
    {
      "check_type": "accuracy",
      "score": "X% verified",
      "findings": {relationships, technology_labels, hierarchy_placement, naming},
      "issues": [...]
    }
```

### Subagent 3: Hierarchy Validation

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Validate C4 hierarchy"
  prompt: |
    Verify STRUCTURAL INTEGRITY of folder hierarchy.

    SYSTEM_ID: <from Phase 0>
    HIERARCHY: <file listing>

    CHECKS:
    1. Required Files: Each level has .puml and .md
    2. Folder Structure: No orphans, no empty containers
    3. Cross-Level Consistency: Diagram elements match folders
    4. Navigation Links: All parent/child links resolve
    5. ID Consistency: Folder names match diagram IDs

    OUTPUT:
    {
      "check_type": "hierarchy",
      "score": "X/5",
      "findings": {required_files, folder_structure, cross_level, navigation, ids},
      "issues": [...]
    }
```

### Subagent 4: Diagram Quality Check

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Validate C4 diagrams"
  prompt: |
    Verify DIAGRAM QUALITY of all PlantUML files.

    SYSTEM_ID: <from Phase 0>
    HIERARCHY: <file listing>

    CHECKS:
    1. PlantUML Syntax: Valid @startuml/@enduml blocks
    2. Correct Includes: Right C4 include per level (see c4-templates.md)
    3. Correct Macros: Right macros per level (see c4-templates.md)
    4. Element Coverage: Not overloaded (>15), not sparse
    5. Relationship Completeness: No orphan elements

    OUTPUT:
    {
      "check_type": "diagram_quality",
      "score": "X/5",
      "findings": {syntax, includes, macros, coverage, relationships},
      "issues": [...]
    }
```

### Subagent 5: Image Pairing Check

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Validate image pairing"
  prompt: |
    Verify every markdown diagram reference has corresponding PNG.

    SYSTEM_ID: <from Phase 0>
    HIERARCHY: <file listing>

    CHECKS:
    1. Extract image refs from .md files: ![...](./filename.png)
    2. Verify referenced PNG exists at path
    3. Check PNG freshness: PNG modified after PUML (not stale)
    4. Find orphan PNGs: Exist but not referenced in any .md
    5. Find missing PNGs: Referenced but don't exist

    EXPECTED PAIRINGS:
    - context.md -> context.png
    - container.md -> container.png
    - component.md -> component.png

    FRESHNESS CHECK:
    ```bash
    # PNG is stale if PUML modified after PNG
    find codemap -name "*.puml" -newer <corresponding .png>
    ```

    OUTPUT:
    {
      "check_type": "image_pairing",
      "findings": {
        "missing_pngs": [{"md_file": "...", "expected_png": "...", "line": N}],
        "orphan_pngs": [{"png_file": "...", "last_modified": "..."}],
        "stale_pngs": [{"png": "...", "puml_mtime": "...", "png_mtime": "..."}]
      },
      "issues": [...]
    }
```

**WAIT for ALL FIVE subagents to complete.**

---

## Phase 3: Synthesis

```yaml
Tool: Task
Parameters:
  subagent_type: "general-purpose"
  model: "opus"
  description: "Synthesize verification"
  prompt: |
    Synthesize findings from all five verification checks.

    OUTPUTS:
    - Completeness: <insert>
    - Accuracy: <insert>
    - Hierarchy: <insert>
    - Diagram Quality: <insert>
    - Image Pairing: <insert>

    GOALS:
    1. Find INTERSECTIONS: Same issue from multiple checks = higher confidence
    2. Identify CONFLICTS: Contradictory findings
    3. ROOT CAUSE analysis: Multiple issues from one cause
    4. PRIORITIZE: severity, frequency, cascade impact, structural first

    FIX ORDER:
    1. Structural (create/delete folders)
    2. Diagrams (fix puml files)
    3. Documentation (fix md files)
    4. Navigation (fix links)
    5. Images (regenerate stale PNGs)

    OUTPUT:
    {
      "synthesis_summary": {total_issues, intersections, conflicts, root_causes},
      "intersections": [...],
      "conflicts": [...],
      "root_causes": [...],
      "prioritized_issues": [...],
      "correction_plan": {
        "phase_1_structural": [...],
        "phase_2_diagrams": [...],
        "phase_3_documentation": [...],
        "phase_4_navigation": [...],
        "phase_5_images": [...]
      }
    }
```

---

## Phase 4: Apply Fixes

Execute fixes in order from correction_plan.

### Step 4A: Structural Fixes

```bash
# Create missing folders
mkdir -p <paths>

# Remove orphan folders
rm -rf <paths>
```

### Step 4B: Diagram Fixes

For each diagram fix, spawn focused subagent:

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Fix C4 diagram"
  model: "haiku"
  prompt: |
    Fix issues in PlantUML file.

    FILE: <path>
    CURRENT: <content>
    FIXES: <from correction_plan>

    OUTPUT: Complete updated file
```

### Step 4C: Documentation Fixes

For missing docs, spawn analysis subagent (like c4-map).
For link fixes, update markdown files directly.

### Step 4D: Navigation Fixes

Fix broken links, update drill-down tables.

### Step 4E: Image Fixes

```bash
# Regenerate stale/missing PNGs (with local C4-PlantUML library)
for puml in <stale_pngs sources>; do
  plantuml -DRELATIVE_INCLUDE="." -tpng $puml
done
```

---

## Phase 5: Re-Verification

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  description: "Re-verify fixes"
  model: "haiku"
  prompt: |
    Verify fixes were applied correctly.

    FIXES APPLIED: <list>

    CHECKS:
    1. Structural: Folders exist, required files present
    2. Diagrams: Syntax valid, includes correct
    3. Navigation: Links resolve
    4. Images: PNGs exist, not stale

    OUTPUT:
    {
      "verification_passed": true/false,
      "fixes_confirmed": [...],
      "fixes_failed": [...],
      "overall_status": "PASS|PARTIAL|FAIL"
    }
```

---

## Phase 6: Finalization

### Step 6A: Regenerate All PNGs

```bash
find codemap -name "*.puml" ! -path "*/\.c4-plantuml/*" \
  -exec plantuml -DRELATIVE_INCLUDE="." -tpng {} \;
```

### Step 6B: Write Verification Report

Create `codemap/VERIFICATION.md`:

```markdown
# C4 Verification Report

<!-- Verified: YYYY-MM-DD -->

## Summary

| Metric | Value |
| ------ | ----- |
| Completeness | X/4 |
| Accuracy | X% |
| Hierarchy | X/5 |
| Diagram Quality | X/5 |
| Image Pairing | X missing, Y stale |
| Issues Found | N |
| Issues Fixed | M |

## Corrections Applied

[List by phase]

## Remaining Issues

[List any unfixed issues]
```

### Step 6C: Update README

Update `codemap/README.md` with verification timestamp.

---

## Output Summary

```markdown
# C4 Verification Complete

## Status: PASS/PARTIAL/FAIL

## Scores
- Completeness: X/4
- Accuracy: X%
- Hierarchy: X/5
- Diagram Quality: X/5
- Image Pairing: X missing, Y stale, Z orphan

## Synthesis
- Issues found: X
- Intersections: Y
- Root causes: Z

## Fixes Applied
- Structural: X
- Diagrams: Y
- Documentation: Z
- Navigation: W
- Images: V regenerated

## Report: codemap/VERIFICATION.md
```

---

## Error Handling

- **Subagent failure:** Continue with other checks, note incomplete verification
- **Irreconcilable conflicts:** List for human decision, skip auto-fix
- **Fix failure:** Log, continue with independent fixes, report partial success
- **Re-verification failure:** List failed fixes, suggest manual intervention

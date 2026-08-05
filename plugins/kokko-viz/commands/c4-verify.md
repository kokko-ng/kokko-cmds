---
description: Verify C4 diagrams against the codebase and auto-fix discrepancies.
argument-hint: '[system-id]'
allowed-tools: Task, Bash, Read, Write, Glob, Grep
---

# C4 Architecture Verification

Validate accuracy and completeness of the C4 map in `codemap/<system-id>/`
against the actual codebase, then apply fixes. Run `/kokko-viz:c4-map` first if
no model exists.

**Read the `c4` skill first:** `${CLAUDE_PLUGIN_ROOT}/skills/c4/SKILL.md`. Its
authoring rules are what this command verifies against — mandatory source-file
hyperlinks and the ban on validation report files.

Templates and schemas live at:
!`echo "${CLAUDE_PLUGIN_ROOT}/skills/c4/references/c4-templates.md"`

Read the relevant section whenever a check cites a `c4-templates.md#...` anchor
(if the path above is empty, locate the file with Glob:
`**/kokko-viz/skills/c4/references/c4-templates.md` under `~/.claude/plugins/`).

## Orchestration

```text
Phase 1: Prep -> Phase 2: Parallel Verification (5 checks) -> Phase 3: Synthesis
-> Phase 4: Apply Fixes -> Phase 5: Re-Verify -> Phase 6: Finalize
```

---

## Phase 1: Preparation

The system to verify is `$1`. If an argument was given, use it as
`SYSTEM_ID` and verify `codemap/<SYSTEM_ID>/` exists — report the error and
stop if it does not. With no argument:

```bash
ls codemap/
```

- Exactly one entry → that is `SYSTEM_ID`.
- More than one → stop and list the systems; ask which one to verify.
  Never guess by taking the first.

```bash
echo "System ID: $SYSTEM_ID"
find codemap/$SYSTEM_ID -type f \
  \( -name "*.md" -o -name "*.puml" -o -name "*.png" \) | sort
```

---

## Phase 2: Parallel Verification

Launch ALL FIVE subagents in parallel in a single message. Each is
`Tool: Task`, `subagent_type: "Explore"`. Each receives `SYSTEM_ID` and the
Phase 1 file listing, and outputs JSON with `check_type`, a score, `findings`,
and `issues` (per c4-templates.md#validation-issue-schema). Subagents cannot
read this plugin's files: read that schema section yourself and paste it into
each of the five prompts you spawn.

**1. Completeness** (`score: X/3`): All deployable units have folders; all
major modules documented; all integrations in context.puml.
Search: Glob `**/Dockerfile`, `**/docker-compose.yml`; Grep `class \w+`,
`import.*azure`.

**2. Accuracy** (`score: X% verified`): Documented deps match code imports;
tech labels match pyproject.toml/package.json; elements in correct parent
folders; names match actual module/class names.
Search: read .puml relationships, Grep imports, verify file paths exist.

**3. Hierarchy** (`score: X/5`): Each level has .puml + .md; no orphans/empty
containers; diagram elements match folders; navigation links resolve; folder
names match diagram IDs; every source file or code element named in a `.md`
is a hyperlink to the actual file that resolves on GitHub (per
`c4-templates.md#source-file-links`) — bare-text file references are issues.

**4. Diagram Quality** (`score: X/5`): Valid `@startuml/@enduml`; correct C4
include per level; correct macros per level (see c4-templates.md); not
overloaded (>15) or sparse; no orphan elements.

**5. Image Pairing**: Each md image ref `![...](./file.png)` has an existing,
fresh PNG. Expected pairings: `context.md->context.png`,
`container.md->container.png`, `component.md->component.png`. A PNG is stale if
its .puml was modified later (`find codemap -name "*.puml" -newer <png>`).
Output findings: `missing_pngs`, `orphan_pngs`, `stale_pngs`.

Wait for ALL FIVE to complete.

---

## Phase 3: Synthesis

```yaml
Tool: Task
Parameters:
  subagent_type: "general-purpose"
  # synthesis wants the strongest model available: inherit the session model
  # rather than pinning an id that goes stale
  description: "Synthesize verification"
  prompt: |
    Synthesize findings from all five verification checks.

    OUTPUTS:
    - Completeness / Accuracy / Hierarchy / Diagram Quality / Image Pairing: <insert each>

    GOALS:
    1. INTERSECTIONS: same issue from multiple checks = higher confidence
    2. CONFLICTS: contradictory findings
    3. ROOT CAUSE: multiple issues from one cause
    4. PRIORITIZE: severity, frequency, cascade impact, structural first

    FIX ORDER: structural (folders) -> diagrams (puml) -> docs (md) ->
    navigation (links) -> images (regenerate PNGs)

    OUTPUT:
    {
      "synthesis_summary": {total_issues, intersections, conflicts, root_causes},
      "intersections": [...], "conflicts": [...], "root_causes": [...],
      "prioritized_issues": [...],
      "correction_plan": {
        "phase_1_structural": [...], "phase_2_diagrams": [...],
        "phase_3_documentation": [...], "phase_4_navigation": [...],
        "phase_5_images": [...]
      }
    }
```

---

## Phase 4: Apply Fixes

Execute `correction_plan` in order.

**4A. Structural:** `mkdir -p <paths>` for missing folders; `rm -rf <paths>`
for orphans.

**4B. Diagrams:** for each fix, spawn a focused subagent
(`Tool: Task`, `subagent_type: "Explore"`; a mechanical rewrite — a
smaller/faster model is fine when selectable) given the file
path, current content, and fixes from the plan; it returns the complete
updated file.

**4C. Documentation:** for missing docs, spawn an analysis subagent (like
c4-map); for link fixes, edit markdown directly.

**4D. Navigation:** fix broken links and drill-down tables.

**4E. Images:** regenerate stale/missing PNGs:

```bash
for puml in <stale/missing sources>; do
  plantuml -DRELATIVE_INCLUDE="." -tpng $puml
done
```

---

## Phase 5: Re-Verification

```yaml
Tool: Task
Parameters:
  subagent_type: "Explore"
  # mechanical re-check: a smaller/faster model is fine when selectable
  description: "Re-verify fixes"
  prompt: |
    Verify fixes were applied correctly.

    FIXES APPLIED: <list>

    CHECKS:
    1. Structural: folders exist, required files present
    2. Diagrams: syntax valid, includes correct
    3. Navigation: links resolve
    4. Images: PNGs exist, not stale

    OUTPUT:
    {
      "verification_passed": true/false,
      "fixes_confirmed": [...], "fixes_failed": [...],
      "overall_status": "PASS|PARTIAL|FAIL"
    }
```

---

## Phase 6: Finalization

**6A. Regenerate all PNGs:**

```bash
find codemap -name "*.puml" ! -path "*/\.c4-plantuml/*" \
  -exec plantuml -DRELATIVE_INCLUDE="." -tpng {} \;
```

**6B. Report the results IN YOUR REPLY — do NOT write a verification
document.** Never create `VERIFICATION.md`, a report file, or any other
validation artifact in the repo. Deliver the summary as a message:

```markdown
## C4 Verification

| Metric | Value |
| ------ | ----- |
| Completeness | X/3 |
| Accuracy | X% |
| Hierarchy | X/5 |
| Diagram Quality | X/5 |
| Image Pairing | X missing, Y stale |
| Issues Found / Fixed | N / M |

Corrections applied: [list by phase]
Remaining issues: [list any unfixed]
```

**6C.** Update `codemap/README.md` with the verification timestamp (this is
the only file 6B–6C may touch).

---

## Output Summary

```markdown
# C4 Verification Complete

## Status: PASS/PARTIAL/FAIL

## Scores
- Completeness: X/3 | Accuracy: X% | Hierarchy: X/5 | Diagram Quality: X/5
- Image Pairing: X missing, Y stale, Z orphan

## Synthesis
- Issues found: X | Intersections: Y | Root causes: Z

## Fixes Applied
- Structural / Diagrams / Documentation / Navigation / Images: [counts]
```

This summary is the deliverable — it goes in the reply, not into a file.

Notes: on subagent failure, continue other checks and note incomplete
verification; list irreconcilable conflicts for human decision; on fix failure,
continue independent fixes and report partial success.

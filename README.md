# claude-code-viz

A Claude Code plugin for C4 architecture mapping and Anki flashcard generation.

## Suggested Workflow

```
1. Initial Setup
   /viz/c4-map              Generate C4 architecture documentation

2. Quality Assurance
   /viz/c4-checklist        Verify diagrams against C4 best practices
   /viz/c4-verify           Validate accuracy against actual codebase

3. Maintenance (after code changes)
   /viz/c4-update           Update documentation to reflect changes
   /viz/c4-checklist        Re-verify diagram quality

4. Learning Materials (optional)
   /viz/anki-generate       Generate flashcards from architecture
   /viz/anki-verify         Verify flashcard accuracy
```

## Sample Output

See a real-world example of what this plugin generates:

https://github.com/Insight-Services-APAC/ingenious/tree/main/codemap

## Installation

```bash
/plugin install kokko-ng-insight/claude-code-viz
```

Or add via marketplace:

```bash
/plugin marketplace add kokko-ng-insight/claude-code-viz
```

## Commands

### `/viz/c4-map`

Map your codebase architecture using the hierarchical C4 model (Context, Containers, Components, Code).

**What it does:**
- Analyzes your codebase structure
- Identifies system boundaries, external integrations, actors
- Maps containers (deployable units) and their technology stacks
- Documents components and their responsibilities
- Extracts key classes and design patterns

**Output Structure:**
```
codemap/
└── <system-id>/
    ├── context.puml              # System context diagram
    ├── context.md                # Context documentation
    └── containers/
        └── <container>/
            ├── container.puml    # Container diagram
            ├── container.md      # Container documentation
            └── components/
                └── <component>/
                    ├── component.puml
                    ├── component.md
                    └── code/
                        ├── classes.puml
                        └── classes.md
```

### `/viz/c4-update`

Update existing C4 documentation based on code changes since last generation.

**What it does:**
- Detects file changes since last codemap update
- Categorizes changes by C4 level (context, container, component, code)
- Applies cascading updates in dependency order:
  - Additions: top-down (context -> container -> component -> code)
  - Deletions: bottom-up (code -> component -> container -> context)
- Repairs navigation links between levels

**Prerequisites:** Run `/viz/c4-map` first

### `/viz/c4-verify`

Validate accuracy and completeness of your C4 architecture map against the actual codebase.

**What it does:**
- **Completeness check**: Are all containers, components, and key classes documented?
- **Accuracy check**: Do relationships and technology labels match the code?
- **Hierarchy validation**: Is the folder structure correct with required files?
- **Diagram quality**: Are PlantUML files syntactically correct with proper C4 macros?

**Output:** Verification report with prioritized fixes

**Prerequisites:** Run `/viz/c4-map` first

### `/viz/c4-checklist`

Verify all C4 diagrams against the official C4 model review checklist.

**Reference:** https://c4model.com/diagrams/checklist

**What it checks:**

| Category | Checks |
|----------|--------|
| **General** | Title, diagram type clarity, scope clarity, key/legend |
| **Elements** | Names, abstraction level, descriptions, technology, acronyms, colours, shapes, icons, borders, sizing |
| **Relationships** | Labels, direction match, protocols, acronyms, colours, arrow heads, line styles |

**Output:** `codemap/<system-id>/C4-CHECKLIST.md` with:
- Overall compliance score (EXCELLENT / GOOD / NEEDS WORK / POOR)
- Per-diagram breakdown (21 checks each)
- Prioritized fixes (Critical / High / Medium / Low)
- Quick wins (easy fixes with high impact)

**Prerequisites:** Run `/viz/c4-map` first

### `/viz/anki-generate`

Generate Anki flashcards covering architecture concepts for learning the codebase.

**What it generates:**
- System purpose and boundaries
- External system integrations
- Container responsibilities and technology stack
- Component modules and dependencies
- Key classes and design patterns
- Cross-cutting concerns (auth, error handling, config)

**Output:** `codemap/<system-id>/anki-cards.json`

**Card format:**
```json
[
  {
    "Front": "Definition or explanation without the term",
    "Back": "The answer term"
  }
]
```

**Prerequisites:** Run `/viz/c4-map` first

### `/viz/anki-verify`

Verify flashcard accuracy against the actual codebase and automatically fix issues.

**What it does:**
- Verifies each card against actual code
- Checks terminology accuracy and spelling
- Validates that concepts exist in the codebase
- Automatically fixes or removes incorrect cards

**Prerequisites:** Run `/viz/anki-generate` first

## Features

- **C4 Architecture Mapping**: Automatically analyze and document your codebase using the C4 model
- **Best Practice Verification**: Validate diagrams against official C4 checklist
- **Incremental Updates**: Keep architecture documentation in sync with code changes
- **Accuracy Verification**: Validate documentation against actual codebase
- **Anki Flashcards**: Generate study flashcards from architecture documentation
- **Flashcard Verification**: Verify flashcard accuracy against the codebase

## Skills

The plugin includes a skill that can be automatically invoked by Claude when:
- You ask about codebase architecture
- You need documentation of system structure
- You want to generate learning materials from code

## Requirements

- Claude Code CLI
- PlantUML (for PNG diagram generation)
- Git (for change detection in updates)

## Rendering Diagrams

All diagrams use C4-PlantUML syntax. Render to PNG with:

```bash
find codemap -name "*.puml" -exec plantuml -tpng {} \;
```

## License

MIT

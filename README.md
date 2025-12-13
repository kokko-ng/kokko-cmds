# claude-code-viz

A Claude Code plugin for C4 architecture mapping and Anki flashcard generation.

## Features

- **C4 Architecture Mapping**: Automatically analyze and document your codebase using the C4 model (Context, Containers, Components, Code)
- **Incremental Updates**: Keep your architecture documentation in sync with code changes
- **Verification**: Validate accuracy and completeness of architecture maps
- **Anki Flashcards**: Generate study flashcards from your architecture documentation
- **Flashcard Verification**: Verify flashcard accuracy against the actual codebase

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

Map your codebase architecture using the hierarchical C4 model.

**Output Structure:**
```
codemap/
└── <system-id>/
    ├── context.puml
    ├── context.md
    └── containers/
        └── <container>/
            ├── container.puml
            ├── container.md
            └── components/
                └── <component>/
                    ├── component.puml
                    ├── component.md
                    └── code/
                        ├── classes.puml
                        └── classes.md
```

### `/viz/c4-update`

Update existing C4 documentation based on code changes since last generation. Detects additions, deletions, and modifications with cascading updates.

### `/viz/c4-verify`

Validate accuracy and completeness of your C4 architecture map:
- Completeness check against actual codebase
- Accuracy verification of relationships and technology labels
- Hierarchy structural integrity
- PlantUML diagram quality

### `/viz/anki-generate`

Generate Anki flashcards covering architecture concepts:
- System purpose and boundaries
- Container responsibilities and technology stack
- Component modules and dependencies
- Key classes and design patterns

**Output:** `codemap/<system-id>/anki-cards.json`

### `/viz/anki-verify`

Verify flashcard accuracy against the codebase and automatically fix issues.

## Skills

The plugin includes a skill that can be automatically invoked by Claude when:
- You ask about codebase architecture
- You need documentation of system structure
- You want to generate learning materials from code

## Requirements

- Claude Code CLI
- PlantUML (for PNG diagram generation)
- Git (for change detection in updates)

## Output Formats

### PlantUML Diagrams

All diagrams use C4-PlantUML syntax and can be rendered with:

```bash
find codemap -name "*.puml" -exec plantuml -tpng {} \;
```

### Anki JSON

Flashcards are exported in standard JSON format compatible with Anki import:

```json
[
  {
    "Front": "Definition without the term",
    "Back": "The answer term"
  }
]
```

## License

MIT

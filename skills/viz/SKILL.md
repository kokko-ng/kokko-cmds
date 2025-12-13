---
name: codebase-visualization
description: Map codebase architecture using C4 model and generate Anki flashcards. Use when user asks about architecture documentation, system structure visualization, C4 diagrams, or wants to generate learning flashcards from code.
---

# Codebase Visualization Skill

This skill provides C4 architecture mapping and Anki flashcard generation for codebases.

## Capabilities

1. **C4 Architecture Mapping** - Analyze and document codebase structure using the C4 model:
   - Context level: System boundaries, actors, external systems
   - Container level: Deployable units, technology stacks
   - Component level: Modules and their responsibilities
   - Code level: Key classes and design patterns

2. **Architecture Updates** - Keep documentation in sync with code changes

3. **Verification** - Validate accuracy and completeness of architecture maps

4. **Anki Flashcards** - Generate study flashcards from architecture documentation

## When to Use

This skill should be invoked when the user:
- Asks to document or map the codebase architecture
- Wants C4 diagrams or architecture visualization
- Needs to understand system structure
- Asks for PlantUML diagrams of the codebase
- Wants to generate flashcards for learning the codebase
- Mentions "codemap", "C4 model", or "architecture documentation"

## Available Commands

After this skill is invoked, suggest the appropriate command:

| Goal | Command |
|------|---------|
| Initial architecture mapping | `/viz/c4-map` |
| Update existing documentation | `/viz/c4-update` |
| Verify documentation accuracy | `/viz/c4-verify` |
| Generate Anki flashcards | `/viz/anki-generate` |
| Verify flashcard accuracy | `/viz/anki-verify` |

## Output Location

All outputs are stored in `codemap/<system-id>/` directory:
- `*.puml` - PlantUML diagram source files
- `*.md` - Markdown documentation with navigation
- `anki-cards.json` - Anki flashcard export

## Prerequisites

- PlantUML for diagram rendering
- Git for change detection (c4-update command)

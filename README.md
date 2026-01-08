# claude-code-viz

A Claude Code plugin for C4 architecture mapping and Anki flashcard generation.

## Installation

```bash
/plugin marketplace add kokko-ng/claude-code-viz
/plugin install claude-code-viz@kokko-ng-claude-code-viz
```

## Suggested Workflow

```
1. Initial Setup
   /viz/c4-map              Generate C4 architecture documentation

2. Quality Assurance
   /viz/c4-verify           Validate accuracy against actual codebase
   /viz/c4-checklist        Verify diagrams against C4 best practices

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

## License

MIT

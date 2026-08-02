# kokko-viz

C4 architecture visualization: generate, update, and verify C4 model
diagrams from a codebase. All three commands read the `c4` skill first;
shared templates live in `skills/c4/references/c4-templates.md`.

```bash
/plugin install kokko-viz@kokko-ng-kokko-cmds
```

## Commands

| Command | Purpose |
| ------- | ------- |
| `/c4-map` | Generate a hierarchical C4 architecture map (context/containers/components) |
| `/c4-update` | Update an existing C4 model to match current code changes |
| `/c4-verify` | Verify C4 diagrams against the codebase and auto-fix discrepancies |

## Skills

| Skill | Purpose |
| ----- | ------- |
| `c4` | Authoring rules for C4 documents (mandatory source-file hyperlinks, no validation report files) plus the shared templates |

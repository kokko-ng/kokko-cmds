# kokko-validation

Generic validation and deployment master-prompt templates plus a skill that
instantiates them for the current repo. The templates cover local
validation, deployed validation, Azure deployment, and aesthetics review;
they carry `{{PLACEHOLDER}}` slots the skill fills in from the codebase.

```bash
/plugin install kokko-validation@kokko-ng-kokko-cmds
```

## Skills

| Skill | Purpose |
| ----- | ------- |
| `tailor` | Instantiate a generic master prompt (local, deployed, azure-deploy, or aesthetics) for the current repo and save it to `prompts/` |

## Templates

The generic templates live in `skills/tailor/references/`:

| Template | Covers |
| -------- | ------ |
| `local-validation.md` | Validating the app end-to-end on a dev machine |
| `deployed-validation.md` | Validating a deployed environment |
| `azure-deploy.md` | Deploying to Azure |
| `aesthetics.md` | UI/visual review |

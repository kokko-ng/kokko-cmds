# kokko-validation

Generic validation and deployment master-prompt templates plus a skill that
instantiates them for the current repo. The templates cover local
validation, deployed validation, Azure deployment, and aesthetics review;
they carry `{{PLACEHOLDER}}` slots the skill fills in from the codebase.

The validation and deploy templates validate `spec.md` user stories through
deterministic, assertion-based test suites — API/integration tests,
frontend component tests, and headless Playwright E2E specs
(`@playwright/test`) — rather than agent-driven browser automation. The
browser still gets exercised, but by committed specs with web-first
assertions, not by the agent driving pages and reading screenshots: faster
re-validation loops and far fewer tokens. The aesthetics template is the
one place the agent itself drives a browser (Playwright CLI), since visual
defects can't be judged by assertions.

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
| `local-validation.md` | Validating the app on a dev machine with deterministic tests |
| `deployed-validation.md` | Validating a deployed environment with deterministic tests |
| `azure-deploy.md` | Deploying to Azure |
| `aesthetics.md` | UI/visual review (screenshot-driven) |

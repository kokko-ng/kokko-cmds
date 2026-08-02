# kokko-infra

Azure infrastructure commands for keeping an eye on a subscription: costs
with anomaly analysis, and a daily activity/health summary. Both commands
drive the `az` CLI, which must be installed and logged in.

```bash
/plugin install kokko-infra@kokko-ng-kokko-cmds
```

## Commands

| Command | Purpose |
| ------- | ------- |
| `/az-costs` | Break down Azure subscription costs with anomaly and optimization analysis |
| `/az-status` | Generate a daily Azure subscription activity and health summary |

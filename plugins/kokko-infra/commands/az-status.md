---
description: Generate a daily Azure subscription activity and health summary.
argument-hint: '[subscription-id] [--days N]'
allowed-tools: Bash(az:*), Bash(date:*), AskUserQuestion
disable-model-invocation: true
---

# Azure Daily Summary

Generate a daily summary of Azure subscription activity and health. `$1` is the subscription to analyze; `--days N` sets the lookback window (default: 1). Use the chosen lookback as `<days>` in every command below.

## CRITICAL — Safety

ALWAYS use AskUserQuestion to confirm the subscription and resource group scope before proceeding. Never assume defaults.

## Steps

1. List subscriptions and confirm target via AskUserQuestion, then set it:

```bash
az account list --query "[].{Name:name, Id:id}" -o table
az account set --subscription "<confirmed-subscription-id>"
```

1. Inventory resources:

```bash
az group list --output table
az resource list \
  --query "[].{Name:name, Type:type, Location:location}" \
  --output table
```

1. Check key services:

```bash
az webapp list --output table        # App Services
az containerapp list --output table  # Container Apps
az functionapp list --output table   # Functions
az vm list -d --output table         # Virtual Machines
```

1. Review recent activity over the lookback window:

```bash
az monitor activity-log list --offset <days>d --output table
```

1. Security and access review:

```bash
az network nsg rule list --resource-group <rg> --nsg-name <nsg> --output table 2>/dev/null
az keyvault certificate list --vault-name <vault> --output table 2>/dev/null
```

1. Cost summary (if enabled), covering the same lookback window (minimum 7 days for a useful trend):

```bash
date -d "<days> days ago" +%Y-%m-%d 2>/dev/null || date -v-<days>d +%Y-%m-%d
date +%Y-%m-%d
az consumption usage list \
  --start-date "<first date printed above>" \
  --end-date "<second date printed above>" \
  --output table
```

If the consumption query fails with an authorization error, cost data
requires Cost Management permissions — note it in the report and move on.

## Output Format

```markdown
# Azure Daily Summary
Date: YYYY-MM-DD
Subscription: <name>

## Resource Overview
| Type | Count | Status |
|------|-------|--------|
| Resource Groups | X | - |
| App Services | X | Y Running |
| Container Apps | X | Y Running |

## Recent Activity
| Time | Operation | Status | Resource |
|------|-----------|--------|----------|
| ... | ... | ... | ... |

## Alerts/Issues
- <any warnings or errors>

## Recommendations
- <optimization suggestions>
```

- Not logged in → `az login`.
- Permission denied → request Reader/Cost Management RBAC role.

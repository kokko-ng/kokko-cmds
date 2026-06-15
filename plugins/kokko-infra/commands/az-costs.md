---
description: Break down Azure subscription costs with anomaly and optimization analysis.
argument-hint: [daily|weekly|<resource-group>]
allowed-tools: Bash(az:*), AskUserQuestion
---

# Azure Cost Analysis

Generate a cost breakdown of Azure subscription resources. `$ARGUMENTS` selects `daily`/`weekly` granularity or filters to a resource group.

## CRITICAL — Safety

ALWAYS use AskUserQuestion to confirm the subscription and resource group before proceeding. Never assume defaults. List options if needed:

```bash
az account list --query "[].{Name:name, Id:id}" -o table
az group list --query "[].name" -o tsv
```

Also confirm the time period (default: MonthToDate).

## Steps

1. Get cost data:

```bash
# Costs by resource group
az cost query --type ActualCost \
  --dataset-grouping name=ResourceGroup type=Dimension \
  --timeframe MonthToDate

# Daily cost trend by service
az cost query --type ActualCost \
  --dataset-grouping name=ServiceName type=Dimension \
  --timeframe MonthToDate --dataset-aggregation totalCost=Sum

# Forecast for current month
az cost query --type AmortizedCost --timeframe MonthToDate
```

2. Per resource group: total MTD, top 3 cost drivers, trend, % of total spend.
3. Break down by service category: Compute (VMs, Container Apps, Functions), Storage (Blob, Cosmos, SQL), AI Services (OpenAI, Cognitive), Networking, Other.
4. Flag anomalies: daily spike >20% above 7-day average; new resources since last week; idle resources with cost but zero usage; resources near quota limits.
5. Suggest optimizations: downsize underutilized resources, reserved-instance opportunities, B-series for dev/test, storage tier changes (hot/cool/archive).

## Output Format

```text
## Azure Cost Summary (MTD)

Total Spend: $X,XXX.XX
Forecast End of Month: $X,XXX.XX
vs Last Month: +/- XX%

### By Resource Group
| Resource Group | Cost | % of Total | Trend |
|---------------|------|------------|-------|
| ... | ... | ... | ... |

### Top Cost Drivers
1. [Resource Name] - $XXX.XX (reason)
2. ...

### Alerts
- [Any anomalies or concerns]

### Optimization Opportunities
- [Specific actionable suggestions]
```

- Not logged in → `az login`.
- Cost data requires Cost Management permissions.

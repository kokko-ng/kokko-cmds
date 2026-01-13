# Azure Daily Summary

Generate a comprehensive daily summary of Azure subscription activity using Azure CLI.

## When to Use

- For daily infrastructure review
- To monitor Azure resource usage
- For operational status reporting

## Arguments

Usage: `/infra/az-status [subscription-id] [--days n]`

- `subscription-id` - Azure subscription to analyze
- `--days` - Number of days to include (default: 1)

ALWAYS use AskUserQuestion to confirm subscription and resource group scope before proceeding. Never assume defaults.

## Prerequisites

- Azure CLI installed and authenticated: `az login`
- Appropriate permissions on target subscription

## Steps

### 1. Confirm Target Subscription

ALWAYS ask user to confirm subscription before proceeding:

```bash
# List available subscriptions
az account list --query "[].{Name:name, Id:id}" -o table
```

Use AskUserQuestion to confirm which subscription to analyze.

### 2. Set Subscription

```bash
az account set --subscription "<confirmed-subscription-id>"
```

### 3. Gather Resource Information

**List resource groups:**
```bash
az group list --output table
```

**List all resources:**
```bash
az resource list --query "[].{Name:name, Type:type, Location:location, ResourceGroup:resourceGroup}" --output table
```

### 4. Check Key Services Status

**App Services:**
```bash
az webapp list --output table
```

**Container Apps:**
```bash
az containerapp list --output table
```

**Azure Functions:**
```bash
az functionapp list --output table
```

**Virtual Machines:**
```bash
az vm list -d --output table
```

### 5. Review Activity Log

```bash
# Get recent activity (last 24 hours)
az monitor activity-log list --offset 1d --output table
```

### 6. Security and Access Review

**Recent firewall changes:**
```bash
az network nsg rule list --resource-group <rg> --nsg-name <nsg> --output table 2>/dev/null
```

**Certificate status:**
```bash
az keyvault certificate list --vault-name <vault> --output table 2>/dev/null
```

### 7. Cost Summary (if enabled)

```bash
az consumption usage list --start-date $(date -d "7 days ago" +%Y-%m-%d) --end-date $(date +%Y-%m-%d) --output table 2>/dev/null || echo "Cost data requires Cost Management permissions"
```

### 8. Generate Summary Report

Format findings as:

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

## Error Handling

| Issue | Cause | Resolution |
|-------|-------|------------|
| Not logged in | Session expired | Run `az login` |
| Permission denied | Missing RBAC role | Request Reader access |
| Subscription not found | Wrong ID | Verify with `az account list` |

## Success Criteria

- All resource types inventoried
- Service health status checked
- Recent activity reviewed
- Summary report generated

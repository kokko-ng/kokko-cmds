#!/bin/bash
# pre-tool-cloud-ops.sh - Block dangerous Azure, GitHub CLI, and IaC operations
# PreToolUse on Bash - Blocks destructive cloud commands only

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Dangerous cloud command patterns (destructive operations only)
dangerous_patterns=(
    # ========================================
    # Terraform/Pulumi/OpenTofu destructive
    # ========================================
    'terraform[[:space:]]+destroy'
    'terraform[[:space:]]+apply[[:space:]]+-auto-approve'
    'terraform[[:space:]]+apply[[:space:]]+--auto-approve'
    'terraform[[:space:]]+taint'
    'terraform[[:space:]]+untaint'
    'terraform[[:space:]]+state[[:space:]]+rm'
    'terraform[[:space:]]+state[[:space:]]+mv'
    'terraform[[:space:]]+state[[:space:]]+replace-provider'
    'terraform[[:space:]]+force-unlock'
    'terraform[[:space:]]+workspace[[:space:]]+delete'
    'tofu[[:space:]]+destroy'
    'tofu[[:space:]]+apply[[:space:]]+-auto-approve'
    'pulumi[[:space:]]+destroy'
    'pulumi[[:space:]]+up[[:space:]]+-y'
    'pulumi[[:space:]]+up[[:space:]]+--yes'
    'pulumi[[:space:]]+refresh[[:space:]]+-y'
    'pulumi[[:space:]]+stack[[:space:]]+rm'

    # ========================================
    # kubectl destructive
    # ========================================
    'kubectl[[:space:]]+delete'
    'kubectl[[:space:]]+drain'
    'kubectl[[:space:]]+cordon'
    'kubectl[[:space:]]+uncordon'
    'kubectl[[:space:]]+taint'
    'kubectl[[:space:]]+replace[[:space:]]+--force'
    'kubectl[[:space:]]+rollout[[:space:]]+undo'
    'kubectl[[:space:]]+rollout[[:space:]]+restart'
    'kubectl[[:space:]]+scale[[:space:]]+.*--replicas=0'
    'kubectl[[:space:]]+patch'
    'kubectl[[:space:]]+edit'
    'kubectl[[:space:]]+apply[[:space:]]+--force'
    'kubectl[[:space:]]+create[[:space:]]+--force'

    # ========================================
    # Azure CLI (az) destructive operations
    # ========================================
    # Generic delete pattern
    'az[[:space:]]+[a-z-]+[[:space:]]+delete'
    'az[[:space:]]+[a-z-]+[[:space:]]+[a-z-]+[[:space:]]+delete'

    # Resource groups
    'az[[:space:]]+group[[:space:]]+delete'
    'az[[:space:]]+group[[:space:]]+deployment[[:space:]]+delete'

    # Virtual machines
    'az[[:space:]]+vm[[:space:]]+delete'
    'az[[:space:]]+vm[[:space:]]+deallocate'
    'az[[:space:]]+vm[[:space:]]+stop'
    'az[[:space:]]+vm[[:space:]]+restart'
    'az[[:space:]]+vm[[:space:]]+redeploy'
    'az[[:space:]]+vm[[:space:]]+reimage'
    'az[[:space:]]+vm[[:space:]]+generalize'
    'az[[:space:]]+vmss[[:space:]]+delete'
    'az[[:space:]]+vmss[[:space:]]+deallocate'
    'az[[:space:]]+vmss[[:space:]]+stop'
    'az[[:space:]]+vmss[[:space:]]+restart'
    'az[[:space:]]+vmss[[:space:]]+reimage'
    'az[[:space:]]+vmss[[:space:]]+scale'

    # Storage
    'az[[:space:]]+storage[[:space:]]+account[[:space:]]+delete'
    'az[[:space:]]+storage[[:space:]]+container[[:space:]]+delete'
    'az[[:space:]]+storage[[:space:]]+blob[[:space:]]+delete'
    'az[[:space:]]+storage[[:space:]]+blob[[:space:]]+delete-batch'
    'az[[:space:]]+storage[[:space:]]+share[[:space:]]+delete'
    'az[[:space:]]+storage[[:space:]]+table[[:space:]]+delete'
    'az[[:space:]]+storage[[:space:]]+queue[[:space:]]+delete'

    # Networking
    'az[[:space:]]+network[[:space:]]+vnet[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+nsg[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+nsg[[:space:]]+rule[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+nic[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+public-ip[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+lb[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+application-gateway[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+dns[[:space:]]+zone[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+dns[[:space:]]+record-set[[:space:]]+.*[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+private-endpoint[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+private-dns[[:space:]]+zone[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+firewall[[:space:]]+delete'
    'az[[:space:]]+network[[:space:]]+bastion[[:space:]]+delete'

    # Databases
    'az[[:space:]]+sql[[:space:]]+server[[:space:]]+delete'
    'az[[:space:]]+sql[[:space:]]+db[[:space:]]+delete'
    'az[[:space:]]+sql[[:space:]]+mi[[:space:]]+delete'
    'az[[:space:]]+mysql[[:space:]]+server[[:space:]]+delete'
    'az[[:space:]]+mysql[[:space:]]+flexible-server[[:space:]]+delete'
    'az[[:space:]]+postgres[[:space:]]+server[[:space:]]+delete'
    'az[[:space:]]+postgres[[:space:]]+flexible-server[[:space:]]+delete'
    'az[[:space:]]+cosmosdb[[:space:]]+delete'
    'az[[:space:]]+cosmosdb[[:space:]]+sql[[:space:]]+database[[:space:]]+delete'
    'az[[:space:]]+cosmosdb[[:space:]]+sql[[:space:]]+container[[:space:]]+delete'
    'az[[:space:]]+redis[[:space:]]+delete'
    'az[[:space:]]+mariadb[[:space:]]+server[[:space:]]+delete'

    # App Services
    'az[[:space:]]+webapp[[:space:]]+delete'
    'az[[:space:]]+webapp[[:space:]]+stop'
    'az[[:space:]]+webapp[[:space:]]+restart'
    'az[[:space:]]+webapp[[:space:]]+deployment[[:space:]]+slot[[:space:]]+delete'
    'az[[:space:]]+functionapp[[:space:]]+delete'
    'az[[:space:]]+functionapp[[:space:]]+stop'
    'az[[:space:]]+functionapp[[:space:]]+restart'
    'az[[:space:]]+staticwebapp[[:space:]]+delete'
    'az[[:space:]]+appservice[[:space:]]+plan[[:space:]]+delete'

    # Container services
    'az[[:space:]]+aks[[:space:]]+delete'
    'az[[:space:]]+aks[[:space:]]+stop'
    'az[[:space:]]+aks[[:space:]]+nodepool[[:space:]]+delete'
    'az[[:space:]]+aks[[:space:]]+nodepool[[:space:]]+scale'
    'az[[:space:]]+acr[[:space:]]+delete'
    'az[[:space:]]+acr[[:space:]]+repository[[:space:]]+delete'
    'az[[:space:]]+container[[:space:]]+delete'
    'az[[:space:]]+containerapp[[:space:]]+delete'
    'az[[:space:]]+containerapp[[:space:]]+revision[[:space:]]+deactivate'

    # Identity and access
    'az[[:space:]]+ad[[:space:]]+user[[:space:]]+delete'
    'az[[:space:]]+ad[[:space:]]+group[[:space:]]+delete'
    'az[[:space:]]+ad[[:space:]]+app[[:space:]]+delete'
    'az[[:space:]]+ad[[:space:]]+sp[[:space:]]+delete'
    'az[[:space:]]+role[[:space:]]+assignment[[:space:]]+delete'
    'az[[:space:]]+role[[:space:]]+definition[[:space:]]+delete'
    'az[[:space:]]+keyvault[[:space:]]+delete'
    'az[[:space:]]+keyvault[[:space:]]+secret[[:space:]]+delete'
    'az[[:space:]]+keyvault[[:space:]]+key[[:space:]]+delete'
    'az[[:space:]]+keyvault[[:space:]]+certificate[[:space:]]+delete'
    'az[[:space:]]+keyvault[[:space:]]+purge'
    'az[[:space:]]+identity[[:space:]]+delete'

    # Deployments
    'az[[:space:]]+deployment[[:space:]]+group[[:space:]]+delete'
    'az[[:space:]]+deployment[[:space:]]+sub[[:space:]]+delete'
    'az[[:space:]]+deployment[[:space:]]+mg[[:space:]]+delete'
    'az[[:space:]]+deployment[[:space:]]+tenant[[:space:]]+delete'
    'az[[:space:]]+deployment[[:space:]]+.*[[:space:]]+cancel'
    'az[[:space:]]+stack[[:space:]]+group[[:space:]]+delete'
    'az[[:space:]]+stack[[:space:]]+sub[[:space:]]+delete'
    'az[[:space:]]+stack[[:space:]]+mg[[:space:]]+delete'

    # Messaging and eventing
    'az[[:space:]]+servicebus[[:space:]]+namespace[[:space:]]+delete'
    'az[[:space:]]+servicebus[[:space:]]+queue[[:space:]]+delete'
    'az[[:space:]]+servicebus[[:space:]]+topic[[:space:]]+delete'
    'az[[:space:]]+eventhubs[[:space:]]+namespace[[:space:]]+delete'
    'az[[:space:]]+eventhubs[[:space:]]+eventhub[[:space:]]+delete'
    'az[[:space:]]+eventgrid[[:space:]]+topic[[:space:]]+delete'
    'az[[:space:]]+eventgrid[[:space:]]+domain[[:space:]]+delete'

    # Monitoring and logging
    'az[[:space:]]+monitor[[:space:]]+log-analytics[[:space:]]+workspace[[:space:]]+delete'
    'az[[:space:]]+monitor[[:space:]]+app-insights[[:space:]]+component[[:space:]]+delete'
    'az[[:space:]]+monitor[[:space:]]+diagnostic-settings[[:space:]]+delete'
    'az[[:space:]]+monitor[[:space:]]+action-group[[:space:]]+delete'
    'az[[:space:]]+monitor[[:space:]]+metrics-alert[[:space:]]+delete'

    # Cognitive services and AI
    'az[[:space:]]+cognitiveservices[[:space:]]+account[[:space:]]+delete'
    'az[[:space:]]+openai[[:space:]]+delete'
    'az[[:space:]]+ml[[:space:]]+workspace[[:space:]]+delete'
    'az[[:space:]]+ml[[:space:]]+compute[[:space:]]+delete'
    'az[[:space:]]+ml[[:space:]]+online-endpoint[[:space:]]+delete'
    'az[[:space:]]+ml[[:space:]]+online-deployment[[:space:]]+delete'

    # DevOps and source control
    'az[[:space:]]+devops[[:space:]]+project[[:space:]]+delete'
    'az[[:space:]]+repos[[:space:]]+delete'
    'az[[:space:]]+pipelines[[:space:]]+delete'

    # Other Azure services
    'az[[:space:]]+apim[[:space:]]+delete'
    'az[[:space:]]+cdn[[:space:]]+endpoint[[:space:]]+delete'
    'az[[:space:]]+cdn[[:space:]]+profile[[:space:]]+delete'
    'az[[:space:]]+signalr[[:space:]]+delete'
    'az[[:space:]]+batch[[:space:]]+account[[:space:]]+delete'
    'az[[:space:]]+logic[[:space:]]+workflow[[:space:]]+delete'
    'az[[:space:]]+backup[[:space:]]+protection[[:space:]]+disable'
    'az[[:space:]]+backup[[:space:]]+vault[[:space:]]+delete'
    'az[[:space:]]+policy[[:space:]]+assignment[[:space:]]+delete'
    'az[[:space:]]+blueprint[[:space:]]+delete'
    'az[[:space:]]+lock[[:space:]]+delete'
    'az[[:space:]]+tag[[:space:]]+delete'

    # Subscription and management group operations
    'az[[:space:]]+account[[:space:]]+management-group[[:space:]]+delete'

    # ========================================
    # GitHub CLI (gh) destructive operations
    # ========================================
    # Repository operations
    'gh[[:space:]]+repo[[:space:]]+delete'
    'gh[[:space:]]+repo[[:space:]]+archive'
    'gh[[:space:]]+repo[[:space:]]+unarchive'
    'gh[[:space:]]+repo[[:space:]]+rename'
    'gh[[:space:]]+repo[[:space:]]+edit[[:space:]]+--visibility'

    # Branch operations
    'gh[[:space:]]+api[[:space:]]+.*repos/.*/git/refs[[:space:]]+-X[[:space:]]+DELETE'

    # Release operations
    'gh[[:space:]]+release[[:space:]]+delete'
    'gh[[:space:]]+release[[:space:]]+delete-asset'

    # Issue and PR operations
    'gh[[:space:]]+issue[[:space:]]+delete'
    'gh[[:space:]]+issue[[:space:]]+close'
    'gh[[:space:]]+issue[[:space:]]+lock'
    'gh[[:space:]]+pr[[:space:]]+close'
    'gh[[:space:]]+pr[[:space:]]+merge[[:space:]]+--delete-branch'
    'gh[[:space:]]+pr[[:space:]]+merge[[:space:]]+-d'

    # Secret operations
    'gh[[:space:]]+secret[[:space:]]+delete'
    'gh[[:space:]]+secret[[:space:]]+remove'

    # Variable operations
    'gh[[:space:]]+variable[[:space:]]+delete'

    # Environment operations
    'gh[[:space:]]+api[[:space:]]+.*environments.*[[:space:]]+-X[[:space:]]+DELETE'

    # Workflow operations
    'gh[[:space:]]+workflow[[:space:]]+disable'
    'gh[[:space:]]+run[[:space:]]+cancel'
    'gh[[:space:]]+run[[:space:]]+delete'

    # SSH key operations
    'gh[[:space:]]+ssh-key[[:space:]]+delete'

    # GPG key operations
    'gh[[:space:]]+gpg-key[[:space:]]+delete'

    # Label operations
    'gh[[:space:]]+label[[:space:]]+delete'

    # Codespace operations
    'gh[[:space:]]+codespace[[:space:]]+delete'
    'gh[[:space:]]+codespace[[:space:]]+stop'
    'gh[[:space:]]+cs[[:space:]]+delete'
    'gh[[:space:]]+cs[[:space:]]+stop'

    # Gist operations
    'gh[[:space:]]+gist[[:space:]]+delete'

    # Project operations
    'gh[[:space:]]+project[[:space:]]+delete'
    'gh[[:space:]]+project[[:space:]]+close'

    # Extension operations
    'gh[[:space:]]+extension[[:space:]]+remove'

    # Auth operations (potentially dangerous)
    'gh[[:space:]]+auth[[:space:]]+logout'

    # API DELETE operations
    'gh[[:space:]]+api[[:space:]]+.*[[:space:]]+-X[[:space:]]+DELETE'
    'gh[[:space:]]+api[[:space:]]+.*[[:space:]]+--method[[:space:]]+DELETE'

    # ========================================
    # Helm destructive operations
    # ========================================
    'helm[[:space:]]+uninstall'
    'helm[[:space:]]+delete'
    'helm[[:space:]]+rollback'
    'helm[[:space:]]+repo[[:space:]]+remove'

    # ========================================
    # Azure DevOps CLI (az devops)
    # ========================================
    'az[[:space:]]+boards[[:space:]]+work-item[[:space:]]+delete'
    'az[[:space:]]+artifacts[[:space:]]+.*[[:space:]]+delete'
)

for pattern in "${dangerous_patterns[@]}"; do
    if echo "$command" | grep -qE "$pattern"; then
        play_sound "warning"

        cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "Destructive cloud operation detected. This command can delete or stop resources. Allow Claude to proceed?"
}
EOF
        exit 0
    fi
done

exit 0

#!/bin/bash
# pre-tool-cloud-ops.sh - Block dangerous cloud operations
# PreToolUse on Bash - Blocks destructive cloud commands only

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Dangerous cloud command patterns (destructive operations only)
dangerous_patterns=(
    # Terraform/Pulumi destructive
    'terraform[[:space:]]+destroy'
    'terraform[[:space:]]+apply[[:space:]]+-auto-approve'
    'pulumi[[:space:]]+destroy'
    'pulumi[[:space:]]+up[[:space:]]+-y'
    'pulumi[[:space:]]+up[[:space:]]+--yes'
    # kubectl destructive
    'kubectl[[:space:]]+delete'
    'kubectl[[:space:]]+drain'
    'kubectl[[:space:]]+cordon'
    'kubectl[[:space:]]+taint'
    'kubectl[[:space:]]+replace[[:space:]]+--force'
    'kubectl[[:space:]]+rollout[[:space:]]+undo'
    # AWS destructive
    'aws[[:space:]]+.*[[:space:]]+delete-'
    'aws[[:space:]]+.*[[:space:]]+terminate-'
    'aws[[:space:]]+.*[[:space:]]+remove-'
    'aws[[:space:]]+s3[[:space:]]+rm'
    'aws[[:space:]]+s3[[:space:]]+rb'
    'aws[[:space:]]+ec2[[:space:]]+stop-instances'
    'aws[[:space:]]+ec2[[:space:]]+terminate-instances'
    'aws[[:space:]]+rds[[:space:]]+delete-db'
    # Azure destructive
    'az[[:space:]]+.*[[:space:]]+delete'
    'az[[:space:]]+group[[:space:]]+delete'
    'az[[:space:]]+vm[[:space:]]+deallocate'
    'az[[:space:]]+vm[[:space:]]+stop'
    # GCloud destructive
    'gcloud[[:space:]]+.*[[:space:]]+delete'
    'gcloud[[:space:]]+compute[[:space:]]+instances[[:space:]]+stop'
    'gcloud[[:space:]]+compute[[:space:]]+instances[[:space:]]+reset'
    'gcloud[[:space:]]+projects[[:space:]]+delete'
)

for pattern in "${dangerous_patterns[@]}"; do
    if echo "$command" | grep -qE "$pattern"; then
        play_sound "warning"

        cat << EOF
{
  "hookSpecificOutput": {
    "permissionDecision": "ask"
  },
  "systemMessage": "Destructive cloud operation detected. This command can delete or stop resources. Allow Claude to proceed?"
}
EOF
        exit 0
    fi
done

exit 0

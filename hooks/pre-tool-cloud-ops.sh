#!/bin/bash
# pre-tool-cloud-ops.sh - Block dangerous cloud and IaC operations
# PreToolUse on Bash - Blocks destructive cloud commands
#
# This hook loads patterns from:
#   hooks/dangerous-patterns/cloud-aws.txt
#   hooks/dangerous-patterns/cloud-gcp.txt
#   hooks/dangerous-patterns/cloud-azure.txt
#   hooks/dangerous-patterns/cloud-github.txt
#   hooks/dangerous-patterns/kubernetes.txt
#   hooks/dangerous-patterns/terraform.txt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"
source "$SCRIPT_DIR/utils/load-patterns.sh"

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Load cloud and infrastructure patterns
load_patterns \
    "cloud-aws" \
    "cloud-gcp" \
    "cloud-azure" \
    "cloud-github" \
    "kubernetes" \
    "terraform"

if check_dangerous_pattern "$command"; then
    play_sound "warning"

    cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "Destructive cloud/infrastructure operation detected. This command can delete or stop resources. Allow Claude to proceed?"
}
EOF
    exit 0
fi

exit 0

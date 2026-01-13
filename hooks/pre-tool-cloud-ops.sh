#!/bin/bash
# pre-tool-cloud-ops.sh - Block cloud operations for confirmation
# Hook #2: PreToolUse on Bash - Blocks az, aws, gcloud, kubectl, terraform, pulumi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Cloud CLI patterns to block (with word boundary after)
# Using space or end-of-string to avoid false positives
cloud_patterns=(
    '^az[[:space:]]'
    '[[:space:]]az[[:space:]]'
    '^aws[[:space:]]'
    '[[:space:]]aws[[:space:]]'
    '^gcloud[[:space:]]'
    '[[:space:]]gcloud[[:space:]]'
    '^kubectl[[:space:]]'
    '[[:space:]]kubectl[[:space:]]'
    '^terraform[[:space:]]'
    '[[:space:]]terraform[[:space:]]'
    '^pulumi[[:space:]]'
    '[[:space:]]pulumi[[:space:]]'
)

for pattern in "${cloud_patterns[@]}"; do
    if echo "$command" | grep -qE "$pattern"; then
        play_sound "warning"

        # Extract the cloud tool name for the message
        tool_name=$(echo "$command" | grep -oE '(^|[[:space:]])(az|aws|gcloud|kubectl|terraform|pulumi)[[:space:]]' | xargs | head -1)

        cat << EOF
{
  "decision": "block",
  "reason": "Cloud operation detected: '$tool_name' command requires confirmation. This hook blocks cloud CLI commands (az, aws, gcloud, kubectl, terraform, pulumi) to prevent accidental infrastructure changes. Review the command and confirm you want to proceed."
}
EOF
        exit 2
    fi
done

exit 0

#!/bin/bash
# prompt-production-warning.sh - Warn about production-related prompts
# Hook #14: UserPromptSubmit - Blocks prompts mentioning production systems

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"

input=$(cat)
user_prompt=$(echo "$input" | jq -r '.user_prompt // ""')

# Production keywords (case-insensitive patterns)
# Using word boundaries to avoid false positives like "reproduction"
prod_patterns=(
    '\bproduction\b'
    '\bprod[[:space:]]+(db|database)\b'
    '\bprod[[:space:]]+(env|environment)\b'
    '\bprod[[:space:]]+(server|cluster)\b'
    '\blive[[:space:]]+(server|database|db|environment|env)\b'
    '\bdeploy[[:space:]]+to[[:space:]]+prod\b'
    '\bpush[[:space:]]+to[[:space:]]+prod\b'
)

for pattern in "${prod_patterns[@]}"; do
    if echo "$user_prompt" | grep -iqE "$pattern"; then
        play_sound "warning"

        cat << 'EOF'
{
  "decision": "block",
  "reason": "PRODUCTION WARNING: Your prompt mentions production systems. Operations on production environments require extra caution and should be done deliberately. Please confirm this is intentional by rephrasing your request to explicitly acknowledge production access (e.g., 'I confirm I want to work with production...')."
}
EOF
        exit 2
    fi
done

exit 0

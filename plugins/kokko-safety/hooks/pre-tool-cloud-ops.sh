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
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
# shellcheck source=utils/hook-preamble.sh
source "$SCRIPT_DIR/utils/hook-preamble.sh"
require_jq_or_ask
read_input_or_ask
# shellcheck source=utils/play-sound.sh
source "$SCRIPT_DIR/utils/play-sound.sh"
# shellcheck source=utils/load-patterns.sh
source "$SCRIPT_DIR/utils/load-patterns.sh"

command=$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_input.command // ""')

# Load cloud and infrastructure patterns
load_patterns \
    "cloud-aws" \
    "cloud-gcp" \
    "cloud-azure" \
    "cloud-github" \
    "kubernetes" \
    "terraform"

if check_dangerous_pattern "$command"; then
    play_sound "warning" || true
    emit_ask "Destructive cloud/infrastructure operation detected: matched pattern '${MATCHED_PATTERN}' from category '${MATCHED_CATEGORY}'. This command can delete or stop resources. Allow Claude to proceed?"
    exit 0
fi

exit 0

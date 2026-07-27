#!/usr/bin/env bash
# guard-cloud.sh — block destructive cloud and IaC operations.
# PreToolUse on Bash.
#
# Categories: cloud-aws, cloud-azure, cloud-gcp, cloud-github, kubernetes,
# terraform. See hooks/dangerous-patterns/.
#
# WHY DENY RATHER THAN ASK
# ------------------------
# Same argument as guard-git.sh. Under `defaultMode: acceptEdits` an "ask"
# either stalls an unattended agent or gets clicked through unread, and an
# agent that planned `az group delete` as step 4 of its own workflow will
# confirm it with total confidence. Deleting a resource group is not
# reflog-recoverable.
#
# Override (humans only, deliberately verbose and greppable):
#   CLAUDE_CLOUD_GUARD=off az group delete ...
set -uo pipefail

HOOK_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# shellcheck source=lib/hook-io.sh
source "$HOOK_LIB/hook-io.sh"
# shellcheck source=lib/patterns.sh
source "$HOOK_LIB/patterns.sh"
# shellcheck source=lib/play-sound.sh
source "$HOOK_LIB/play-sound.sh"

read_hook_input
hook_command || exit 0

guard_disabled CLAUDE_CLOUD_GUARD && exit 0

load_patterns \
    "cloud-aws" \
    "cloud-azure" \
    "cloud-gcp" \
    "cloud-github" \
    "kubernetes" \
    "terraform"

if check_dangerous_pattern "$HOOK_COMMAND"; then
    play_sound "warning"
    deny "BLOCKED: this deletes, stops or replaces cloud infrastructure, and there is no undo. Matched a destructive-operation pattern for cloud/IaC. If this is genuinely intended, tell the user exactly which resources it affects and let them run it, or re-run with CLAUDE_CLOUD_GUARD=off prefixed."
fi

exit 0

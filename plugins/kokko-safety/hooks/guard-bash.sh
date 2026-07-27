#!/usr/bin/env bash
# guard-bash.sh — block destructive shell operations.
# PreToolUse on Bash.
#
# Categories: file-operations, disk-storage, permissions, users,
# system-services, databases, docker, shell-security.
# See hooks/dangerous-patterns/.
#
# WHAT IS DELIBERATELY *NOT* GUARDED
# ----------------------------------
# Three categories were removed rather than converted, because every one of
# them fired on routine development work and a guard that fires on routine work
# gets switched off wholesale:
#
#   packages.txt   `pip uninstall`, `npm prune`, `poetry remove`, `brew
#                  cleanup`, `go clean -cache`. Uninstalling a package does not
#                  destroy work; it is a normal step in dependency debugging.
#   process.txt    `killall`, `pkill`, `kill -9`. This is how you manage a dev
#                  server. Its genuinely dangerous entries (`kill -9 1`,
#                  drop_caches, oom_score_adj) are unreachable in a container.
#   networking.txt `unset http_proxy`, `tailscale down`, `dscacheutil
#                  -flushcache`, interface teardown. Inside a devcontainer none
#                  of this reaches the host, and the proxy entries fire on
#                  ordinary shell setup.
#
# git.txt was removed too: guard-git.sh supersedes it with anchored,
# dirty-tree-aware rules, and git.txt's `git worktree remove|prune` entries
# blocked kokko-janitor's own worktree workflow.
#
# Override (humans only, deliberately verbose and greppable):
#   CLAUDE_BASH_GUARD=off rm -rf ./build
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

guard_disabled CLAUDE_BASH_GUARD && exit 0

load_patterns \
    "file-operations" \
    "disk-storage" \
    "permissions" \
    "users" \
    "system-services" \
    "databases" \
    "docker" \
    "shell-security"

if check_dangerous_pattern "$HOOK_COMMAND"; then
    play_sound "warning"
    deny "BLOCKED: this deletes files, destroys credentials, drops database state, or changes system configuration in a way that is not recoverable. Narrow it to explicit paths, or tell the user what it would do and let them run it. To override: prefix the command with CLAUDE_BASH_GUARD=off."
fi

exit 0

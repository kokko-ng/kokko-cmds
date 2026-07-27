#!/usr/bin/env bash
# git-snapshot.sh — checkpoint uncommitted tracked changes into a real git object.
#
# WHY THIS EXISTS
# ---------------
# rebase/reset/checkout/stash silently overwrite tracked files. Uncommitted work
# was never a git object, so there is no reflog entry, no dangling blob, and
# `git fsck` cannot find it. It is simply gone. That has destroyed hours of work
# on real projects, repeatedly.
#
# `git stash create` builds a commit from the current tracked changes WITHOUT
# touching the working tree, the index, or the stash ref. Pointing a ref at it
# makes the work a first-class git object that survives every destructive
# command. This runs before git commands and on every user turn, so the window
# in which work exists only in the working tree stays small.
#
# Untracked files are deliberately NOT captured: rebase/reset/checkout only ever
# touch tracked paths, so untracked work is not at risk from them. (`git clean`
# is the exception — guard-git.sh denies it.)
#
# Recover with:  git stash apply <ref>     (see: snaps, or `git for-each-ref
# refs/snapshots/` if the snaps wrapper is not installed)
set -uo pipefail

HOOK_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# shellcheck source=lib/hook-io.sh
source "$HOOK_LIB/hook-io.sh"

read_hook_input
input="$HOOK_INPUT"

command -v jq >/dev/null 2>&1 || exit 0
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    # Distinguish "not a repo" (fine, stay silent) from "git refuses to
    # operate" (dubious ownership on a host-uid bind mount). The latter means
    # NOTHING is being checkpointed — a safety net that fails silently is
    # worse than none, because everyone assumes it is working. Say so on
    # stdout: for UserPromptSubmit hooks that lands in Claude's context, so
    # the broken state gets surfaced instead of discovered after data loss.
    err=$(git rev-parse --git-dir 2>&1 >/dev/null || true)
    printf '%s' "$err" | grep -qi 'dubious ownership' && \
        echo "WARNING: git-snapshot.sh cannot checkpoint this repository — git reports 'dubious ownership' (workspace owned by a different uid). Uncommitted work is NOT protected until this is fixed: git config --global --add safe.directory <workspace>"
    exit 0
fi

event=$(printf '%s' "$input" | jq -r '.hook_event_name // ""' 2>/dev/null || echo "")
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# On Bash calls, only snapshot when git is actually about to run — snapshotting
# before every `ls` would be pure overhead. UserPromptSubmit always snapshots,
# which also covers git invoked indirectly (scripts, Makefiles, python).
if [[ "$event" == "PreToolUse" ]]; then
    printf '%s' "$cmd" | grep -qE '(^|[^[:alnum:]_.-])git([^[:alnum:]_-]|$)' || exit 0
fi

# stash create needs at least one commit to base the snapshot on.
git rev-parse --verify -q HEAD >/dev/null 2>&1 || exit 0

# Empty output means a clean tree: nothing to checkpoint.
snap=$(git stash create "claude-snapshot" 2>/dev/null) || exit 0
[[ -n "$snap" ]] || exit 0

# Skip if the tree is byte-identical to the newest snapshot, so a burst of git
# commands does not create a burst of duplicate refs.
newest=$(git for-each-ref --sort=-refname --count=1 --format='%(objectname)' refs/snapshots/ 2>/dev/null || true)
if [[ -n "$newest" ]]; then
    new_tree=$(git rev-parse "$snap^{tree}" 2>/dev/null || true)
    old_tree=$(git rev-parse "$newest^{tree}" 2>/dev/null || true)
    [[ -n "$new_tree" && "$new_tree" == "$old_tree" ]] && exit 0
fi

# The object id suffix keeps two snapshots taken within the same second from
# silently overwriting one another; the timestamp prefix keeps refname sort
# order chronological.
git update-ref "refs/snapshots/$(date -u +%Y%m%dT%H%M%SZ)-${snap:0:7}" "$snap" 2>/dev/null || true

# Retain the most recent 200. Snapshots are cheap (one commit object reusing
# existing blobs), but unbounded refs slow every ref walk down.
git for-each-ref --sort=-refname --format='%(refname)' refs/snapshots/ 2>/dev/null \
    | tail -n +201 \
    | while read -r ref; do git update-ref -d "$ref" 2>/dev/null || true; done

exit 0

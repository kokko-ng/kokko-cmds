#!/bin/bash
# git-snapshot.sh - Checkpoint uncommitted tracked changes into a real git object.
# PreToolUse on Bash (git commands only) + UserPromptSubmit (always)
#
# WHY
# ---
# rebase/reset/checkout/restore/stash silently overwrite tracked files. For
# COMMITTED work that is survivable -- the reflog has it. For UNCOMMITTED work it
# is terminal: those changes were never a git object, so there is no reflog
# entry, no dangling blob, and `git fsck` cannot find them. They are simply gone.
#
# Every other hook in this plugin tries to recognise a dangerous command before
# it runs. That approach can only ever block what someone thought to list, and
# it is blind to git invoked from a script, a Makefile, or a subprocess. This
# hook inverts the problem: it makes the work safe BEFORE anything runs, so it
# does not matter what the command turns out to be.
#
# `git stash create` builds a commit from the current changes WITHOUT touching
# the working tree, the index, or the stash ref. Pointing a ref at it promotes
# uncommitted work to a first-class git object, which survives every destructive
# command by definition.
#
# Untracked files are deliberately not captured: rebase/reset/checkout only touch
# tracked paths. (`git clean` is the exception -- pre-tool-destructive-git.sh
# denies it outright, since there would be no safety net.)
#
# Recover with:  git stash apply <ref>
# List with:     git for-each-ref refs/snapshots/

# Defer to the devcontainer's own copy of this hook when present, so projects
# running in that container do not snapshot twice per command.
[[ -x /home/vscode/.claude/hooks/git-snapshot.sh ]] && exit 0

input=$(cat 2>/dev/null)

command -v jq >/dev/null 2>&1 || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

event=$(echo "$input" | jq -r '.hook_event_name // ""' 2>/dev/null)
command=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

# On Bash calls, only snapshot when git is about to run -- snapshotting before
# every `ls` is pure overhead. UserPromptSubmit always snapshots, which also
# covers git invoked indirectly.
if [ "$event" = "PreToolUse" ]; then
    echo "$command" | grep -qE '(^|[^[:alnum:]_.-])git([^[:alnum:]_-]|$)' || exit 0
fi

# stash create needs a commit to base the snapshot on.
git rev-parse --verify -q HEAD >/dev/null 2>&1 || exit 0

# Empty output means a clean tree: nothing to checkpoint.
snap=$(git stash create "claude-snapshot" 2>/dev/null) || exit 0
[ -n "$snap" ] || exit 0

# Skip when the tree is identical to the newest snapshot, so a burst of git
# commands does not produce a burst of duplicate refs.
newest=$(git for-each-ref --sort=-refname --count=1 --format='%(objectname)' refs/snapshots/ 2>/dev/null)
if [ -n "$newest" ]; then
    new_tree=$(git rev-parse "$snap^{tree}" 2>/dev/null)
    old_tree=$(git rev-parse "$newest^{tree}" 2>/dev/null)
    [ -n "$new_tree" ] && [ "$new_tree" = "$old_tree" ] && exit 0
fi

# The object id suffix stops two snapshots in the same second from overwriting
# each other; the timestamp prefix keeps refname sort order chronological.
git update-ref "refs/snapshots/$(date -u +%Y%m%dT%H%M%SZ)-$(echo "$snap" | cut -c1-7)" "$snap" 2>/dev/null

# Retain the most recent 200. Snapshots are cheap (one commit reusing existing
# blobs), but unbounded refs slow every ref walk.
git for-each-ref --sort=-refname --format='%(refname)' refs/snapshots/ 2>/dev/null \
    | tail -n +201 \
    | while read -r ref; do git update-ref -d "$ref" 2>/dev/null; done

exit 0

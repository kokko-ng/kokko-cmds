#!/usr/bin/env bash
# guard-git.sh — block git commands that destroy uncommitted work.
#
# DESIGN: deny, and only when it matters.
#
# "deny", not "ask": agents run unattended under acceptEdits, where an "ask"
# either blocks forever or gets clicked through. Every real incident happened
# because rebase was a documented step in an agent's own workflow — it would
# have answered "yes" to a prompt with total confidence.
#
# "only when it matters": these commands are catastrophic ONLY against a dirty
# tree. On a clean tree a rebase is fully reflog-recoverable, so it is allowed
# through silently. A guard that fires on every routine command is noise, and
# noise gets switched off — which is precisely how the pre-existing safety
# plugin ended up disabled and protecting nothing. This fires rarely, and when
# it fires it is right.
#
# Override (humans only, deliberately verbose and greppable):
#   CLAUDE_GIT_GUARD=off git rebase ...
# Prefer committing. git-snapshot.sh has already checkpointed the tree, so even
# a bypass is recoverable — that is the point of having both layers.
set -uo pipefail

HOOK_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# shellcheck source=lib/hook-io.sh
source "$HOOK_LIB/hook-io.sh"

read_hook_input
hook_command || exit 0
cmd="$HOOK_COMMAND"

guard_disabled CLAUDE_GIT_GUARD && exit 0

matches() { printf '%s' "$cmd" | grep -qE "$1"; }

# `git` at a COMMAND position — start of a line, or after a shell operator, or
# quoted behind `sh -c`. Anchoring here is not pedantry: an unanchored `git`
# matches inside string literals (`echo "never git reset --hard"`) and, worse,
# inside other words — `digit restore` contains "git restore". A guard that
# cries wolf on documentation gets switched off.
CMDPOS='(^|[;&|(){}]|[[:space:]]-c[[:space:]]+["'"'"']?)[[:space:]]*'

# ...tolerating the global options that legitimately precede a subcommand.
G="${CMDPOS}"'git[[:space:]]+((-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+)[[:space:]]+)*'

# `snaps` is a convenience wrapper shipped by the kokko devcontainer. Name the
# underlying git command too: this plugin installs anywhere, and a recovery
# instruction that references a command the user does not have is worse than
# no instruction at all.
SNAPS='run `snaps` (or `git for-each-ref refs/snapshots/`)'
RECOVER="Uncommitted tracked changes are present. git-snapshot.sh has checkpointed them ($SNAPS), but do not rely on that: commit the work instead, then retry."

# ---------------------------------------------------------------------------
# Always denied — destructive regardless of whether the tree is dirty.
# ---------------------------------------------------------------------------

# Destroys UNTRACKED files, which snapshots deliberately do not capture. This is
# the one case with no safety net, so it is denied unconditionally.
matches "${G}clean([[:space:]]+-[a-zA-Z]*[fdx])" && \
    deny "BLOCKED: \`git clean\` deletes untracked files. Snapshots only cover TRACKED changes, so there is no recovery path for this one. Delete specific files with \`rm\` instead, after confirming what they are."

# These destroy the history and the snapshot refs themselves — the safety net.
matches "${G}(filter-branch|filter-repo)" && \
    deny "BLOCKED: history rewriting destroys objects and the refs/snapshots/ safety net. Ask the user first."
matches "${G}reflog[[:space:]]+(expire|delete)" && \
    deny "BLOCKED: the reflog is the recovery path for committed work. Do not expire it."
matches "${G}(gc[[:space:]]+.*--prune|prune([[:space:]]|$))" && \
    deny "BLOCKED: pruning deletes unreachable objects, which is exactly what recovery depends on."
matches "${G}update-ref[[:space:]]+-d[[:space:]]+refs/snapshots" && \
    deny "BLOCKED: refs/snapshots/ is the working-tree safety net. Never delete it by hand."

# `(.*[[:space:]])?` rather than `.*` before the flag: the flag can sit
# immediately after `push` (`git push -f origin x`) or later in the argument
# list (`git push origin x -f`). The previous form required a space to be
# consumed separately from the one after `push`, so it matched the second
# spelling and silently missed the first.
matches "${G}push[[:space:]]+(.*[[:space:]])?(--force([[:space:]]|=|$)|--force-with-lease|-f([[:space:]]|$))" && \
    deny "BLOCKED: force-push rewrites the shared remote. Push additively; if a push is rejected, leave it rejected and tell the user."

# The dot must be a COMPLETE argument (`.` or `./`), not a prefix — otherwise
# legitimate dotted paths (`git add .claude/settings.json`, `.gitignore`)
# false-positive as `git add .`.
matches "${G}add[[:space:]]+(\.[/]?([[:space:]]|$)|-A([[:space:]]|$)|--all([[:space:]]|$))" && \
    deny "BLOCKED: \`git add .\` stages everything, including build output, secrets and scratch files. Stage explicit file paths. Note a directory add also sweeps in any UNTRACKED files inside it — prefer naming files."

matches "${G}stash[[:space:]]+(drop|clear)" && \
    deny "BLOCKED: this permanently deletes stashed work. Inspect it first (\`git stash list\`, \`git stash show -p\`)."

# `git stash create` builds a commit object WITHOUT touching the working tree,
# the index or the stash ref. It is what git-snapshot.sh uses to checkpoint --
# denying it would disable the safety net this file advertises. `list` and
# `show` are pure reads. Everything else under `stash` moves work out of the
# tree and is handled with the dirty-tree rules below.
STASH_READONLY='create|list|show'

# ---------------------------------------------------------------------------
# Protected branches — absorbed from the old pre-tool-branch-protection.sh.
#
# Committing straight to main is recoverable, so this asks rather than denies.
# It is the one case in this file where "ask" is right: the operation is
# routinely legitimate (solo repos, docs fixes) and refusing it outright would
# be wrong more often than it was right.
# ---------------------------------------------------------------------------

PROTECTED='main|master|production|prod|release'

# What matters is which branch the operation LANDS on, not which branch happens
# to be checked out. Sitting on main and pushing a feature branch is routine and
# must not prompt; committing onto main, or pushing main itself, is what wants a
# second look.
protected_branch_ask() {
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || true)

    # An explicit refspec naming a protected branch, from any current branch.
    if matches "${G}push[[:space:]]+([^[:space:]]+[[:space:]]+)*($PROTECTED)([[:space:]]|$)"; then
        ask "This pushes directly to a protected branch. Proceed?"
    fi

    [[ -n "$current_branch" ]] || return 0
    printf '%s' "$current_branch" | grep -qE "^($PROTECTED)$" || return 0

    # Committing or merging lands on the checked-out branch by definition.
    matches "${G}(commit|merge)([[:space:]]|$)" && \
        ask "You are on protected branch '${current_branch}'. Run this git command directly on it?"

    # A bare `git push` (no refspec) pushes the current branch, which is
    # protected. `git push -u origin other-branch` names its target and is
    # handled by the refspec check above.
    matches "${G}push([[:space:]]+(-[^[:space:]]+|--[^[:space:]]+))*[[:space:]]*$" && \
        ask "You are on protected branch '${current_branch}' and this pushes it. Proceed?"

    return 0
}
protected_branch_ask

# ---------------------------------------------------------------------------
# Denied only against a dirty tree — safe and allowed on a clean one.
# ---------------------------------------------------------------------------

if git rev-parse --git-dir >/dev/null 2>&1; then
    [[ -n "$(git status --porcelain --untracked-files=no 2>/dev/null | head -1)" ]] || exit 0
else
    # git cannot READ this repository at all. The usual cause is the
    # "dubious ownership" refusal on bind-mounted workspaces owned by the
    # host uid. That must fail CLOSED, not open: the tree may well be dirty,
    # the snapshot hook's git calls are failing identically (so nothing is
    # checkpointed), and an agent can bypass the refusal per-command with
    # `git -c safe.directory=... rebase` — sailing past a guard that cannot
    # see the tree. Treat the tree as dirty until git works again.
    err=$(git rev-parse --git-dir 2>&1 >/dev/null || true)
    printf '%s' "$err" | grep -qi 'dubious ownership' || exit 0
    RECOVER='git itself cannot read this repository ("dubious ownership": the workspace is owned by a different uid than the container user). The dirty-tree check AND the snapshot safety net are both non-functional, so the tree is treated as dirty. Fix first: `git config --global --add safe.directory <workspace>`, verify snapshots work, then retry.'
fi

matches "${G}rebase([[:space:]]|$)" && \
    deny "BLOCKED: \`git rebase\` over a dirty tree silently discards every uncommitted change to a tracked file, with no prompt and no way back. $RECOVER"

matches "${G}reset([[:space:]]|$)" && \
    deny "BLOCKED: \`git reset\` over a dirty tree can discard uncommitted tracked changes. $RECOVER"

matches "${G}(checkout|switch)[[:space:]]+.*(-f([[:space:]]|$)|--force([[:space:]]|$)|--discard-changes)" && \
    deny "BLOCKED: a forced checkout/switch overwrites uncommitted tracked changes. $RECOVER"

matches "${G}checkout([[:space:]]+[^[:space:]-][^[:space:]]*)*[[:space:]]+--[[:space:]]" && \
    deny "BLOCKED: \`git checkout <ref> -- <path>\` silently overwrites that file's uncommitted changes. To keep a copy, use \`cp\`. $RECOVER"

matches "${G}checkout[[:space:]]+\.([[:space:]]|$)" && \
    deny "BLOCKED: \`git checkout .\` discards all uncommitted tracked changes. $RECOVER"

matches "${G}restore([[:space:]]|$)" && \
    deny "BLOCKED: \`git restore\` overwrites uncommitted changes from another revision. Use \`cp\` to back up and restore files. $RECOVER"

if ! matches "${G}stash[[:space:]]+($STASH_READONLY)([[:space:]]|$)"; then
    matches "${G}stash([[:space:]]|$)" && \
        deny "BLOCKED: \`git stash\` was load-bearing in past data-loss incidents and is easy to forget to pop. Commit instead — commits are cheap, reversible, and visible. (\`git stash create|list|show\` are allowed: they do not move work out of the tree.)"
fi

matches "${G}branch[[:space:]]+(-f|--force)([[:space:]]|$)" && \
    deny "BLOCKED: \`git branch -f\` silently moves a ref. Ask the user first. $RECOVER"

exit 0

#!/bin/bash
# pre-tool-destructive-git.sh - Block git operations that destroy uncommitted work
# PreToolUse on Bash
#
# Two tiers:
#   DENY  - commands that irrecoverably destroy work. Tree-destroying ones are
#           denied only while the tree is dirty (see below); the rest always.
#   ASK   - everything else in hooks/dangerous-patterns/git.txt.
#
# WHY DENY RATHER THAN ASK
# ------------------------
# This hook used to ask about everything. Two problems with that:
#
#   1. Agents run unattended (acceptEdits, bypassPermissions). An "ask" either
#      stalls the run or is answered "yes" by an agent that is confident -- and
#      it always is, because rebase-and-push is a documented, routine step in
#      many agent workflows. It is not being reckless. It will not hesitate.
#   2. Uncommitted tracked changes are unrecoverable once overwritten: never a
#      git object, so no reflog, no dangling blob, nothing for fsck. A prompt is
#      not a proportionate control for an irreversible, silent loss.
#
# WHY DIRTY-GATED RATHER THAN BLANKET
# -----------------------------------
# These commands are catastrophic only against a dirty tree; on a clean one the
# reflog has you covered. Gating on that is not leniency -- it is what keeps the
# hook enabled. Warning on ~30 patterns regardless of context is noise, and noise
# gets switched off; this plugin was found disabled in a real settings.json,
# protecting nothing at the moment it was needed. A control you turn off is worse
# than none, because you think you have one. This fires rarely and is right when
# it does.
#
# git-snapshot.sh checkpoints the tree independently, so even a bypass is
# recoverable. Two layers, neither trusted alone.
#
# Override (humans, not agents):  CLAUDE_GIT_GUARD=off git rebase ...

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"
source "$SCRIPT_DIR/utils/load-patterns.sh"

# Defer to the devcontainer's own guard when present, so a container-based
# project does not get two denials for one command.
[[ -x /home/vscode/.claude/hooks/guard-git.sh ]] && exit 0

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')
[ -n "$command" ] || exit 0

[ "${CLAUDE_GIT_GUARD:-on}" = "off" ] && exit 0
echo "$command" | grep -qE '(^|[[:space:];&|(])CLAUDE_GIT_GUARD=off[[:space:]]' && exit 0

# Deliberately silent. A denial already returns a written reason that Claude
# reads and acts on; an alert on top adds nothing, and the sound would fire on
# every blocked command. Alerts are for things a human must notice -- a deny
# needs no human. (The ask tier below keeps its sound: that one does need you.)
deny() {
    jq -n --arg r "$1" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $r
        }
    }'
    exit 0
}

matches() { echo "$command" | grep -qE "$1"; }

# `git` at a COMMAND position: start of a line, after a shell operator, or quoted
# behind `sh -c`. Without this anchor a bare `git` matches inside string literals
# (`echo "never git reset --hard"`) and inside other words -- `digit restore`
# contains the substring "git restore". A hook that cries wolf on documentation
# is a hook that gets disabled.
CMDPOS='(^|[;&|(){}]|[[:space:]]-c[[:space:]]+["'"'"']?)[[:space:]]*'
G="${CMDPOS}"'git[[:space:]]+((-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+)[[:space:]]+)*'

RECOVER='git-snapshot.sh has checkpointed the tree (git for-each-ref refs/snapshots/), but do not rely on that: commit the work instead, then retry.'

# --- Always denied ---------------------------------------------------------

# Destroys UNTRACKED files, which snapshots deliberately do not cover. The one
# case with no safety net, so it is denied regardless of tree state.
matches "${G}clean([[:space:]]+-[a-zA-Z]*[fdx])" && \
    deny "BLOCKED: \`git clean\` deletes untracked files, and snapshots only cover TRACKED changes -- there is no recovery path for this one. Remove specific files with \`rm\` after confirming what they are."

matches "${G}(filter-branch|filter-repo)" && \
    deny "BLOCKED: history rewriting destroys objects and the refs/snapshots/ safety net. Ask the user first."
matches "${G}reflog[[:space:]]+(expire|delete)" && \
    deny "BLOCKED: the reflog is the recovery path for committed work. Do not expire it."
matches "${G}(gc[[:space:]]+.*--prune|prune([[:space:]]|$))" && \
    deny "BLOCKED: pruning deletes unreachable objects, which is exactly what a recovery depends on."
matches "${G}update-ref[[:space:]]+-d[[:space:]]+refs/snapshots" && \
    deny "BLOCKED: refs/snapshots/ is the working-tree safety net. Do not delete it by hand."

matches "${G}push[[:space:]]+.*(--force([[:space:]]|=|$)|--force-with-lease|[[:space:]]-f([[:space:]]|$))" && \
    deny "BLOCKED: force-push rewrites shared history. Push additively; if a push is rejected, that is usually correct -- report it and stop."

matches "${G}add[[:space:]]+(\.|-A([[:space:]]|$)|--all([[:space:]]|$))" && \
    deny "BLOCKED: \`git add .\` stages everything, including build output, secrets and scratch files. Stage explicit paths: \`git add src/ docs/\`."

matches "${G}stash[[:space:]]+(drop|clear)" && \
    deny "BLOCKED: this permanently deletes stashed work. Inspect it first: \`git stash list\`, \`git stash show -p\`."

# --- Denied only against a dirty tree --------------------------------------

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

if [ -n "$(git status --porcelain --untracked-files=no 2>/dev/null | head -1)" ]; then

    matches "${G}rebase([[:space:]]|$)" && \
        deny "BLOCKED: \`git rebase\` over a dirty tree silently discards every uncommitted change to a tracked file, with no prompt and no way back. $RECOVER"

    matches "${G}reset([[:space:]]|$)" && \
        deny "BLOCKED: \`git reset\` over a dirty tree can discard uncommitted tracked changes. $RECOVER"

    matches "${G}(checkout|switch)[[:space:]]+.*(-f([[:space:]]|$)|--force([[:space:]]|$)|--discard-changes)" && \
        deny "BLOCKED: a forced checkout/switch overwrites uncommitted tracked changes. $RECOVER"

    matches "${G}checkout([[:space:]]+[^[:space:]-][^[:space:]]*)*[[:space:]]+--[[:space:]]" && \
        deny "BLOCKED: \`git checkout <ref> -- <path>\` silently overwrites that file's uncommitted changes. Use \`cp\` to back up and restore files. $RECOVER"

    matches "${G}checkout[[:space:]]+\.([[:space:]]|$)" && \
        deny "BLOCKED: \`git checkout .\` discards all uncommitted tracked changes. $RECOVER"

    matches "${G}restore([[:space:]]|$)" && \
        deny "BLOCKED: \`git restore\` overwrites uncommitted changes from another revision. Use \`cp\` instead. $RECOVER"

    matches "${G}stash([[:space:]]|$)" && \
        deny "BLOCKED: \`git stash\` is easy to forget to pop and was load-bearing in past data-loss incidents. Commit instead -- commits are cheap, reversible and visible."

    matches "${G}branch[[:space:]]+(-f|--force)([[:space:]]|$)" && \
        deny "BLOCKED: \`git branch -f\` silently moves a ref. Ask the user first. $RECOVER"
fi

# --- Everything else in git.txt: ask ---------------------------------------
# Anchored at a command position, unlike the shared check_dangerous_pattern.
# Safe to do here because every git.txt pattern begins with `git[[:space:]]`.
load_patterns "git"
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$command" | grep -qiE "${CMDPOS}${pattern}"; then
        play_sound "warning"
        cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "Destructive git operation detected. This could rewrite history or delete branches. Allow Claude to proceed?"
}
EOF
        exit 0
    fi
done

exit 0

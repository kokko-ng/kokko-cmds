#!/usr/bin/env bash
# Fail when a branch changes plugin content without bumping the version.
#
# Usage: scripts/check-version-bumped.sh <base-ref>
#
# The release workflow derives its tag from the version in marketplace.json.
# If plugins change and the version does not, the release either collides with
# an existing tag (and is silently skipped -- `gh release view` succeeds, the
# job exits 0, and nothing ships) or publishes new content under a version
# users already have cached. Neither failure is visible without this check.
#
# Documentation-only and CI-only changes are exempt; they do not ship to anyone
# through the marketplace.
set -uo pipefail

BASE="${1:-origin/main}"
MARKETPLACE=".claude-plugin/marketplace.json"

git rev-parse --verify -q "$BASE" >/dev/null 2>&1 || {
    echo "cannot resolve base ref '$BASE' - skipping version check"
    exit 0
}

changed="$(git diff --name-only "$BASE"...HEAD -- plugins/ || true)"

if [ -z "$changed" ]; then
    echo "No changes under plugins/ - version bump not required."
    exit 0
fi

# A change confined to markdown that is not a command or skill definition is
# documentation. Commands and skills ARE the shipped product, so they count.
shipped=0
while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
        */commands/*|*/SKILL.md|*/hooks/*|*/scripts/*|*plugin.json) shipped=1; break ;;
        *.md) ;;
        *) shipped=1; break ;;
    esac
done <<< "$changed"

if [ "$shipped" -eq 0 ]; then
    echo "Only documentation changed under plugins/ - version bump not required."
    exit 0
fi

base_version="$(git show "$BASE:$MARKETPLACE" 2>/dev/null | jq -r '.plugins[0].version' 2>/dev/null || echo "")"
head_version="$(jq -r '.plugins[0].version' "$MARKETPLACE" 2>/dev/null || echo "")"

if [ -z "$base_version" ] || [ -z "$head_version" ]; then
    echo "could not read the version on one side - skipping"
    exit 0
fi

if [ "$base_version" = "$head_version" ]; then
    echo "ERROR: plugin content changed but the version is still $head_version."
    echo
    echo "Changed files:"
    printf '  %s\n' $changed
    echo
    echo "Run: scripts/bump.sh patch   (or minor / major)"
    exit 1
fi

echo "Version bumped $base_version -> $head_version for a plugin change. OK."
exit 0

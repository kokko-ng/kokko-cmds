#!/usr/bin/env bash
# Bump every plugin version in lockstep, in one place.
#
# Usage:
#   scripts/bump.sh 3.3.0     set an explicit version
#   scripts/bump.sh patch     3.2.0 -> 3.2.1
#   scripts/bump.sh minor     3.2.0 -> 3.3.0
#   scripts/bump.sh major     3.2.0 -> 4.0.0
#
# WHY LOCKSTEP
# ------------
# All plugins in this marketplace share one version. That is a deliberate
# choice -- they are developed together and installed together, and per-plugin
# versions would mean nine changelogs for a personal toolkit. The cost is that
# a bump touches ten files, which is exactly the kind of thing that gets done
# by hand, half-done, and then ships a marketplace.json disagreeing with the
# manifests it points at.
#
# So: one command does all ten, `check-marketplace-sync.sh` proves they agree,
# and `check-version-bumped.sh` proves a plugin change did not skip the bump.
set -euo pipefail

MARKETPLACE=".claude-plugin/marketplace.json"
CHANGELOG="CHANGELOG.md"

[ -f "$MARKETPLACE" ] || { echo "run from the repo root" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

current="$(jq -r '.plugins[0].version' "$MARKETPLACE")"

usage() {
    sed -n '3,9p' "$0" | sed 's/^# \?//'
    echo
    echo "current version: $current"
}

[ $# -eq 1 ] || { usage; exit 2; }

case "$1" in
    major|minor|patch)
        IFS=. read -r maj min pat <<< "$current"
        case "$1" in
            major) new="$((maj + 1)).0.0" ;;
            minor) new="${maj}.$((min + 1)).0" ;;
            patch) new="${maj}.${min}.$((pat + 1))" ;;
        esac
        ;;
    [0-9]*.[0-9]*.[0-9]*) new="$1" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "not a version or bump keyword: $1" >&2; usage; exit 2 ;;
esac

if [ "$new" = "$current" ]; then
    echo "already at $new - nothing to do"
    exit 0
fi

echo "Bumping $current -> $new"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

jq --arg v "$new" '.plugins |= map(.version = $v)' "$MARKETPLACE" > "$tmp"
mv "$tmp" "$MARKETPLACE"
echo "  updated $MARKETPLACE"

while read -r manifest; do
    tmp="$(mktemp)"
    jq --arg v "$new" '.version = $v' "$manifest" > "$tmp"
    mv "$tmp" "$manifest"
    echo "  updated $manifest"
done < <(find plugins -name plugin.json -path '*/.claude-plugin/*' | sort)

# Seed a changelog entry rather than writing it: the person bumping knows what
# changed, and a generated "various fixes" line is worse than a blank one.
# Skip when an entry for this version already exists -- writing the changelog
# before running the bump is a perfectly normal order to work in.
if [ -f "$CHANGELOG" ] && grep -q "^## $new\b" "$CHANGELOG"; then
    echo "  $CHANGELOG already has an entry for $new - left alone"
elif [ -f "$CHANGELOG" ]; then
    tmp="$(mktemp)"
    {
        head -n "$(grep -n '^## ' "$CHANGELOG" | head -1 | cut -d: -f1 | awk '{print $1-1}')" "$CHANGELOG"
        echo "## $new - unreleased"
        echo
        echo "- TODO: describe this release"
        echo
        tail -n +"$(grep -n '^## ' "$CHANGELOG" | head -1 | cut -d: -f1)" "$CHANGELOG"
    } > "$tmp"
    mv "$tmp" "$CHANGELOG"
    echo "  seeded $CHANGELOG - fill in the entry before committing"
fi

echo
bash scripts/check-marketplace-sync.sh
echo
echo "Next: fill in $CHANGELOG, commit, and tag v$new"

#!/usr/bin/env bash
# Bump the lock-step version everywhere it lives: every entry in
# .claude-plugin/marketplace.json and every plugins/*/.claude-plugin/plugin.json.
# Usage: scripts/bump-version.sh <new-version>
# All JSON files are jq-canonical (2-space indent), so jq output round-trips
# without formatting churn.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <new-version>" >&2
  exit 2
fi

new_version="$1"
if ! printf '%s' "$new_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "ERROR: '$new_version' is not a semver X.Y.Z version" >&2
  exit 2
fi

cd "$(dirname "$0")/.."

MARKETPLACE=".claude-plugin/marketplace.json"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

jq --arg v "$new_version" '.plugins[].version = $v' "$MARKETPLACE" > "$tmp"
cp "$tmp" "$MARKETPLACE"
echo "updated $MARKETPLACE"

for manifest in plugins/*/.claude-plugin/plugin.json; do
  jq --arg v "$new_version" '.version = $v' "$manifest" > "$tmp"
  cp "$tmp" "$manifest"
  echo "updated $manifest"
done

bash scripts/check-marketplace-sync.sh

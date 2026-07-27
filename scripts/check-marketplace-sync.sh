#!/usr/bin/env bash
# Verify marketplace.json stays in sync with each plugin's plugin.json
# (same version and description for every listed plugin).
set -euo pipefail

MARKETPLACE=".claude-plugin/marketplace.json"
FAIL=0

for name in $(jq -r '.plugins[].name' "$MARKETPLACE"); do
  source_dir=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .source' "$MARKETPLACE")
  manifest="${source_dir%/}/.claude-plugin/plugin.json"

  if [ ! -f "$manifest" ]; then
    echo "ERROR: $name: manifest not found at $manifest"
    FAIL=1
    continue
  fi

  mp_version=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .version' "$MARKETPLACE")
  pl_version=$(jq -r '.version' "$manifest")
  if [ "$mp_version" != "$pl_version" ]; then
    echo "ERROR: $name: version mismatch (marketplace=$mp_version, plugin.json=$pl_version)"
    FAIL=1
  fi

  mp_desc=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .description' "$MARKETPLACE")
  pl_desc=$(jq -r '.description' "$manifest")
  if [ "$mp_desc" != "$pl_desc" ]; then
    echo "ERROR: $name: description differs between marketplace.json and plugin.json"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "marketplace.json is in sync with all plugin manifests"
fi
exit "$FAIL"

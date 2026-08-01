#!/usr/bin/env bash
# Verify marketplace.json stays in sync with each plugin's plugin.json:
#   - every marketplace entry has a manifest with the same name, version,
#     and description
#   - every plugins/*/ directory is listed in marketplace.json
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

  pl_name=$(jq -r '.name' "$manifest")
  if [ "$pl_name" != "$name" ]; then
    echo "ERROR: $name: plugin.json name is '$pl_name' but marketplace entry is '$name'"
    FAIL=1
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

# Reverse direction: every plugin directory must be listed in marketplace.json,
# otherwise a plugin silently never ships.
if [ -d plugins ]; then
  for dir in plugins/*/; do
    [ -d "$dir" ] || continue
    norm="${dir%/}"
    if ! jq -e --arg d "$norm" \
        '[.plugins[].source | sub("^\\./"; "") | sub("/$"; "")] | index($d)' \
        "$MARKETPLACE" >/dev/null; then
      echo "ERROR: $norm exists but is not listed in $MARKETPLACE"
      FAIL=1
    fi
  done
fi

if [ "$FAIL" -eq 0 ]; then
  echo "marketplace.json is in sync with all plugin manifests"
fi
exit "$FAIL"

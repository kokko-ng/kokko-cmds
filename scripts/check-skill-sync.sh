#!/usr/bin/env bash
# Verify the shared language-detection block stays byte-identical across all
# kokko-code-quality skills. The six SKILL.md files carry the same detection
# scaffold on purpose; deliberate per-skill deltas live OUTSIDE the markers.
# Unenforced, the copies drift (one skill checked tsconfig.json, the others
# did not) and deliberate deltas become indistinguishable from accidents.
set -euo pipefail

START='<!-- shared:language-detection start'
END='<!-- shared:language-detection end -->'

FAIL=0
ref=""
ref_file=""
count=0

for f in plugins/kokko-code-quality/skills/*/SKILL.md; do
  count=$((count + 1))
  region=$(awk -v s="$START" -v e="$END" \
    'index($0, s)==1 {on=1} on {print} index($0, e)==1 {on=0}' "$f")
  if [ -z "$region" ]; then
    echo "ERROR: $f has no shared:language-detection block"
    FAIL=1
    continue
  fi
  if [ -z "$ref" ]; then
    ref="$region"
    ref_file="$f"
    continue
  fi
  if [ "$region" != "$ref" ]; then
    echo "ERROR: shared language-detection block in $f differs from $ref_file:"
    diff <(printf '%s\n' "$ref") <(printf '%s\n' "$region") | sed 's/^/  /' | head -20
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "shared language-detection block is in sync across $count skills"
fi
exit "$FAIL"

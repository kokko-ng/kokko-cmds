#!/usr/bin/env bash
# Verify every copy of a shared hook library is byte-identical.
#
# A Claude Code plugin cannot source a file from a sibling plugin's directory,
# and a symlink pointing outside the plugin root does not survive plugin
# install. So genuinely shared helpers are duplicated -- and duplicated files
# drift. play-sound.sh drifted for long enough that one copy kept a 10x afplay
# gain default and no mute switch after the other was fixed, while the README
# documented the fixed behaviour as if it applied everywhere.
#
# This is the check that makes the duplication safe. Add a shared file by
# listing its basename in SHARED_FILES.
set -uo pipefail

SHARED_FILES=(
    "play-sound.sh"
)

FAIL=0

for name in "${SHARED_FILES[@]}"; do
    mapfile -t copies < <(find plugins -type f -path '*/hooks/lib/*' -name "$name" | sort)

    if [ "${#copies[@]}" -eq 0 ]; then
        echo "ERROR: $name is listed as shared but no copy exists under plugins/*/hooks/lib/"
        FAIL=1
        continue
    fi

    if [ "${#copies[@]}" -eq 1 ]; then
        echo "OK: $name (single copy: ${copies[0]})"
        continue
    fi

    reference="${copies[0]}"
    ref_sum="$(md5sum "$reference" | cut -d' ' -f1)"
    drifted=()

    for copy in "${copies[@]:1}"; do
        if [ "$(md5sum "$copy" | cut -d' ' -f1)" != "$ref_sum" ]; then
            drifted+=("$copy")
        fi
    done

    if [ "${#drifted[@]}" -gt 0 ]; then
        echo "ERROR: $name has drifted between plugins."
        echo "  reference: $reference"
        for copy in "${drifted[@]}"; do
            echo "  differs:   $copy"
            diff -u "$reference" "$copy" | sed 's/^/    /' || true
        done
        echo "  Fix: copy the intended version over the others, then re-run."
        FAIL=1
    else
        echo "OK: $name (${#copies[@]} identical copies)"
    fi
done

if [ "$FAIL" -eq 0 ]; then
    echo "All shared hook libraries are in sync."
fi
exit "$FAIL"

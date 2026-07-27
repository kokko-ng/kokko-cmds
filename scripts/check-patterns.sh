#!/usr/bin/env bash
# Lint the dangerous-patterns/ files.
#
# Every line in these files becomes part of a regex that decides whether to
# block a command. A malformed one is worse than useless: `grep -f` fails on the
# whole file, so ONE bad pattern silently disables an entire guard. Nothing
# previously checked that.
#
# Checks:
#   1. Every pattern compiles as an ERE (with the command-position anchor that
#      lib/patterns.sh prepends at runtime).
#   2. No pattern is anchored with ^ -- lib/patterns.sh supplies the anchor, and
#      a stray ^ mid-pattern can never match.
#   3. No pattern is so short it would match almost anything.
#   4. Every category file referenced by a guard hook actually exists.
set -uo pipefail

PATTERNS_DIR="plugins/kokko-safety/hooks/dangerous-patterns"
HOOKS_DIR="plugins/kokko-safety/hooks"
CMDPOS='(^|[;&|(){}<>]|[[:space:]]-c[[:space:]]+["'"'"']?)[[:space:]]*'
MIN_LENGTH=4
FAIL=0
count=0

for file in "$PATTERNS_DIR"/*.txt; do
    [ -f "$file" ] || continue
    lineno=0
    while IFS= read -r line || [ -n "$line" ]; do
        lineno=$((lineno + 1))
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        case "$line" in [[:space:]]*\#*) continue ;; esac

        count=$((count + 1))

        # 1. Does it compile, with the runtime anchor attached?
        #    grep exits 1 for "no match" and 2 for "bad regex" -- only the
        #    latter is a failure here.
        printf '' | grep -qE "${CMDPOS}${line#\\b}" 2>/dev/null
        if [ "$?" -eq 2 ]; then
            echo "ERROR: $file:$lineno: not a valid ERE once anchored: $line"
            FAIL=1
            continue
        fi

        # 2. A leading ^ fights the anchor lib/patterns.sh prepends.
        case "$line" in
            ^*)
                echo "ERROR: $file:$lineno: starts with ^; lib/patterns.sh supplies the anchor: $line"
                FAIL=1
                ;;
        esac

        # 3. Suspiciously broad.
        stripped="${line//\[\[:space:\]\]/ }"
        if [ "${#stripped}" -lt "$MIN_LENGTH" ]; then
            echo "ERROR: $file:$lineno: pattern is too short to be specific: $line"
            FAIL=1
        fi
    done < "$file"
done

# 4. Every category a hook loads must exist, or the guard silently covers less
#    than its own documentation claims.
while read -r category; do
    [ -n "$category" ] || continue
    if [ ! -f "$PATTERNS_DIR/${category}.txt" ]; then
        echo "ERROR: a guard hook loads category '$category' but $PATTERNS_DIR/${category}.txt does not exist"
        FAIL=1
    fi
done < <(grep -hoE '^\s+"[a-z-]+"\s*\\?$' "$HOOKS_DIR"/guard-*.sh 2>/dev/null | tr -d ' "\\')

# And every file present should be loaded by something, or it is dead weight
# that looks like protection.
for file in "$PATTERNS_DIR"/*.txt; do
    [ -f "$file" ] || continue
    base="$(basename "$file" .txt)"
    if ! grep -qE "\"$base\"" "$HOOKS_DIR"/guard-*.sh 2>/dev/null; then
        echo "ERROR: $file is not loaded by any guard hook (dead patterns read as protection)"
        FAIL=1
    fi
done

if [ "$FAIL" -eq 0 ]; then
    echo "All $count patterns compile and every category is wired to a guard."
fi
exit "$FAIL"

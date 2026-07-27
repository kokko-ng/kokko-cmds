#!/bin/bash
# patterns.sh - load dangerous-command patterns and match a command against them.
#
# TWO THINGS THIS FIXES over the naive version.
#
# 1. ONE grep, not one per pattern. The old loop ran `echo "$cmd" | grep` once
#    per pattern -- with ~1,300 patterns loaded that is ~2,600 processes on
#    EVERY Bash tool call, in a PreToolUse hook, in the interactive path.
#    grep -f reads them all into a single automaton and runs once.
#
# 2. Patterns are anchored to a COMMAND POSITION and matched case-SENSITIVELY.
#    The old matcher used `grep -qiE` with unanchored patterns, so
#    `echo "never run kill -9"` tripped the process guard, `cat notes.md`
#    containing "aws s3 rm" tripped the cloud guard, and every pattern also
#    matched its own uppercase spelling. A guard that cries wolf on prose is a
#    guard that gets switched off -- which is how the previous version of this
#    plugin ended up disabled and protecting nothing.
#
# The anchor mirrors guard-git.sh's: start of string, after a shell operator,
# or quoted behind `sh -c`.

_PATTERNS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_DIR="${PATTERNS_DIR:-$_PATTERNS_LIB_DIR/../dangerous-patterns}"

# A command sits at a command position if it starts the string or follows a
# shell operator. Also tolerate `sh -c '...'` and a leading `sudo`/`env`, which
# are how a command gets smuggled past a naive anchor.
PATTERN_CMDPOS='(^|[;&|(){}<>]|[[:space:]]-c[[:space:]]+["'"'"']?)[[:space:]]*(sudo[[:space:]]+|env[[:space:]]+[A-Za-z_]+=[^[:space:]]*[[:space:]]+)*'

# Build a single grep -E pattern file from the named categories.
# Sets PATTERN_FILE to its path; the caller is responsible for nothing, the
# EXIT trap cleans up.
load_patterns() {
    PATTERN_FILE="$(mktemp)"
    # shellcheck disable=SC2064  # expand PATTERN_FILE now, not at trap time
    trap "rm -f '$PATTERN_FILE'" EXIT

    local category file line
    for category in "$@"; do
        file="$PATTERNS_DIR/${category}.txt"
        [[ -f "$file" ]] || continue
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            # Patterns are written to start at the command name. A leading \b
            # is redundant once the command-position anchor is prepended, and
            # \b immediately after a bracket expression is not portable.
            line="${line#\\b}"
            printf '%s%s\n' "$PATTERN_CMDPOS" "$line"
        done < "$file"
    done > "$PATTERN_FILE"
}

# Load every category present in the patterns directory.
load_all_patterns() {
    local names=()
    local f
    for f in "$PATTERNS_DIR"/*.txt; do
        [[ -f "$f" ]] || continue
        f="${f##*/}"
        names+=("${f%.txt}")
    done
    load_patterns "${names[@]}"
}

# check_dangerous_pattern <command> - 0 if the command matches any loaded
# pattern. Case-sensitive by design (see header).
check_dangerous_pattern() {
    [[ -s "$PATTERN_FILE" ]] || return 1
    printf '%s' "$1" | grep -qE -f "$PATTERN_FILE"
}

# matched_pattern <command> - echo the first pattern that matched, for use in
# the deny message. Only called on the deny path, so its cost does not matter.
matched_pattern() {
    printf '%s' "$1" | grep -oE -f "$PATTERN_FILE" 2>/dev/null | head -1
}

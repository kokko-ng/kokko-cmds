#!/bin/bash
# load-patterns.sh - Load dangerous command patterns from text files
# Usage: source this file, then call load_patterns "category1" "category2" ...
# Or call load_all_patterns to load everything
#
# MATCHED_PATTERN/MATCHED_CATEGORY are consumed by the sourcing hook, not here:
# shellcheck disable=SC2034

# Get the directory containing this script, then navigate to dangerous-patterns
_LOAD_PATTERNS_SCRIPT_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
PATTERNS_DIR="$_LOAD_PATTERNS_SCRIPT_DIR/../dangerous-patterns"

# Populated by load_patterns/load_all_patterns (parallel arrays)
DANGEROUS_PATTERNS=()
DANGEROUS_PATTERN_CATEGORIES=()

# Set by check_dangerous_pattern when a pattern matches; read by the sourcing
# hook when it builds the permission-decision reason.
MATCHED_PATTERN=""
MATCHED_CATEGORY=""

# Append every non-comment line of a pattern file to the global arrays.
# Arguments: category name, file path
_append_pattern_file() {
    local category="$1" file="$2" line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        DANGEROUS_PATTERNS+=("$line")
        DANGEROUS_PATTERN_CATEGORIES+=("$category")
    done < "$file"
}

# Load patterns from specific category files
# Arguments: category names without .txt extension
# Returns: patterns in the global DANGEROUS_PATTERNS array
load_patterns() {
    DANGEROUS_PATTERNS=()
    DANGEROUS_PATTERN_CATEGORIES=()
    local category file
    for category in "$@"; do
        file="$PATTERNS_DIR/${category}.txt"
        if [[ -f "$file" ]]; then
            _append_pattern_file "$category" "$file"
        else
            echo "kokko-safety: pattern file not found (category '$category'): $file" >&2
        fi
    done
}

# Load all patterns from all .txt files in the patterns directory
load_all_patterns() {
    DANGEROUS_PATTERNS=()
    DANGEROUS_PATTERN_CATEGORIES=()
    local file category
    for file in "$PATTERNS_DIR"/*.txt; do
        [[ -f "$file" ]] || continue
        category="${file##*/}"
        category="${category%.txt}"
        _append_pattern_file "$category" "$file"
    done
}

# Check if a command matches any loaded pattern.
# Arguments: command string
# Returns: 0 if match found (MATCHED_PATTERN/MATCHED_CATEGORY are set),
#          1 otherwise.
# The command is fed to grep with printf (not echo) so a command starting
# with -n/-e is matched verbatim instead of being eaten as an echo option.
# A pattern that is not a valid ERE (grep exit status >= 2) is reported to
# stderr instead of being silently skipped as a dead pattern.
check_dangerous_pattern() {
    local command="$1"
    MATCHED_PATTERN=""
    MATCHED_CATEGORY=""
    local i status
    for i in ${DANGEROUS_PATTERNS[@]+"${!DANGEROUS_PATTERNS[@]}"}; do
        if printf '%s\n' "$command" | grep -qiE -- "${DANGEROUS_PATTERNS[$i]}"; then
            MATCHED_PATTERN="${DANGEROUS_PATTERNS[$i]}"
            MATCHED_CATEGORY="${DANGEROUS_PATTERN_CATEGORIES[$i]}"
            return 0
        else
            status=${PIPESTATUS[1]}
            if [[ "$status" -ge 2 ]]; then
                echo "kokko-safety: invalid pattern in ${DANGEROUS_PATTERN_CATEGORIES[$i]}.txt (grep exit $status): ${DANGEROUS_PATTERNS[$i]}" >&2
            fi
        fi
    done
    return 1
}

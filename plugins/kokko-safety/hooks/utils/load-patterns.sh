#!/bin/bash
# load-patterns.sh - Load dangerous command patterns from text files
# Usage: source this file, then call load_patterns "category1" "category2" ...
#
# MATCHED_PATTERN/MATCHED_CATEGORY are consumed by the sourcing hook, not here:
# shellcheck disable=SC2034

# Get the directory containing this script, then navigate to dangerous-patterns
_LOAD_PATTERNS_SCRIPT_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
PATTERNS_DIR="$_LOAD_PATTERNS_SCRIPT_DIR/../dangerous-patterns"

# Populated by load_patterns (parallel arrays)
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

# Check if a command matches any loaded pattern.
# Arguments: command string
# Returns: 0 if match found (MATCHED_PATTERN/MATCHED_CATEGORY are set),
#          1 otherwise.
# One batch grep over all patterns decides the common no-match case in a
# single process instead of one grep spawn per pattern (~676 patterns for
# destructive-bash made every benign command cost seconds). The per-pattern
# loop below only runs to name which pattern matched, or -- when the batch
# grep itself errors because one invalid ERE poisons the whole pattern file
# -- to report the offending pattern(s) individually.
# The command is fed to grep with printf (not echo) so a command starting
# with -n/-e is matched verbatim instead of being eaten as an echo option.
# A pattern that is not a valid ERE (grep exit status >= 2) is reported to
# stderr instead of being silently skipped as a dead pattern.
check_dangerous_pattern() {
    local command="$1"
    MATCHED_PATTERN=""
    MATCHED_CATEGORY=""
    # No patterns can never match; returning here also keeps grep -f from
    # seeing an empty pattern file. load_patterns never stores an empty line
    # (an empty pattern would match everything), so the batch file is safe.
    if [[ ${#DANGEROUS_PATTERNS[@]} -eq 0 ]]; then
        return 1
    fi
    local batch_status=0
    grep -qiE -f <(printf '%s\n' "${DANGEROUS_PATTERNS[@]}") <<<"$command" 2>/dev/null \
        || batch_status=$?
    if [[ "$batch_status" -eq 1 ]]; then
        return 1
    fi
    local i status
    for i in "${!DANGEROUS_PATTERNS[@]}"; do
        # Capture the pipeline status immediately: any command in between
        # (even an assignment) would overwrite PIPESTATUS.
        printf '%s\n' "$command" | grep -qiE -- "${DANGEROUS_PATTERNS[$i]}" \
            && status=0 || status=${PIPESTATUS[1]}
        if [[ "$status" -eq 0 ]]; then
            MATCHED_PATTERN="${DANGEROUS_PATTERNS[$i]}"
            MATCHED_CATEGORY="${DANGEROUS_PATTERN_CATEGORIES[$i]}"
            return 0
        elif [[ "$status" -ge 2 ]]; then
            echo "kokko-safety: invalid pattern in ${DANGEROUS_PATTERN_CATEGORIES[$i]}.txt (grep exit $status): ${DANGEROUS_PATTERNS[$i]}" >&2
        fi
    done
    return 1
}

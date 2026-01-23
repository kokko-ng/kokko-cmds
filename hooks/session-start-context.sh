#!/bin/bash
# session-start-context.sh - Detect project context at session start
# SessionStart - Outputs project type and git branch info

# Read input from stdin
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // "."')

cd "$cwd" 2>/dev/null || exit 0

# Detect project type
project_type="unknown"
detected_files=()

# Check for Python project
if [ -f "pyproject.toml" ]; then
    project_type="python"
    detected_files+=("pyproject.toml")
elif [ -f "requirements.txt" ]; then
    project_type="python"
    detected_files+=("requirements.txt")
elif [ -f "setup.py" ]; then
    project_type="python"
    detected_files+=("setup.py")
fi

# Check for JavaScript/TypeScript project (can override or be mixed)
if [ -f "package.json" ]; then
    if [ -f "tsconfig.json" ]; then
        if [ "$project_type" = "python" ]; then
            project_type="mixed"
        else
            project_type="typescript"
        fi
        detected_files+=("package.json" "tsconfig.json")
    else
        if [ "$project_type" = "python" ]; then
            project_type="mixed"
        else
            project_type="nodejs"
        fi
        detected_files+=("package.json")
    fi
fi

# Check for Go project
if [ -f "go.mod" ]; then
    project_type="go"
    detected_files+=("go.mod")
fi

# Check for Rust project
if [ -f "Cargo.toml" ]; then
    project_type="rust"
    detected_files+=("Cargo.toml")
fi

# Get git info
git_branch=""
git_dirty=false
if git rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$(git branch --show-current 2>/dev/null)
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

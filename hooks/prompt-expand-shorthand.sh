#!/bin/bash
# prompt-expand-shorthand.sh - Expand shorthand commands
# Hook #13: UserPromptSubmit - Expands lgtm, ship it, wip to full workflows

input=$(cat)
user_prompt=$(echo "$input" | jq -r '.user_prompt // ""')

# Normalize: trim whitespace and lowercase
normalized=$(echo "$user_prompt" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

case "$normalized" in
    "lgtm")
        cat << 'EOF'
The code looks good to merge. Please perform the following workflow:
1. Stage all changed files with git add
2. Create a commit with a descriptive message based on the actual changes made (use Conventional Commits format)
3. Push to the current branch

Do NOT run tests unless specifically requested.
EOF
        ;;

    "ship it"|"shipit"|"ship")
        cat << 'EOF'
Ready to ship this feature. Please perform the complete shipping workflow:
1. Run all tests and ensure they pass
2. Run linting/formatting checks if configured (pre-commit, eslint, etc.)
3. Stage all changed files with git add
4. Create a commit with a descriptive message summarizing the changes (use Conventional Commits format)
5. Push to the current branch
6. Create a pull request with:
   - A clear title summarizing the feature/fix
   - A description with bullet points of what changed
   - Any relevant testing notes

If any step fails, stop and report the issue before continuing.
EOF
        ;;

    "wip")
        cat << 'EOF'
Create a work-in-progress commit. Please:
1. Stage all changed files with git add
2. Create a commit with message format: "wip: [brief description of current work state]"
3. Do NOT run tests or any quality checks
4. Do NOT push to remote

This is just a local checkpoint commit for saving progress.
EOF
        ;;

    *)
        # No expansion needed, output nothing (prompt passes through unchanged)
        ;;
esac

exit 0

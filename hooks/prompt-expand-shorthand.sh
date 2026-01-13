#!/bin/bash
# prompt-expand-shorthand.sh - Expand shorthand commands
# UserPromptSubmit - Expands shorthand to full instructions

input=$(cat)
user_prompt=$(echo "$input" | jq -r '.prompt // ""')

# Normalize: trim whitespace and lowercase
normalized=$(echo "$user_prompt" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

case "$normalized" in
    "gd")
        cat << 'EOF'
Grok deeply: Thoroughly analyze and understand the topic, code, or problem at hand. Go beyond surface-level explanation - explore the underlying concepts, design decisions, trade-offs, and implications. Connect it to broader patterns and principles. Explain it in a way that builds deep intuition.
EOF
        ;;

    "assume")
        cat << 'EOF'
List all assumptions you are making about this task, code, or problem. What are you taking for granted? What could be wrong? What do you need to verify before proceeding? Be explicit about uncertainties and potential blind spots.
EOF
        ;;

    "edge")
        cat << 'EOF'
Explore the edge cases. What are the boundary conditions, error states, unusual inputs, race conditions, and failure modes? Think about empty values, nulls, extremes, concurrent access, and unexpected user behavior. Be thorough and paranoid.
EOF
        ;;

    "hunt")
        cat << 'EOF'
Hunt this down relentlessly. Search everywhere - files, code, logs, configs, dependencies. Try every angle, follow every lead, trace every reference. Do not stop until you find or solve it. If one approach fails, try another. Exhaust all possibilities before concluding it cannot be found.
EOF
        ;;

    "clarify")
        cat << 'EOF'
Proactively use AskUserQuestion throughout this session to clarify ambiguities. Do not assume intent when multiple interpretations exist. Ask about unclear requirements, scope boundaries, implementation preferences, and trade-offs before proceeding. Better to confirm than to redo work.
EOF
        ;;

    "lgtm")
        cat << 'EOF'
Execute the following skills in succession:
1. /compush
2. /pr
3. /merge

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

    "revert")
        cat << 'EOF'
Safely revert the last commit:
1. Show the last commit details (hash, message, changed files) using git log -1 and git diff HEAD~1 --stat
2. Use AskUserQuestion to confirm the user wants to revert this specific commit
3. If confirmed, run: git revert HEAD --no-edit
4. Show the result and new HEAD commit

Do NOT use git reset. Always use git revert to preserve history.
EOF
        ;;

    *)
        # No expansion needed, output nothing (prompt passes through unchanged)
        ;;
esac

exit 0

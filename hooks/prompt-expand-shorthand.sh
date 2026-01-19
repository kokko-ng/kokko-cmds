#!/bin/bash
# prompt-expand-shorthand.sh - Expand shorthand commands
# UserPromptSubmit - Expands shorthand to full instructions
#
# The UserPromptSubmit hook cannot replace the user's prompt, only add context.
# So we output JSON with additionalContext that tells Claude to treat the
# expansion as the user's actual request.

input=$(cat)
user_prompt=$(echo "$input" | jq -r '.prompt // ""')

# Normalize: trim whitespace and lowercase
normalized=$(echo "$user_prompt" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Function to output the expansion as JSON additionalContext
output_expansion() {
    local shorthand="$1"
    local expansion="$2"

    # Build the context message and escape it properly for JSON
    local context="<shorthand-expansion shorthand=\"${shorthand}\">
The user typed the shorthand command '${shorthand}'. This expands to the following instruction which you MUST follow as if the user typed it directly:

${expansion}
</shorthand-expansion>"

    # Use jq to properly escape the context string for JSON
    local escaped_context
    escaped_context=$(printf '%s' "$context" | jq -Rs '.')

    cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": ${escaped_context}
  }
}
EOF
}

case "$normalized" in
    "gd")
        output_expansion "gd" "Grok deeply: Thoroughly analyze and understand the topic, code, or problem at hand. Go beyond surface-level explanation - explore the underlying concepts, design decisions, trade-offs, and implications. Connect it to broader patterns and principles. Explain it in a way that builds deep intuition."
        ;;

    "assume")
        output_expansion "assume" "List all assumptions you are making about this task, code, or problem. What are you taking for granted? What could be wrong? What do you need to verify before proceeding? Be explicit about uncertainties and potential blind spots."
        ;;

    "edge")
        output_expansion "edge" "Explore the edge cases. What are the boundary conditions, error states, unusual inputs, race conditions, and failure modes? Think about empty values, nulls, extremes, concurrent access, and unexpected user behavior. Be thorough and paranoid."
        ;;

    "hunt")
        output_expansion "hunt" "Hunt this down relentlessly. Search everywhere - files, code, logs, configs, dependencies. Try every angle, follow every lead, trace every reference. Do not stop until you find or solve it. If one approach fails, try another. Exhaust all possibilities before concluding it cannot be found."
        ;;

    "clarify")
        output_expansion "clarify" "Proactively use AskUserQuestion throughout this session to clarify ambiguities. Do not assume intent when multiple interpretations exist. Ask about unclear requirements, scope boundaries, implementation preferences, and trade-offs before proceeding. Better to confirm than to redo work."
        ;;

    "lgtm")
        output_expansion "lgtm" "Execute the following skills in succession:
1. /compush
2. /pr
3. /merge

If any step fails, stop and report the issue before continuing."
        ;;

    "wip")
        output_expansion "wip" "Create a work-in-progress commit. Please:
1. Stage all changed files with git add
2. Create a commit with message format: 'wip: [brief description of current work state]'
3. Do NOT run tests or any quality checks
4. Do NOT push to remote

This is just a local checkpoint commit for saving progress."
        ;;

    "revert")
        output_expansion "revert" "Safely revert the last commit:
1. Show the last commit details (hash, message, changed files) using git log -1 and git diff HEAD~1 --stat
2. Use AskUserQuestion to confirm the user wants to revert this specific commit
3. If confirmed, run: git revert HEAD --no-edit
4. Show the result and new HEAD commit

Do NOT use git reset. Always use git revert to preserve history."
        ;;

    *)
        # No expansion needed, output nothing (prompt passes through unchanged)
        ;;
esac

exit 0

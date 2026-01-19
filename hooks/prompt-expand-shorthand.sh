#!/bin/bash
# prompt-expand-shorthand.sh - Expand shorthand commands
# UserPromptSubmit - Expands shorthand to full instructions
#
# The UserPromptSubmit hook cannot replace the user's prompt, only add context.
# So we output JSON with additionalContext that tells Claude to treat the
# expansion as the user's actual request.

input=$(cat)
user_prompt=$(echo "$input" | jq -r '.prompt // ""')

# Normalize for matching: lowercase only (preserve structure for word boundary detection)
normalized=$(echo "$user_prompt" | tr '[:upper:]' '[:lower:]')

# Function to check if a shorthand appears as a separate word in the prompt
# Matches: "gd", "word gd word", "gd.", "(gd)", etc.
# Does NOT match: "gdx", "xgd", "agdb"
has_shorthand() {
    local shorthand="$1"
    local text="$2"
    # Use grep with word boundary matching (-w) and case-insensitive (-i)
    echo "$text" | grep -qiw "$shorthand"
}

# Function to get expansion for a shorthand
get_expansion() {
    local shorthand="$1"
    case "$shorthand" in
        "gd")
            echo "Grok deeply: Thoroughly analyze and understand the topic, code, or problem at hand. Go beyond surface-level explanation - explore the underlying concepts, design decisions, trade-offs, and implications. Connect it to broader patterns and principles. Explain it in a way that builds deep intuition."
            ;;
        "assume")
            echo "List all assumptions you are making about this task, code, or problem. What are you taking for granted? What could be wrong? What do you need to verify before proceeding? Be explicit about uncertainties and potential blind spots."
            ;;
        "edge")
            echo "Explore the edge cases. What are the boundary conditions, error states, unusual inputs, race conditions, and failure modes? Think about empty values, nulls, extremes, concurrent access, and unexpected user behavior. Be thorough and paranoid."
            ;;
        "hunt")
            echo "Hunt this down relentlessly. Search everywhere - files, code, logs, configs, dependencies. Try every angle, follow every lead, trace every reference. Do not stop until you find or solve it. If one approach fails, try another. Exhaust all possibilities before concluding it cannot be found."
            ;;
        "clarify")
            echo "Proactively use AskUserQuestion throughout this session to clarify ambiguities. Do not assume intent when multiple interpretations exist. Ask about unclear requirements, scope boundaries, implementation preferences, and trade-offs before proceeding. Better to confirm than to redo work."
            ;;
        "lgtm")
            cat << 'EXPANSION'
Execute the following skills in succession:
1. /compush
2. /pr
3. /merge

If any step fails, stop and report the issue before continuing.
EXPANSION
            ;;
        "wip")
            cat << 'EXPANSION'
Create a work-in-progress commit. Please:
1. Stage all changed files with git add
2. Create a commit with message format: 'wip: [brief description of current work state]'
3. Do NOT run tests or any quality checks
4. Do NOT push to remote

This is just a local checkpoint commit for saving progress.
EXPANSION
            ;;
        "revert")
            cat << 'EXPANSION'
Safely revert the last commit:
1. Show the last commit details (hash, message, changed files) using git log -1 and git diff HEAD~1 --stat
2. Use AskUserQuestion to confirm the user wants to revert this specific commit
3. If confirmed, run: git revert HEAD --no-edit
4. Show the result and new HEAD commit

Do NOT use git reset. Always use git revert to preserve history.
EXPANSION
            ;;
    esac
}

# List of all shorthands
shorthands="gd assume edge hunt clarify lgtm wip revert"

# Collect all matching shorthands
matched_shorthands=""
for shorthand in $shorthands; do
    if has_shorthand "$shorthand" "$normalized"; then
        matched_shorthands="$matched_shorthands $shorthand"
    fi
done

# Trim leading space
matched_shorthands=$(echo "$matched_shorthands" | sed 's/^ //')

# If no shorthands matched, exit silently (prompt passes through unchanged)
if [ -z "$matched_shorthands" ]; then
    exit 0
fi

# Build combined context for all matched shorthands
context=""
for shorthand in $matched_shorthands; do
    expansion=$(get_expansion "$shorthand")
    context="$context<shorthand-expansion shorthand=\"${shorthand}\">
The user's prompt contains the shorthand '${shorthand}'. This expands to the following instruction which you MUST incorporate:

${expansion}
</shorthand-expansion>

"
done

# Use jq to properly escape the context string for JSON
escaped_context=$(printf '%s' "$context" | jq -Rs '.')

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": ${escaped_context}
  }
}
EOF

exit 0

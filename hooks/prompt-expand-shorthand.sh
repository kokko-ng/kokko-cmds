#!/bin/bash
# prompt-expand-shorthand.sh - Expand shorthand commands
# UserPromptSubmit - Expands shorthand to full instructions

input=$(cat)
user_prompt=$(echo "$input" | jq -r '.user_prompt // ""')

# Normalize: trim whitespace and lowercase
normalized=$(echo "$user_prompt" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Function to output JSON response
emit_expansion() {
    jq -n --arg value "$1" '{"result": "continue", "value": $value}'
}

case "$normalized" in
    "gd")
        emit_expansion "Grok deeply: Thoroughly analyze and understand the topic, code, or problem at hand. Go beyond surface-level explanation - explore the underlying concepts, design decisions, trade-offs, and implications. Connect it to broader patterns and principles. Explain it in a way that builds deep intuition."
        ;;

    "assume")
        emit_expansion "List all assumptions you are making about this task, code, or problem. What are you taking for granted? What could be wrong? What do you need to verify before proceeding? Be explicit about uncertainties and potential blind spots."
        ;;

    "edge")
        emit_expansion "Explore the edge cases. What are the boundary conditions, error states, unusual inputs, race conditions, and failure modes? Think about empty values, nulls, extremes, concurrent access, and unexpected user behavior. Be thorough and paranoid."
        ;;

    "hunt")
        emit_expansion "Hunt this down relentlessly. Search everywhere - files, code, logs, configs, dependencies. Try every angle, follow every lead, trace every reference. Do not stop until you find or solve it. If one approach fails, try another. Exhaust all possibilities before concluding it cannot be found."
        ;;

    "clarify")
        emit_expansion "Proactively use AskUserQuestion throughout this session to clarify ambiguities. Do not assume intent when multiple interpretations exist. Ask about unclear requirements, scope boundaries, implementation preferences, and trade-offs before proceeding. Better to confirm than to redo work."
        ;;

    *)
        # No expansion needed, output nothing (prompt passes through unchanged)
        ;;
esac

exit 0

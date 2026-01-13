#!/bin/bash
# prompt-expand-shorthand.sh - Expand shorthand commands
# Hook #13: UserPromptSubmit - Expands shorthand to full instructions

input=$(cat)
user_prompt=$(echo "$input" | jq -r '.user_prompt // ""')

# Normalize: trim whitespace and lowercase
normalized=$(echo "$user_prompt" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

case "$normalized" in
    "gd")
        cat << 'EOF'
Grok deeply: Thoroughly analyze and understand the topic, code, or problem at hand. Go beyond surface-level explanation - explore the underlying concepts, design decisions, trade-offs, and implications. Connect it to broader patterns and principles. Explain it in a way that builds deep intuition.
EOF
        ;;

    *)
        # No expansion needed, output nothing (prompt passes through unchanged)
        ;;
esac

exit 0

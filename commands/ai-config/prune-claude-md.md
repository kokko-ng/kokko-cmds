---
disable-model-invocation: true
---

# Prune CLAUDE.md

Reduce CLAUDE.md to only essential information for effective agent performance.

## When to Use

- When CLAUDE.md is too long (> 300 lines)
- When context window is being wasted
- During periodic documentation cleanup

## Arguments

Usage: `/prune-claude-md [claude-md-path] [--target-lines number]`

- `claude-md-path` - Path to CLAUDE.md file (default: ./CLAUDE.md)
- `--target-lines` - Target line count (default: 300)

If `$ARGUMENTS` is provided, use it as the file path or target.

## Steps

### 1. Analyze Current Size

```bash
wc -l CLAUDE.md
```

### 2. Categorize Content by Priority

**Priority 1 - Must Keep:**

- Project-specific commands (build, test, run)
- Critical constraints or requirements
- Non-obvious architectural decisions
- Environment setup essentials

**Priority 2 - Keep if Space Allows:**

- Code style preferences beyond linting
- Common gotchas specific to codebase
- Key file locations for important modules

**Priority 3 - Remove:**

- General programming advice
- Lengthy explanations of standard tools
- Verbose examples when terse ones work
- Aspirational guidelines not enforced

### 3. Principles for Pruning

**Keep information that:**

- Directly affects code generation
- Prevents common mistakes
- Enables task completion
- Is unique to this project

**Remove information that:**

- Claude already knows (general best practices)
- Is redundant or repeated
- Is too verbose when shorter version suffices
- Describes obvious project structure
- Contains examples inferable from code

### 4. Apply Compression Techniques

1. **Consolidate** related points into single statements
2. **Use bullet points** instead of paragraphs
3. **Remove filler words** and qualifiers
4. **Replace examples with patterns** where possible
5. **Link to docs** instead of duplicating
6. **Use code blocks sparingly** - only for non-obvious commands

### 5. Validate Final Size. Loop back to Step 2 if still not under 300 lines

```bash
wc -l CLAUDE.md
```

Target: Under 300 lines while retaining critical information.

## Guidance on Effectiveness

Ask: "Could an agent complete common tasks with only this CLAUDE.md?"

- If yes for all critical workflows, pruning is complete
- If no, add back minimum needed context

## Success Criteria

- CLAUDE.md under target line count
- All critical information retained
- Agent can complete common tasks
- No redundant or obvious information

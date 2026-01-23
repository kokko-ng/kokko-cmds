---
disable-model-invocation: true
---

# Prune README.md

Reduce README.md to essential information for developer onboarding.

## When to Use

- When README.md is too long
- When important info is buried in text
- During documentation cleanup

## Arguments

Usage: `/prune-readme [readme-path] [--target-lines number]`

- `readme-path` - Path to README.md file (default: ./README.md)
- `--target-lines` - Target line count (default: 100 simple, 200 complex)

If `$ARGUMENTS` is provided, use it as the file path or target.

## Steps

### 1. Analyze Current Size

```bash
wc -l README.md
```

### 2. Categorize Content by Priority

**Priority 1 - Must Keep:**
- Project name and one-line description
- Prerequisites (language version, required tools)
- Installation steps
- Basic usage/run command

**Priority 2 - Keep if Space Allows:**
- Configuration options (brief)
- Common troubleshooting
- Contributing guidelines (or link)
- License

**Priority 3 - Remove:**
- Lengthy architecture explanations (move to docs/)
- Multiple usage examples (keep one, link to more)
- Changelog content (use CHANGELOG.md)
- Verbose feature lists
- Screenshots that don't aid understanding

### 3. Principles for Pruning

**Keep information that:**
- Enables quick start (clone, install, run in under 5 minutes)
- Explains the purpose (one paragraph max)
- Shows basic usage
- Points to more info (links, not duplicated content)

**Remove information that:**
- Duplicates info elsewhere (package.json scripts, inline comments)
- Is obvious from code or file structure
- Contains excessive examples when one suffices
- Includes outdated badges or status indicators
- Has verbose explanations that could be one-liners

### 4. Apply Compression Techniques

1. **Use tables** for option/config documentation
2. **Single code block** for install + run (copy-paste friendly)
3. **Link to docs** instead of duplicating
4. **Remove badges** that don't provide useful info
5. **Collapse optional sections** using details/summary if supported

### 5. Validate Final Size. Loop back to Step 2 if still not under target.

```bash
wc -l README.md
```

Target: Under 100 lines (simple), under 200 (complex).

## Guidance on Effectiveness

Ask: "Could a new developer go from clone to running in 5 minutes?"
- If yes, pruning is complete
- If no, add back minimum needed steps

## Success Criteria

- README under target line count
- New developer can get running quickly
- No redundant information
- Clear, scannable structure

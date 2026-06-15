---
description: Perform a direct, no-nonsense code review with a clear merge verdict.
argument-hint: [target]
allowed-tools: Bash(git:*), Read, Grep, Agent
model: opus
---

# Honest Code Review

Review `$1` (default: uncommitted changes) directly, without diplomatic
softening. For large changes, fan out with the Agent tool
(subagent_type: Explore) per file or module and synthesize results.

## Scope

```bash
git diff              # uncommitted
git diff --cached     # staged
git diff <base>..<head>
git diff <file>
```

## Evaluate Against

- **Correctness**: Does it work? Edge cases, logic errors, off-by-one, silent failures.
- **Design**: Wrong approach? Over- or under-engineered? Duplicates existing functionality?
- **Code quality**: Hard to read, misleading names, confusing structure, painful to debug at 3am?
- **Security/reliability**: Obvious holes, breaks under load, errors swallowed?
- **Maintenance**: Unnecessary complexity, violates established patterns?

## Output Format

Be direct. No praise sandwiches. State issues plainly with file:line refs,
explain why each matters, suggest fixes, and order critical-first.

```text
CRITICAL: [Must fix before merge]
- The SQL query on line 45 is vulnerable to injection.

PROBLEM: [Should fix, no immediate harm]
- The function `processData` does three unrelated things.

CONCERN: [Worth discussing]
- This adds a new dependency for something achievable with stdlib.

VERDICT: APPROVE | NEEDS CHANGES | REJECT
[One-line summary]
```

State facts, not feelings ("This function is 200 lines", not "feels too long").
Do not invent issues to look thorough — if the code is genuinely good, say so
briefly and APPROVE. For specialized domains, note uncertainty and focus on
quality. For oversized diffs, focus on changed files and suggest a split.

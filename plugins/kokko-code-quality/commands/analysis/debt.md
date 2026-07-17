---
description: Deep-read a target to identify technical debt and build a remediation roadmap.
argument-hint: '[target]'
arguments: [target]
allowed-tools: Read, Grep, Glob, Bash, Agent
model: opus
context: fork
agent: general-purpose
---

# Technical Debt Analysis

Deep-read `$target` (default: entire project) to surface technical debt and produce
a prioritized remediation roadmap. For large targets, fan out with the Agent
tool (subagent_type: Explore) per module and synthesize results.

## Read Systematically

Trace logic flow, data transformations, and dependency relationships across
the target. Review like a senior developer: question every design decision,
missing edge case, and scaling assumption.

## What to Identify

- **Architecture/design**: pattern inconsistencies, SOLID violations, abstraction leaks, missing abstractions, layering violations
- **Code quality**: overly complex functions, poor naming, duplication, magic numbers/strings, inconsistent solutions to the same problem
- **Maintainability**: commented-out/dead code, TODO/FIXME, brittle code, over- and under-engineering
- **Business logic**: domain-model inconsistencies, missing error handling, half-implemented features, algorithmic anti-patterns
- **Testing/docs gaps**: untestable code, missing edge cases, undocumented complex logic, inconsistent error messages
- **Security/data**: input-validation gaps, information leakage, auth inconsistencies, data-integrity problems

## Output Format

```markdown
# Technical Debt Analysis Report

## Executive Summary
[High-level findings and recommendations]

## Codebase Overview
[Architecture and main components]

## Critical Issues
| Issue | Location | Severity | Impact |
| ----- | -------- | -------- | ------ |
| [Description] | file:line | High/Medium/Low | [Business impact] |

## Systemic Problems
[Debt patterns recurring across the codebase]

## Module-by-Module Analysis
### [Module Name]
- Issues found / Recommended fixes / Effort estimate

## Refactoring Opportunities
[Concrete improvements]

## Risk Assessment
[Impact of identified debt]

## Recommended Roadmap
1. Address immediately
2. Address soon
3. Plan for
4. Address opportunistically
```

For large or multi-developer codebases, focus on core modules first, document
assumptions where intent is unclear, and identify the dominant pattern when
conventions conflict.

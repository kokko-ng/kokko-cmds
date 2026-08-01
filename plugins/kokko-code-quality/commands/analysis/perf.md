---
description: Identify performance bottlenecks across a target and recommend prioritized fixes.
argument-hint: '[target] [--focus database|api|frontend|backend|memory]'
allowed-tools: Read, Grep, Glob, Bash, Task
---

# Performance Bottleneck Analysis

Analyze `$1` (default: entire project) for performance bottlenecks, optionally
scoped by `--focus`. Prioritize hot paths (request handlers, background jobs,
query-heavy operations, external integrations) and measure before optimizing —
check existing metrics/logging and TODO comments about performance. For large
targets, fan out with the Task tool (subagent_type: Explore) per focus area
and synthesize results.

## What to Search For

- **Database**: N+1 queries, missing indexes, `SELECT *`, no result caching, missing pagination, sync DB calls in loops, no connection pooling
- **API/network**: serial calls that could parallelize, missing request/response caching, uncompressed large payloads, blocking external calls, missing timeouts, repeated calls for same data, no rate limiting/circuit breakers
- **Frontend**: large inline data, no lazy loading, DOM churn in loops, missing debounce/throttle, large reactive objects, no code splitting, unnecessary re-renders
- **Backend**: sync processing of large datasets, missing async/await, blocking I/O, inefficient/nested loops, no streaming for large files, no worker queues, heavy compute in handlers
- **Memory**: leaks (unclosed connections/resources), large objects retained, missing context managers, unbounded caches, circular references, no pooling
- **Concurrency**: serial I/O-bound ops, thread-safety issues, lock contention/deadlock risk, sync code in async contexts

```bash
# N+1 patterns (Python)
grep -rn "for.*in.*:" --include="*.py" -A5 | grep -E "\.get\(|\.filter\(|\.query\("
# SELECT *
grep -rn "SELECT \*" --include="*.py" --include="*.sql"
```

## Output Format

```markdown
## Performance Findings

### Critical (High Impact)
| Location | Issue | Impact | Fix |
|----------|-------|--------|-----|
| file:line | N+1 query in loop | 100+ queries | Use prefetch/eager loading |

### Important (Medium Impact)
...

### Minor (Low Impact)
...

## Recommended Actions
1. [Highest priority fix]
...
```

Document trade-offs (complexity vs. speed). If impact is unclear, recommend
adding timing/profiling before changing code.

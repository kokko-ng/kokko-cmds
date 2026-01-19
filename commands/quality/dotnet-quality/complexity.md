# Refactor Using Complexity Analysis

Use .NET analyzers and code metrics to identify high-complexity methods and refactor safely.

## When to Use

- When code is difficult to understand or modify
- Before major feature additions to complex areas
- To improve code quality metrics

## Arguments

Usage: `/quality/dotnet-quality/complexity [target] [--threshold number]`

- `target` - Solution or project to analyze (default: auto-detect)
- `--threshold` - Maximum cyclomatic complexity allowed (default: 15)

If `$ARGUMENTS` is provided, use it as the target path.

## Prerequisites

- .NET SDK 6.0+
- Visual Studio or JetBrains tools (optional for detailed analysis)

## Steps

### 1. Enable Code Metrics Analyzers

Add to `.csproj` or `Directory.Build.props`:
```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisLevel>latest-all</AnalysisLevel>
</PropertyGroup>
```

### 2. Run Code Metrics Analysis

```bash
# Build and capture analyzer warnings
dotnet build -warnaserror:CA1502,CA1505,CA1506

# Generate detailed metrics (requires msbuild)
dotnet msbuild /t:Metrics
```

Key complexity rules:
- **CA1502** - Cyclomatic complexity too high (default > 25)
- **CA1505** - Maintainability index too low (< 20)
- **CA1506** - Class coupling too high (> 95)

### 3. Configure Thresholds

Create or update `.editorconfig`:
```ini
[*.cs]
# Cyclomatic complexity threshold
dotnet_code_quality.CA1502.threshold = 15

# Maintainability index threshold
dotnet_code_quality.CA1505.threshold = 40

# Class coupling threshold
dotnet_code_quality.CA1506.threshold = 40
```

### 4. Identify Hotspots

Target methods with:
- Cyclomatic complexity > 15
- Maintainability index < 40
- High class coupling (> 40 dependencies)
- Deep nesting levels (> 3)

Prioritize by:
1. Highest complexity first
2. Frequency of change (`git log --follow <file>`)
3. Business criticality

### 5. Establish Safety Net

For each target method:
1. Add or improve focused tests (behavioral, edge cases, error paths)
2. Run tests before refactoring:
   ```bash
   dotnet test --filter "FullyQualifiedName~<TestClass>"
   ```

### 6. Refactor Tactics

Apply one tactic at a time:

- **Extract Method** - Break out cohesive blocks
- **Guard Clauses** - Replace nested conditionals with early returns
- **Dictionary Dispatch** - Replace switch statements with lookup
- **Decompose Conditionals** - Extract complex conditions to named methods
- **Remove Duplication** - DRY or inline trivial indirections
- **Replace Nested Loops** - Use LINQ or extract inner loops
- **Clarify Names** - Rename unclear variables/methods
- **Isolate Side Effects** - Separate pure logic from I/O
- **Reduce Parameters** - Introduce record or class
- **Split Large Classes** - Single Responsibility Principle

After each micro-change:
```bash
dotnet test
dotnet build -warnaserror:CA1502
```

Commit if green:
```bash
git add <files>
git commit -m "refactor(complexity): reduce complexity in <method>"
```

### 7. Validate No Regression

When a file is improved:
```bash
dotnet build -warnaserror:CA1502,CA1505,CA1506
dotnet test
dotnet format --verify-no-changes
```

### 8. Know When to Stop

Stop refactoring when:
- Cyclomatic complexity <= 15
- Maintainability index >= 40
- Further changes risk unnecessary churn
- Code is clear and testable

### 9. Handle Hard Cases

If complexity resists decomposition:
- Introduce a decision table or data-driven structure
- Split algorithm into phases (parse -> transform -> emit)
- Use the Strategy pattern for variant behavior
- Accept temporary adapter while migrating callers

## Error Handling

| Issue | Cause | Resolution |
|-------|-------|------------|
| Tests fail after refactor | Behavior changed | Revert, write more tests first |
| Complexity stays high | Algorithm inherently complex | Document, add tests, accept |
| Metrics conflict | Low complexity but low maintainability | Focus on readability over metrics |

## Success Criteria

- No methods with cyclomatic complexity > 15
- Maintainability index >= 40 for all types
- All tests pass
- Code is more readable and maintainable

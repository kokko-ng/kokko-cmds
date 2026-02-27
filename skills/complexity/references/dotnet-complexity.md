# .NET Complexity Analysis

## Prerequisites

- .NET SDK 6.0+

## Enable Code Metrics Analyzers

Add to `.csproj` or `Directory.Build.props`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisLevel>latest-all</AnalysisLevel>
</PropertyGroup>
```

## Commands

```bash
# Build and capture analyzer warnings
dotnet build -warnaserror:CA1502,CA1505,CA1506

# Generate detailed metrics (requires msbuild)
dotnet msbuild /t:Metrics
```

## Key Complexity Rules

- **CA1502** - Cyclomatic complexity too high (default > 25)
- **CA1505** - Maintainability index too low (< 20)
- **CA1506** - Class coupling too high (> 95)

## Configure Thresholds

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

## Identify Hotspots

Target methods with:

- Cyclomatic complexity > 15
- Maintainability index < 40
- High class coupling (> 40 dependencies)
- Deep nesting levels (> 3)

Prioritize by:

1. Highest complexity first
2. Frequency of change (`git log --follow <file>`)
3. Business criticality

## Refactor Tactics

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

## Validation

After each micro-change:

```bash
dotnet build -warnaserror:CA1502
```

## Commit Format

```text
refactor(complexity): reduce complexity in <method>
```

## When to Stop

- Cyclomatic complexity <= 15
- Maintainability index >= 40
- Further changes risk unnecessary churn

## Hard Cases

If complexity resists decomposition:

- Introduce a decision table or data-driven structure
- Split algorithm into phases (parse -> transform -> emit)
- Use the Strategy pattern for variant behavior
- Accept temporary adapter while migrating callers

## Final Quality Gate

```bash
dotnet build -warnaserror:CA1502,CA1505,CA1506
dotnet format --verify-no-changes
```

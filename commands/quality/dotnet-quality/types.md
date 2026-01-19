# Find and Fix Type Errors with .NET Analyzers

Use strict C# compiler settings and analyzers to detect and fix type-related issues.

## When to Use

- Before committing C# code changes
- When enabling nullable reference types
- To catch type-related bugs early

## Arguments

Usage: `/quality/dotnet-quality/types [target]`

- `target` - Solution or project to check (default: auto-detect)

If `$ARGUMENTS` is provided, use it as the target path.

## Prerequisites

- .NET SDK 6.0+
- Nullable reference types enabled (recommended)

## Steps

### 1. Enable Strict Type Checking

Add to `.csproj` or `Directory.Build.props`:
```xml
<PropertyGroup>
  <Nullable>enable</Nullable>
  <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  <WarningsAsErrors>nullable</WarningsAsErrors>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisLevel>latest-recommended</AnalysisLevel>
</PropertyGroup>
```

### 2. Run Type Check

```bash
# Build with all warnings
dotnet build

# Build with nullable warnings as errors
dotnet build -warnaserror:nullable

# Build specific project
dotnet build src/MyProject/MyProject.csproj
```

### 3. Review Output

For each error, note:
- File path and line number
- Error code (e.g., CS8600, CS8602, CA1062)
- Error description

### 4. Common Errors and Fixes

| Error Code | Description | Fix |
|------------|-------------|-----|
| CS8600 | Converting null literal to non-nullable | Add null check or use nullable type |
| CS8602 | Dereference of possibly null reference | Add null check or use `?.` operator |
| CS8603 | Possible null reference return | Return non-null or change return type |
| CS8604 | Possible null argument | Validate argument or mark parameter nullable |
| CS8618 | Non-nullable property uninitialized | Initialize in constructor or make nullable |
| CS8619 | Nullability mismatch in interface | Match interface nullability |
| CS8625 | Cannot convert null to non-nullable | Add null check |
| CS8629 | Nullable value type may be null | Use `?.Value` or null check |
| CA1062 | Validate parameter is non-null | Add `ArgumentNullException.ThrowIfNull()` |
| CA2201 | Do not raise reserved exception types | Use specific exception types |

### 5. Fix Iteratively

For each error:

1. **Understand the error** - Read the full message and context
2. **Fix the source** - Update code to satisfy type checker
3. **Re-run build** on the specific project:
   ```bash
   dotnet build src/MyProject/MyProject.csproj
   ```
4. **Commit when clean:**
   ```bash
   git add <files>
   git commit -m "fix(types): resolve <error_code> in <file>"
   ```

### 6. Nullable Annotation Patterns

**For parameters:**
```csharp
// Before
public void Process(string data) { }

// After - if null is valid
public void Process(string? data) { }

// After - if null is not valid
public void Process(string data)
{
    ArgumentNullException.ThrowIfNull(data);
}
```

**For properties:**
```csharp
// Before - warning CS8618
public string Name { get; set; }

// After - initialized
public string Name { get; set; } = string.Empty;

// After - nullable
public string? Name { get; set; }

// After - required (C# 11+)
public required string Name { get; set; }
```

**For return types:**
```csharp
// Before - may return null
public User GetUser(int id) { }

// After - explicitly nullable
public User? GetUser(int id) { }

// After - throw if not found
public User GetUser(int id) =>
    _users.Find(u => u.Id == id)
    ?? throw new InvalidOperationException($"User {id} not found");
```

### 7. Configure Strictness

For stricter checking, add to `.editorconfig`:
```ini
[*.cs]
# Nullable warnings as errors
dotnet_diagnostic.CS8600.severity = error
dotnet_diagnostic.CS8602.severity = error
dotnet_diagnostic.CS8603.severity = error
dotnet_diagnostic.CS8604.severity = error

# Require null checks on public methods
dotnet_diagnostic.CA1062.severity = warning
```

### 8. Handle Third-Party Libraries

For libraries without nullable annotations:
```csharp
// Use null-forgiving operator when you know value is non-null
var result = legacyLibrary.GetValue()!;

// Or add explicit check
var value = legacyLibrary.GetValue();
if (value is null)
    throw new InvalidOperationException("Unexpected null from library");
```

### 9. Final Validation

```bash
dotnet build -warnaserror:nullable
dotnet test
dotnet format --verify-no-changes
```

## Error Handling

| Issue | Cause | Resolution |
|-------|-------|------------|
| Too many errors | Enabling nullable on legacy code | Migrate file by file with `#nullable enable` |
| Third-party type issues | Library lacks annotations | Use `!` sparingly with comments |
| Generic type issues | Complex inference | Add explicit type parameters |

## Avoiding `object` and `dynamic`

**CRITICAL**: Avoid `object` and `dynamic` unless absolutely necessary. They defeat type checking.

**Instead of `object`, use:**
- Generic types `<T>` - to preserve type relationships
- Interfaces - for polymorphism
- `record` types - for data transfer
- Union types via inheritance or `OneOf<>` library

**Instead of `dynamic`, use:**
- Strong typing with interfaces
- `System.Text.Json` with typed models
- Source generators for runtime scenarios

**If `object`/`dynamic` is unavoidable:**
- Add a comment explaining why
- Limit scope as much as possible
- Add runtime type checks immediately after

## Success Criteria

- Zero nullable warnings with strict settings
- All type annotations are accurate
- No `object` or `dynamic` without documented justification
- No null-forgiving `!` without explanation
- Tests still pass after type fixes

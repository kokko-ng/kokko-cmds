# .NET Type Checking

## Prerequisites

- .NET SDK 6.0+
- Nullable reference types enabled (recommended)

## Enable Strict Type Checking

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

## Commands

```bash
# Build with all warnings
dotnet build

# Build with nullable warnings as errors
dotnet build -warnaserror:nullable

# Build specific project
dotnet build src/MyProject/MyProject.csproj
```

## Common Errors and Fixes

| Error Code | Description | Fix |
| ---------- | ----------- | --- |
| CS8600 | Converting null to non-nullable | Add null check or nullable type |
| CS8602 | Dereference of possibly null | Add null check or use `?.` |
| CS8603 | Possible null reference return | Return non-null or change type |
| CS8604 | Possible null argument | Validate or mark parameter nullable |
| CS8618 | Non-nullable uninitialized | Initialize in constructor or nullable |
| CS8619 | Nullability mismatch in interface | Match interface nullability |
| CS8625 | Cannot convert null | Add null check |
| CS8629 | Nullable value type may be null | Use `?.Value` or null check |
| CA1062 | Validate parameter is non-null | Add `ThrowIfNull()` |
| CA2201 | Do not raise reserved exceptions | Use specific exception types |

## Nullable Annotation Patterns

**For parameters:**

```csharp
// If null is valid
public void Process(string? data) { }

// If null is not valid
public void Process(string data)
{
    ArgumentNullException.ThrowIfNull(data);
}
```

**For properties:**

```csharp
// Initialized
public string Name { get; set; } = string.Empty;

// Nullable
public string? Name { get; set; }

// Required (C# 11+)
public required string Name { get; set; }
```

**For return types:**

```csharp
// Explicitly nullable
public User? GetUser(int id) { }

// Throw if not found
public User GetUser(int id) =>
    _users.Find(u => u.Id == id)
    ?? throw new InvalidOperationException($"User {id} not found");
```

## Configure Strictness

Add to `.editorconfig`:

```ini
[*.cs]
dotnet_diagnostic.CS8600.severity = error
dotnet_diagnostic.CS8602.severity = error
dotnet_diagnostic.CS8603.severity = error
dotnet_diagnostic.CS8604.severity = error
dotnet_diagnostic.CA1062.severity = warning
```

## Avoiding `object` and `dynamic`

**CRITICAL**: Avoid `object` and `dynamic` unless absolutely necessary.

**Instead of `object`, use:**

- Generic types `<T>` - to preserve type relationships
- Interfaces - for polymorphism
- `record` types - for data transfer
- Union types via inheritance or `OneOf<>` library

**Instead of `dynamic`, use:**

- Strong typing with interfaces
- `System.Text.Json` with typed models
- Source generators for runtime scenarios

**If unavoidable:**

- Add a comment explaining why
- Limit scope as much as possible
- Add runtime type checks immediately after

## Handle Third-Party Libraries

```csharp
// Use null-forgiving operator when you know value is non-null
var result = legacyLibrary.GetValue()!;

// Or add explicit check
var value = legacyLibrary.GetValue();
if (value is null)
    throw new InvalidOperationException("Unexpected null from library");
```

## Validation

After each fix:

```bash
dotnet build src/MyProject/MyProject.csproj
```

## Commit Format

```text
fix(types): resolve <error_code> in <file>
```

## Final Quality Gate

```bash
dotnet build -warnaserror:nullable
dotnet format --verify-no-changes
```

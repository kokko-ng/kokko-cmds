# Verify and Fix XML Documentation

Use .NET compiler warnings and analyzers to ensure all public APIs have proper XML documentation.

## When to Use

- When documentation coverage is low
- Before major releases
- When generating API documentation with DocFX

## Arguments

Usage: `/quality/dotnet-quality/docs [target]`

- `target` - Solution or project to check (default: auto-detect)

If `$ARGUMENTS` is provided, use it as the target path.

## Prerequisites

- .NET SDK 6.0+

## Persistence Requirement

**DO NOT STOP until ALL documentation issues are resolved.** This task requires complete coverage:
- Process every single file reported
- Fix every missing or malformed XML doc comment
- Continue working through all types systematically
- Re-run the build after each batch of fixes to confirm progress
- Only consider this task complete when build reports zero CS1591 warnings

If context window limits approach, document remaining files in the todo list and continue in the next session.

## Steps

### 1. Enable Documentation Warnings

Add to `.csproj` or `Directory.Build.props`:
```xml
<PropertyGroup>
  <GenerateDocumentationFile>true</GenerateDocumentationFile>
  <NoWarn>$(NoWarn);1701;1702</NoWarn>
  <!-- Treat missing docs as warnings -->
  <WarningsAsErrors>CS1591</WarningsAsErrors>
</PropertyGroup>
```

### 2. Run Documentation Analysis

```bash
# Build with documentation warnings
dotnet build -warnaserror:CS1591

# Full build to see all warnings
dotnet build
```

Key documentation warnings:
- **CS1591** - Missing XML comment for publicly visible type or member
- **CS1572** - XML comment has param tag but no parameter
- **CS1573** - Parameter has no matching param tag
- **CS1574** - XML comment has cref but cannot resolve
- **CS1587** - XML comment not placed on valid element
- **CS1589** - Cannot include XML fragment

### 3. Processing Order

Work through files systematically:
1. Public API classes and interfaces
2. Public methods on controllers/services
3. Public properties and events
4. Protected members for inheritance
5. Internal types (optional but recommended)

### 4. XML Documentation Standards

Use consistent XML doc format:

**For methods:**
```csharp
/// <summary>
/// Short one-line summary ending with period.
/// </summary>
/// <remarks>
/// Longer description if needed. Explain the purpose,
/// not the implementation.
/// </remarks>
/// <param name="param1">Description of first parameter.</param>
/// <param name="param2">Description of second parameter.</param>
/// <returns>Description of return value.</returns>
/// <exception cref="ArgumentNullException">
/// Thrown when <paramref name="param1"/> is null.
/// </exception>
/// <example>
/// <code>
/// var result = MethodName("value", 42);
/// </code>
/// </example>
public bool MethodName(string param1, int param2)
{
    // ...
}
```

**For classes:**
```csharp
/// <summary>
/// Short one-line summary.
/// </summary>
/// <remarks>
/// Longer description of the class purpose and usage.
/// </remarks>
/// <typeparam name="T">Description of type parameter.</typeparam>
public class ClassName<T>
{
    /// <summary>
    /// Description of property.
    /// </summary>
    public string PropertyName { get; set; }
}
```

**For interfaces:**
```csharp
/// <summary>
/// Defines the contract for user management operations.
/// </summary>
public interface IUserService
{
    /// <summary>
    /// Retrieves a user by their unique identifier.
    /// </summary>
    /// <param name="id">The unique user identifier.</param>
    /// <returns>The user if found; otherwise, null.</returns>
    User? GetUser(int id);
}
```

### 5. Fix Iteratively

For each file with issues:
1. Add missing XML documentation starting with public interfaces
2. Fix malformed documentation
3. Verify changes:
   ```bash
   dotnet build src/MyProject/MyProject.csproj -warnaserror:CS1591
   ```
4. Commit when passing:
   ```bash
   git add <file>
   git commit -m "docs(<namespace>): add XML docs to <type>"
   ```

### 6. Use InheritDoc for Implementations

For interface implementations:
```csharp
/// <inheritdoc />
public User? GetUser(int id)
{
    return _repository.Find(id);
}
```

For overrides:
```csharp
/// <inheritdoc />
/// <remarks>
/// This implementation adds caching behavior.
/// </remarks>
public override string ToString()
{
    return _cachedString ??= base.ToString();
}
```

### 7. Configure Scope

To exclude certain assemblies from documentation requirements:
```xml
<!-- In specific project that doesn't need docs -->
<PropertyGroup>
  <GenerateDocumentationFile>false</GenerateDocumentationFile>
</PropertyGroup>
```

Or exclude specific types in `.editorconfig`:
```ini
[**/Internal/**/*.cs]
dotnet_diagnostic.CS1591.severity = none

[**/Migrations/*.cs]
dotnet_diagnostic.CS1591.severity = none
```

### 8. Validate Coverage Improvement

After each batch of fixes:
```bash
dotnet build -warnaserror:CS1591
dotnet test
```

### 9. Generate Documentation (Optional)

```bash
# Install DocFX
dotnet tool install -g docfx

# Generate documentation site
docfx init
docfx build
docfx serve _site
```

## Error Handling

| Issue | Cause | Resolution |
|-------|-------|------------|
| CS1591 on generated code | Auto-generated files | Exclude from documentation requirements |
| CS1574 cref not found | Type in different namespace | Add full namespace or using directive |
| Too many warnings | Large codebase | Process namespace by namespace |

## Success Criteria

- `dotnet build -warnaserror:CS1591` passes
- All public types and members have XML documentation
- All tests pass
- Documentation follows consistent format
- `<inheritdoc />` used appropriately for implementations

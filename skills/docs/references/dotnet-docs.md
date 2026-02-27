# .NET XML Documentation

## Prerequisites

- .NET SDK 6.0+

## Enable Documentation Warnings

Add to `.csproj` or `Directory.Build.props`:

```xml
<PropertyGroup>
  <GenerateDocumentationFile>true</GenerateDocumentationFile>
  <NoWarn>$(NoWarn);1701;1702</NoWarn>
  <WarningsAsErrors>CS1591</WarningsAsErrors>
</PropertyGroup>
```

## Commands

```bash
# Build with documentation warnings
dotnet build -warnaserror:CS1591

# Full build to see all warnings
dotnet build
```

## Key Documentation Warnings

- **CS1591** - Missing XML comment for publicly visible type or member
- **CS1572** - XML comment has param tag but no parameter
- **CS1573** - Parameter has no matching param tag
- **CS1574** - XML comment has cref but cannot resolve
- **CS1587** - XML comment not placed on valid element
- **CS1589** - Cannot include XML fragment

## Processing Order

Work through files systematically:

1. Public API classes and interfaces
2. Public methods on controllers/services
3. Public properties and events
4. Protected members for inheritance
5. Internal types (optional but recommended)

## XML Documentation Standards

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

## Use InheritDoc

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

## Configure Scope

Exclude assemblies from documentation requirements:

```xml
<PropertyGroup>
  <GenerateDocumentationFile>false</GenerateDocumentationFile>
</PropertyGroup>
```

Or exclude types in `.editorconfig`:

```ini
[**/Internal/**/*.cs]
dotnet_diagnostic.CS1591.severity = none

[**/Migrations/*.cs]
dotnet_diagnostic.CS1591.severity = none
```

## Validation

After fixing each file:

```bash
dotnet build src/MyProject/MyProject.csproj -warnaserror:CS1591
```

## Commit Format

```text
docs(<namespace>): add XML docs to <type>
```

## Error Handling

| Issue | Resolution |
| ----- | ---------- |
| CS1591 on generated code | Exclude from documentation requirements |
| CS1574 cref not found | Add full namespace or using directive |
| Too many warnings | Process namespace by namespace |

## Final Quality Gate

```bash
dotnet build -warnaserror:CS1591
```

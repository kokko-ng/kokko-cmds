# Find and Remove Dead Code with .NET Analyzers

Use .NET analyzers to detect unused code and safely remove it.

## When to Use

- During codebase cleanup
- Before major refactoring
- To reduce maintenance burden

## Arguments

Usage: `/quality/dotnet-quality/deadcode [target]`

- `target` - Solution or project to analyze (default: auto-detect)

If `$ARGUMENTS` is provided, use it as the target path.

## Prerequisites

- .NET SDK 6.0+
- Roslynator.Analyzers (optional): `dotnet add package Roslynator.Analyzers`

## Steps

### 1. Enable Dead Code Analyzers

Add to `.csproj` or `Directory.Build.props`:
```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisLevel>latest-all</AnalysisLevel>
</PropertyGroup>

<ItemGroup>
  <PackageReference Include="Roslynator.Analyzers" Version="4.*" PrivateAssets="all" />
</ItemGroup>
```

### 2. Run Dead Code Analysis

```bash
# Build with dead code warnings as errors
dotnet build -warnaserror:CS0168,CS0169,CS0219,CS0414,IDE0051,IDE0052,IDE0059,IDE0060,CA1822

# Full analysis
dotnet build
```

Key analyzer rules:
- **CS0168** - Variable declared but never used
- **CS0169** - Field never used
- **CS0219** - Variable assigned but never used
- **CS0414** - Field assigned but never read
- **IDE0051** - Private member unused
- **IDE0052** - Private member unread
- **IDE0059** - Unnecessary value assignment
- **IDE0060** - Unused parameter
- **CA1822** - Member can be static (not using instance data)

### 3. Check for Unused Dependencies

```bash
# List all package references
dotnet list package

# Check for deprecated packages
dotnet list package --deprecated

# Check for outdated packages
dotnet list package --outdated
```

### 4. Verify Each Finding

For each item detected, **thoroughly verify** whether the code is truly unused:

**Cross-check references:**
- All internal references across the solution
- Reflection-based access: `typeof()`, `nameof()`, `GetType()`
- Serialization attributes: `[JsonProperty]`, `[DataMember]`
- Dependency injection registrations
- Configuration binding targets
- Entity Framework navigation properties
- ASP.NET conventions (controllers, handlers)

**Check for indirect usage:**
- `dynamic` keyword usage
- `Activator.CreateInstance()`
- Assembly scanning (DI containers)
- Source generators
- Runtime compilation
- gRPC/SignalR contracts

### 5. Remove Verified Dead Code

**Only if absolutely certain the code is unused:**

1. Remove the dead code
2. Run tests immediately:
   ```bash
   dotnet test
   ```
3. Create a separate commit:
   ```bash
   git add .
   git commit -m "chore(cleanup): remove unused <member>"
   ```

### 6. Handle One Item at a Time

Do not batch deletions. Process one finding at a time to maintain traceability and safety.

### 7. Remove Unused Dependencies

```bash
# Remove unused package
dotnet remove package <package-name>

# Verify build still works
dotnet build
dotnet test
```

### 8. Suppress False Positives

For code used via reflection or conventions:
```csharp
// Used by EF Core conventions
[System.Diagnostics.CodeAnalysis.SuppressMessage(
    "CodeQuality", "IDE0051",
    Justification = "Used by Entity Framework navigation")]
private ICollection<Order> Orders { get; set; }
```

Or configure in `.editorconfig`:
```ini
[*.cs]
# Ignore unused members in specific files
[**/Entities/*.cs]
dotnet_diagnostic.IDE0051.severity = none
```

### 9. Final Validation

```bash
dotnet build -warnaserror:CS0168,CS0169,IDE0051,IDE0052
dotnet test
```

## Error Handling

| Issue | Cause | Resolution |
|-------|-------|------------|
| Test failures after removal | Code was actually used | Revert, investigate usage pattern |
| False positive | Reflection/convention usage | Add suppression with explanation |
| Build errors | Removed dependency still needed | Check all project references |

## Success Criteria

- All analyzer findings addressed (removed or suppressed)
- Each removal has its own commit
- All tests pass after each removal
- No suppressions without documented justification

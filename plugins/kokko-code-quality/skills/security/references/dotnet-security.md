# .NET Security Analysis

## Prerequisites

- .NET SDK 6.0+
- SecurityCodeScan.VS2019 analyzer (optional): `dotnet add package SecurityCodeScan.VS2019`

## Commands

### NuGet Vulnerability Scan

```bash
# Check for vulnerable dependencies
dotnet list package --vulnerable

# Include transitive dependencies
dotnet list package --vulnerable --include-transitive

# JSON output for parsing
dotnet list package --vulnerable --format json
```

### Enable Security Analyzers

Add to `.csproj` or `Directory.Build.props`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisLevel>latest</AnalysisLevel>
  <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
</PropertyGroup>

<ItemGroup>
  <PackageReference Include="SecurityCodeScan.VS2019"
                    Version="5.*" PrivateAssets="all" />
  <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers"
                    Version="8.*" PrivateAssets="all" />
</ItemGroup>
```

### Build with Security Warnings

```bash
# Build with warnings treated as errors for security rules
dotnet build /warnaserror:SCS0001,SCS0002,SCS0003,SCS0004,SCS0005

# Full build with all warnings visible
dotnet build -warnaserror
```

## Common Issues and Fixes

| Rule ID | Issue | Fix |
| ------- | ----- | --- |
| SCS0001 | Command injection | Use parameterized commands |
| SCS0002 | SQL injection | Use parameterized queries or EF Core |
| SCS0005 | Weak random | Use `RandomNumberGenerator` for security |
| SCS0006 | Weak hash (MD5/SHA1) | Use SHA256 or SHA512 |
| SCS0007 | XML external entity | Disable DTD processing |
| SCS0012 | Hardcoded password | Use configuration or secret manager |
| SCS0018 | Path traversal | Validate and sanitize file paths |
| SCS0029 | XSS vulnerability | Use HTML encoding, Razor auto-escapes |
| CA2100 | SQL injection | Use SqlParameter |
| CA2351 | Insecure deserializer | Use System.Text.Json with safe options |
| CA5350 | Weak crypto | Use modern algorithms (AES, RSA-2048+) |
| CA5351 | Broken crypto (DES) | Migrate to AES |

## Classification

For each finding, classify as:

- **TRUE_POSITIVE** - Fix now
- **NEEDS_REFACTOR** - Create safer abstraction then fix
- **FALSE_POSITIVE** - Justify and suppress locally
- **ACCEPT_RISK** - Open tracking issue with rationale

## Suppression Pattern

```csharp
#pragma warning disable SCS0005 // Using weak random for non-security shuffle
var random = new Random();
#pragma warning restore SCS0005

// Or use attribute
[SuppressMessage("Security", "SCS0005",
    Justification = "Non-security random for UI")]
```

## Validation

After each fix:

```bash
dotnet build
```

## Commit Format

```text
security(dotnet): mitigate <RuleID> in <file>
```

## Final Quality Gate

```bash
dotnet list package --vulnerable
dotnet build -warnaserror
```

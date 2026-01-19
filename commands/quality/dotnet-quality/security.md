# Security Hardening with .NET Analyzers

Use .NET security analyzers and NuGet audit to detect security issues in C# code.

## When to Use

- Before security audits
- After adding authentication or data handling code
- As part of CI/CD security checks

## Arguments

Usage: `/quality/dotnet-quality/security [target] [--severity low|medium|high]`

- `target` - Solution or project to scan (default: auto-detect .sln or .csproj)
- `--severity` - Minimum severity level to report (default: medium)

If `$ARGUMENTS` is provided, use it as the target path or options.

## Prerequisites

- .NET SDK 6.0+
- SecurityCodeScan.VS2019 analyzer (optional): `dotnet add package SecurityCodeScan.VS2019`

## Steps

### 1. Run NuGet Vulnerability Scan

```bash
# Check for vulnerable dependencies
dotnet list package --vulnerable

# Include transitive dependencies
dotnet list package --vulnerable --include-transitive

# JSON output for parsing
dotnet list package --vulnerable --format json
```

### 2. Enable Security Analyzers

Add to your `.csproj` or `Directory.Build.props`:
```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisLevel>latest</AnalysisLevel>
  <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
</PropertyGroup>

<ItemGroup>
  <PackageReference Include="SecurityCodeScan.VS2019" Version="5.*" PrivateAssets="all" />
  <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.*" PrivateAssets="all" />
</ItemGroup>
```

### 3. Run Build with Warnings

```bash
# Build with warnings treated as errors for security rules
dotnet build /warnaserror:SCS0001,SCS0002,SCS0003,SCS0004,SCS0005

# Full build with all warnings visible
dotnet build -warnaserror
```

### 4. Parse Findings

For each issue note:
- File:Line
- Rule ID (e.g., SCS0001, CA2100)
- Severity / Category
- Short description

Create a working list sorted: High severity first.

### 5. Classify Each Finding

Choose one:
- **TRUE_POSITIVE** - Fix now
- **NEEDS_REFACTOR** - Create safer abstraction then fix
- **FALSE_POSITIVE** - Justify and suppress locally
- **ACCEPT_RISK** - Open tracking issue with rationale

### 6. Common Issues and Fixes

| Rule ID | Issue | Fix |
|---------|-------|-----|
| SCS0001 | Command injection | Use parameterized commands, avoid string concatenation |
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

### 7. Fix Incrementally

For each finding fixed:
```bash
dotnet build
dotnet test
```

Commit if clean:
```bash
git add <files>
git commit -m "security(dotnet): mitigate <RuleID> in <file>"
```

### 8. Suppress False Positives

Use the narrowest suppression with explanation:
```csharp
#pragma warning disable SCS0005 // Using weak random for non-security shuffle
var random = new Random();
#pragma warning restore SCS0005

// Or use attribute
[SuppressMessage("Security", "SCS0005", Justification = "Non-security random for UI")]
```

### 9. Final Quality Gate

```bash
dotnet list package --vulnerable
dotnet build -warnaserror
dotnet test
```

## Error Handling

| Issue | Cause | Resolution |
|-------|-------|------------|
| Too many findings | Legacy codebase | Prioritize high severity, fix incrementally |
| False positives | Context not understood | Add targeted suppression with explanation |
| NuGet vulnerabilities | Outdated packages | Run `dotnet outdated` then update |

## Success Criteria

- Zero high-severity findings
- All medium-severity findings addressed or documented
- No suppressions without explanation
- All security fixes have tests

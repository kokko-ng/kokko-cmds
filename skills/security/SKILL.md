---
name: security
description: Security analysis and vulnerability fixes (bandit for py, eslint-security/npm-audit for js, SecurityCodeScan for dotnet)
argument-hint: "[py|js|dotnet]"
---

# Security Analysis Skill

Detect and fix security vulnerabilities in code using language-specific
security analyzers.

## Language Detection

Parse `$ARGUMENTS` for the language:

- `py` or `python` - Python security analysis
- `js` or `javascript` or `typescript` or `ts` - JavaScript/TypeScript
  security analysis
- `dotnet` or `csharp` or `cs` - .NET/C# security analysis

If no language specified, auto-detect:

1. Check for `pyproject.toml` or `setup.py` - use Python
2. Check for `package.json` - use JavaScript/TypeScript
3. Check for `*.csproj` or `*.sln` - use .NET

## Workflow

1. **Detect language** from arguments or project files
2. **Read reference file**: Load `references/<lang>-security.md` for
   tool-specific instructions
3. **Run security scanner** using the commands from the reference
4. **Parse findings** and prioritize by severity (High > Medium > Low)
5. **Fix each issue**:
   - TRUE_POSITIVE: Fix the vulnerability
   - FALSE_POSITIVE: Suppress with documented justification
   - NEEDS_REFACTOR: Create safer abstraction first
6. **Test after each fix**: Run tests to ensure no regression
7. **Commit incrementally**: Use message format
   `security(<tool>): mitigate <issue> in <file>`
8. **Final validation**: Run security scanner again to confirm zero
   high/medium findings

## Reference Files

Load the appropriate reference based on detected language:

- Python: `references/py-security.md`
- JavaScript/TypeScript: `references/js-security.md`
- .NET: `references/dotnet-security.md`

## Success Criteria

- Zero high-severity findings
- All medium-severity findings addressed or documented
- No suppressions without documented justification
- All security fixes have tests

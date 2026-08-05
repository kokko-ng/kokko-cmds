---
name: security
description: Run security analysis and fix findings with bandit (Python), eslint-plugin-security plus npm audit (JavaScript/TypeScript), or SecurityCodeScan (.NET). Use when the user asks for a security scan, a vulnerability audit, or fixes for insecure patterns and vulnerable dependencies. Trigger on "security scan", "vulnerabilities", "bandit", "npm audit", or "CVE"; pass py, js, or dotnet to pick the stack.
---

# Security Analysis Skill

Detect and fix security vulnerabilities in code using language-specific
security analyzers.

<!-- shared:language-detection start -- this block is byte-identical across all kokko-code-quality skills; scripts/check-skill-sync.sh enforces it -->

## Language Detection

Parse `$ARGUMENTS` for an explicit language and check only that one:

- `py` or `python` - Python
- `js`, `javascript`, `typescript`, or `ts` - JavaScript/TypeScript
- `dotnet`, `csharp`, or `cs` - .NET

If no language is specified, detect every language present -- a repo can be
more than one, and covering only the first match silently skips the rest:

1. `pyproject.toml` or `setup.py` present - Python
2. `package.json` or `tsconfig.json` present - JavaScript/TypeScript
3. `*.csproj` or `*.sln` files present - .NET

Run the full workflow once per detected language, and name every detected
language in the report -- including any skipped because the skill does not
support it.

<!-- shared:language-detection end -->

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
6. **Commit incrementally**: Use message format
   `fix(security): mitigate <issue> in <file>` — `fix` is the Conventional
   Commits type for vulnerability mitigations; `security` is not a valid type
7. **Final validation**: Run security scanner again to confirm zero
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

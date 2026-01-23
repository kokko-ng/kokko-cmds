---
name: complexity
description: Complexity analysis and refactoring (radon for py, eslint for js, .NET analyzers for dotnet)
argument-hint: "[py|js|dotnet]"
---

# Complexity Analysis Skill

Identify high-complexity code and refactor it safely using language-specific tools.

## Language Detection

Parse `$ARGUMENTS` for the language:

- `py` or `python` - Python complexity analysis with radon
- `js` or `javascript` or `typescript` or `ts` - JavaScript/TypeScript
  complexity with ESLint
- `dotnet` or `csharp` or `cs` - .NET code metrics analyzers

If no language specified, auto-detect:

1. Check for `pyproject.toml` or `setup.py` - use Python
2. Check for `package.json` - use JavaScript/TypeScript
3. Check for `*.csproj` or `*.sln` - use .NET

## Workflow

1. **Detect language** from arguments or project files
2. **Read reference file**: Load `references/<lang>-complexity.md` for
   tool-specific instructions
3. **Run complexity analyzer** using the commands from the reference
4. **Identify hotspots**: Functions/methods exceeding complexity thresholds
5. **Prioritize by**:
   - Worst complexity grade first
   - Frequency of change (git history)
   - Business criticality
6. **Establish safety net**: Ensure tests exist for target code
7. **Refactor incrementally** using tactics from reference file:
   - Extract function/method
   - Guard clauses for early returns
   - Dictionary/object dispatch for switch statements
   - Decompose conditionals
8. **Test after each change**: Run tests immediately
9. **Commit incrementally**: Use message format
   `refactor(complexity): reduce complexity in <symbol>`
10. **Final validation**: Run analyzer to confirm improvements

## Reference Files

Load the appropriate reference based on detected language:

- Python: `references/py-complexity.md`
- JavaScript/TypeScript: `references/js-complexity.md`
- .NET: `references/dotnet-complexity.md`

## When to Stop

- Complexity at acceptable threshold (varies by language)
- Further changes risk unnecessary churn
- Code is clear and testable

## Success Criteria

- No functions exceeding complexity threshold
- All tests pass
- Code is more readable and maintainable

---
name: complexity
description: Measure and reduce code complexity with radon (Python), ESLint complexity rules (JavaScript/TypeScript), or .NET analyzers. Use when the user asks to find overly complex code, lower cyclomatic complexity, or refactor tangled functions. Trigger on "complexity", "cyclomatic", "too complex", or "simplify this module"; pass py, js, or dotnet to pick the stack.
---

# Complexity Analysis Skill

Identify high-complexity code and refactor it safely using language-specific tools.

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
2. **Read reference file**: Load `references/<lang>-complexity.md` for
   tool-specific instructions
3. **Run complexity analyzer** using the commands from the reference
4. **Identify hotspots**: Functions/methods exceeding complexity thresholds
5. **Prioritize by**:
   - Worst complexity grade first
   - Frequency of change (git history)
   - Business criticality
6. **Refactor incrementally** using tactics from reference file:
   - Extract function/method
   - Guard clauses for early returns
   - Dictionary/object dispatch for switch statements
   - Decompose conditionals
7. **Commit incrementally**: Use message format
   `refactor(complexity): reduce complexity in <symbol>`
8. **Final validation**: Run analyzer to confirm improvements

## Reference Files

Load the appropriate reference based on detected language:

- Python: `references/py-complexity.md`
- JavaScript/TypeScript: `references/js-complexity.md`
- .NET: `references/dotnet-complexity.md`

## When to Stop

- Complexity at acceptable threshold (varies by language)
- Further changes risk unnecessary churn

## Success Criteria

- No functions exceeding complexity threshold
- Code is more readable and maintainable

---
name: types
description: Type checking and annotation fixes (mypy for py, tsc for js, nullable analyzers for dotnet)
argument-hint: "[py|js|dotnet]"
disable-model-invocation: true
---

# Type Checking Skill

Detect and fix type errors using language-specific type checkers.

## Language Detection

Parse `$ARGUMENTS` for the language:

- `py` or `python` - Python type checking with mypy
- `js` or `javascript` or `typescript` or `ts` - TypeScript compiler checks
- `dotnet` or `csharp` or `cs` - .NET nullable reference types and analyzers

If no language specified, auto-detect:

1. Check for `pyproject.toml` or `setup.py` - use Python
2. Check for `package.json` or `tsconfig.json` - use JavaScript/TypeScript
3. Check for `*.csproj` or `*.sln` - use .NET

## Workflow

1. **Detect language** from arguments or project files
2. **Read reference file**: Load `references/<lang>-types.md` for
   tool-specific instructions
3. **Run type checker** using the commands from the reference
4. **Parse errors** and group by error code/category
5. **Fix each error**:
   - Update code to satisfy type checker
   - Add proper type annotations where missing
   - Avoid `Any`/`any`/`object`/`dynamic` unless absolutely necessary
6. **Test after each fix**: Run tests to ensure no regression
7. **Commit incrementally**: Use message format
   `fix(types): resolve <error_code> in <file>`
8. **Final validation**: Run type checker again to confirm zero errors

## Reference Files

Load the appropriate reference based on detected language:

- Python: `references/py-types.md`
- JavaScript/TypeScript: `references/js-types.md`
- .NET: `references/dotnet-types.md`

## Critical Rules

- NEVER use `Any` (Python), `any` (TypeScript), or `object`/`dynamic` (.NET)
  without documented justification
- Limit scope of any type-escape mechanisms
- Add comments explaining why type-escape is unavoidable

## Success Criteria

- Zero type errors with strict settings enabled
- All type annotations are accurate
- No type-escape mechanisms without documented justification
- Tests pass after all type fixes

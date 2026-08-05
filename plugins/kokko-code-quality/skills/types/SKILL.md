---
name: types
description: Strengthen type safety with mypy (Python), tsc (TypeScript), or nullable reference analyzers (.NET). Use when the user asks to add type annotations, fix type errors, or tighten type-checker configuration. Trigger on "type errors", "type annotations", "mypy", "tsc", or "strict null checks"; pass py, js, or dotnet to pick the stack.
---

# Type Checking Skill

Detect and fix type errors using language-specific type checkers.

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
2. **Read reference file**: Load `references/<lang>-types.md` for
   tool-specific instructions
3. **Run type checker** using the commands from the reference
4. **Parse errors** and group by error code/category
5. **Fix each error**:
   - Update code to satisfy type checker
   - Add proper type annotations where missing
   - Avoid `Any`/`any`/`object`/`dynamic` unless absolutely necessary
6. **Commit incrementally**: Use message format
   `fix(types): resolve <error_code> in <file>`
7. **Final validation**: Run type checker again to confirm zero errors

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

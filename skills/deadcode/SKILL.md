---
name: deadcode
description: Dead code detection and removal (vulture for py, knip for js, .NET analyzers for dotnet)
argument-hint: "[py|js|dotnet]"
---

# Dead Code Detection Skill

Detect unused code and safely remove it using language-specific tools.

## Language Detection

Parse `$ARGUMENTS` for the language:

- `py` or `python` - Python dead code detection with vulture
- `js` or `javascript` or `typescript` or `ts` - JavaScript/TypeScript with knip
- `dotnet` or `csharp` or `cs` - .NET analyzers (IDE0051, IDE0052, etc.)

If no language specified, auto-detect:

1. Check for `pyproject.toml` or `setup.py` - use Python
2. Check for `package.json` - use JavaScript/TypeScript
3. Check for `*.csproj` or `*.sln` - use .NET

## Workflow

1. **Detect language** from arguments or project files
2. **Read reference file**: Load `references/<lang>-deadcode.md` for
   tool-specific instructions
3. **Run dead code analyzer** using the commands from the reference
4. **For each finding, THOROUGHLY VERIFY** it is truly unused:
   - Check all internal imports/references
   - Check dynamic/reflection usage
   - Check framework conventions (DI, ORM, routes, fixtures)
   - Check config-based registrations
   - Check entry points and plugin systems
5. **Remove verified dead code** ONLY if absolutely certain
6. **Test immediately** after each removal
7. **Commit each removal separately**: Use message format
   `chore(cleanup): remove unused <item>`
8. **Create whitelist/suppression** for false positives with explanation
9. **Final validation**: Run analyzer again to confirm clean

## Reference Files

Load the appropriate reference based on detected language:

- Python: `references/py-deadcode.md`
- JavaScript/TypeScript: `references/js-deadcode.md`
- .NET: `references/dotnet-deadcode.md`

## Critical Rules

- Handle ONE item at a time - do NOT batch deletions
- VERIFY thoroughly before removing - many tools have false positives
- Test IMMEDIATELY after each removal
- Revert if tests fail - investigate usage pattern

## Success Criteria

- All findings addressed (removed or whitelisted with justification)
- Each removal has its own commit
- All tests pass after each removal
- No suppressions without documented justification

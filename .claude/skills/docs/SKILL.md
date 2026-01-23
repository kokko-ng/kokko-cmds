---
name: docs
description: Documentation coverage and formatting (interrogate/pydocstyle for py, eslint-jsdoc for js, XML docs for dotnet)
argument-hint: "[py|js|dotnet]"
disable-model-invocation: true
---

# Documentation Coverage Skill

Ensure all public APIs have proper documentation using language-specific tools.

## Language Detection

Parse `$ARGUMENTS` for the language:
- `py` or `python` - Python docstrings with interrogate and pydocstyle
- `js` or `javascript` or `typescript` or `ts` - JSDoc with eslint-plugin-jsdoc
- `dotnet` or `csharp` or `cs` - XML documentation comments

If no language specified, auto-detect:
1. Check for `pyproject.toml` or `setup.py` - use Python
2. Check for `package.json` - use JavaScript/TypeScript
3. Check for `*.csproj` or `*.sln` - use .NET

## Persistence Requirement

**DO NOT STOP until ALL documentation issues are resolved.** This task requires complete coverage:
- Process every single file reported by the tools
- Fix every missing or malformed doc comment
- Continue working through all modules systematically
- Re-run analysis tools after each batch of fixes
- Only consider complete when tools report zero issues

If context window limits approach, document remaining files and continue in next session.

## Workflow

1. **Detect language** from arguments or project files
2. **Read reference file**: Load `references/<lang>-docs.md` for tool-specific instructions
3. **Run documentation analyzer** using commands from the reference
4. **Process files systematically** in order:
   - Public API functions and classes first
   - Complex functions next
   - Entry points and orchestration code
   - Utility functions and helpers
   - Private/internal functions last
5. **Add documentation** following the style guide in the reference
6. **Verify each file**: Run analyzer on specific file after fixing
7. **Commit incrementally**: Use message format `docs(<module>): add docs to <file>`
8. **Final validation**: Run full analysis to confirm 100% coverage

## Reference Files

Load the appropriate reference based on detected language:
- Python: `references/py-docs.md` (Google-style docstrings)
- JavaScript/TypeScript: `references/js-docs.md` (JSDoc format)
- .NET: `references/dotnet-docs.md` (XML documentation)

## Success Criteria

- 100% documentation coverage on public APIs
- Zero style violations
- All tests pass
- Documentation follows consistent format for the language

---
name: docs
description: Check and improve documentation coverage with interrogate/pydocstyle (Python), eslint-plugin-jsdoc (JavaScript/TypeScript), or XML doc comments (.NET). Use when the user asks to add docstrings, audit doc coverage, or fix docstring formatting. Trigger on "docstrings", "documentation coverage", "jsdoc", or "xml docs"; pass py, js, or dotnet to pick the stack.
---

# Documentation Coverage Skill

Ensure all public APIs have proper documentation using language-specific tools.

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

## Persistence Requirement

**DO NOT STOP until ALL documentation issues are resolved.** This task
requires complete coverage:

- Process every single file reported by the tools
- Fix every missing or malformed doc comment
- Continue working through all modules systematically
- Re-run analysis tools after each batch of fixes
- Only consider complete when tools report zero issues

If context window limits approach, document remaining files and continue in
next session.

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
- Documentation follows consistent format for the language

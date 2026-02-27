---
name: architecture
description: Architecture enforcement (import-linter for py, dependency-cruiser for js)
argument-hint: "[py|js]"
---

# Architecture Enforcement Skill

Detect and fix architectural violations -- dependency structure, coupling,
cycles, and layering -- using language-specific architecture analyzers.

## Language Detection

Parse `$ARGUMENTS` for the language:

- `py` or `python` - Python architecture enforcement
- `js` or `javascript` or `typescript` or `ts` - JavaScript/TypeScript
  architecture enforcement

If no language specified, auto-detect:

1. Check for `pyproject.toml` or `setup.py` - use Python
2. Check for `package.json` - use JavaScript/TypeScript

## Workflow

1. **Detect language** from arguments or project files
2. **Read reference file**: Load `references/<lang>-architecture.md` for
   tool-specific instructions
3. **Check for config**: Look for the tool's config file; create one if missing
   using the reference's bootstrap instructions
4. **Run architecture analyzer** using the commands from the reference
5. **Parse violations** from output (cycles, forbidden imports, layer breaches)
6. **Fix each violation**:
   - CYCLE: Break circular dependency by extracting shared module or
     introducing an interface
   - FORBIDDEN_IMPORT: Move import to allowed layer or restructure module
   - LAYER_VIOLATION: Invert dependency direction or introduce abstraction
   - COUPLING: Extract shared types/interfaces to reduce coupling
7. **Commit incrementally**: Use message format
   `refactor(architecture): <description>`
8. **Final validation**: Run architecture analyzer again to confirm zero
   violations

## Reference Files

Load the appropriate reference based on detected language:

- Python: `references/py-architecture.md`
- JavaScript/TypeScript: `references/js-architecture.md`

## Success Criteria

- Zero architecture violations from the analyzer
- No circular dependencies remain
- All layer boundaries enforced

---
name: architecture
description: Enforce architectural layering and import rules with import-linter (Python) or dependency-cruiser (JavaScript/TypeScript). Use when the user asks to enforce architecture, check layering, define import contracts, or fix dependency-direction violations. Trigger on "architecture check", "layer violations", "import rules", "import-linter", or "dependency-cruiser"; pass py or js to pick the stack.
---

# Architecture Enforcement Skill

Detect and fix architectural violations -- dependency structure, coupling,
cycles, and layering -- using language-specific architecture analyzers.

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

This skill supports Python and JavaScript/TypeScript only. If .NET is
requested or detected, say it is not supported here and continue with the
supported languages.

## Workflow

1. **Detect language** from arguments or project files
2. **Read reference file**: Load `references/<lang>-architecture.md` for
   tool-specific instructions
3. **Check for config**: Look for the tool's config file; create one if missing
   using the reference's bootstrap instructions
4. **Run architecture analyzer** using the commands from the reference. For
   Python, use the Rich output workaround from the reference to get readable
   output (import-linter v2.10+ renders Unicode box-drawing via Rich that is
   unreadable in non-TTY contexts)
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

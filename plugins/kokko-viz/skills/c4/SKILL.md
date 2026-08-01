---
name: c4
description: Authoring rules and shared templates for C4 architecture and codemap documents - mandatory source-file hyperlinks, no validation report files, template and diagram conventions. Use when the user asks to generate, update, or verify C4 models, architecture diagrams, or codemap documentation. Trigger on "C4", "codemap", "architecture diagram", or any /c4-map, /c4-update, or /c4-verify run.
---

# C4 Authoring Skill

The rules every generated C4 or codemap document must follow, and the shared
templates the `/c4-map`, `/c4-update` and `/c4-verify` commands write from.

These rules used to live in the global `CLAUDE.md`, where they applied to every
session whether or not it touched architecture documentation. They belong here:
loaded when C4 work is actually happening, alongside the templates they
constrain.

Read this before writing or editing anything under `codemap/`, and whenever a
command below cites a `c4-templates.md#...` anchor.

## Rules

### 1. Source file links are mandatory

Every source file, module, class, or other code element named in a generated
`.md` MUST be a markdown hyperlink to the actual file it refers to. Never bare
text like `src/db.py`.

- Use **repo-relative paths** computed from the document's own location, so the
  link resolves when browsing the repo on GitHub.
- **Verify the link target exists on disk before writing it.** A confident link
  to a file that was renamed is worse than no link.
- Line anchors are the one exception to repo-relative: to point at a specific
  line, use an absolute GitHub blob URL derived from `git remote get-url origin`
  and the default branch. Plain file references stay repo-relative.

Full detail and a worked example: `references/c4-templates.md#source-file-links`.

This rule is also a verification check — `/c4-verify` treats a bare-text file
reference as a hierarchy issue and fixes it.

### 2. Never write validation or verification reports into the repo

Report verification results **in the reply message**. Do not create
`VERIFICATION.md`, a report file, an audit log, or any other validation artifact
in the repository. The only file a verification run may write outside the
diagrams it is fixing is the timestamp in `codemap/README.md`.

### 3. Every document carries navigation and a timestamp

Each generated `.md` includes a parent navigation link, a drill-down table to
its children, and a `<!-- Last updated: YYYY-MM-DD -->` comment. Links must
resolve; drill-down tables must match the folders that actually exist.

### 4. Diagrams and docs stay paired

Each level owns a `.puml`, a `.md`, and a generated `.png`. A PNG whose `.puml`
is newer is stale and must be regenerated. Never hand-edit a PNG or let a `.md`
reference an image that does not exist.

## Templates and schemas

`references/c4-templates.md` holds the shared material for all three commands.
Read the section an instruction cites rather than the whole file:

| Anchor | Contents |
| ------ | -------- |
| `#output-structure` | The `codemap/` folder layout |
| `#markdown-templates` | `context.md`, `container.md`, `component.md` skeletons |
| `#plantuml-reference` | Library setup, include statements and valid macros per level |
| `#json-output-schemas` | Phase output and validation issue schemas |
| `#search-strategies` | How to detect external systems, containers, components |
| `#source-file-links` | Rule 1 in full, with a worked relative-path example |
| `#navigation-link-patterns` | Parent links and drill-down table format |
| `#png-generation` | PlantUML invocation |
| `#error-handling` | Phase and validation failure responses |

Inside a plugin command the file is at
`${CLAUDE_PLUGIN_ROOT}/skills/c4/references/c4-templates.md`. If that variable
is not set, locate it with Glob: `**/kokko-viz/skills/c4/references/c4-templates.md`
under `~/.claude/plugins/`.

## Commands

| Command | Purpose |
| ------- | ------- |
| `/c4-map` | Build a C4 model from scratch (context, containers, components) |
| `/c4-update` | Bring an existing model in line with code changes |
| `/c4-verify` | Check an existing model against the code and fix what is wrong |

All three apply the rules above. When invoked directly rather than through a
command, follow the same rules and the same output structure.

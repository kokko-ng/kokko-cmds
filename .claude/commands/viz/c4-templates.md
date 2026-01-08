# C4 Architecture Templates Reference

Shared templates and patterns for c4-map, c4-update, and c4-verify commands.

---

## Output Structure

```
codemap/
├── README.md
├── VERIFICATION.md
└── <system-id>/
    ├── context.puml
    ├── context.png
    ├── context.md
    └── containers/
        └── <container-id>/
            ├── container.puml
            ├── container.png
            ├── container.md
            └── components/
                └── <component-id>/
                    ├── component.puml
                    ├── component.png
                    ├── component.md
                    └── code/
                        ├── classes.puml
                        ├── classes.png
                        └── classes.md
```

---

## Markdown Templates

### context.md

```markdown
# System Context: [System Name]

<!-- Last updated: YYYY-MM-DD -->

[System description]

## Diagram

![System Context](./context.png)

## Actors

| Actor | Description |
|-------|-------------|
| [Name] | [Description] |

## External Systems

| System | Type | Description |
|--------|------|-------------|
| [Name] | [Type] | [Description] |

## Drill Down - Containers

| Container | Technology | Description | Details |
|-----------|------------|-------------|---------|
| [Name] | [Tech] | [Desc] | [View](./containers/<id>/container.md) |
```

### container.md

```markdown
# Container: [Container Name]

<!-- Last updated: YYYY-MM-DD -->

**Parent:** [System Context](../../context.md)

[Container description]

## Diagram

![Container](./container.png)

## Technology

| Aspect | Value |
|--------|-------|
| Framework | [Framework] |
| Runtime | [Runtime] |

## Dependencies

- External: [List external systems]
- Containers: [List container dependencies]

## Drill Down - Components

| Component | Responsibility | Details |
|-----------|----------------|---------|
| [Name] | [Desc] | [View](./components/<id>/component.md) |
```

### component.md

```markdown
# Component: [Component Name]

<!-- Last updated: YYYY-MM-DD -->

**Parent:** [Container Name](../../container.md)
**System:** [System Context](../../../../context.md)

[Component description]

## Diagram

![Component](./component.png)

## Responsibility

[Detailed responsibility]

## Dependencies

- Internal: [Same container dependencies]
- Cross-Container: [Other container dependencies]

## Drill Down - Code

| Class | Purpose | Details |
|-------|---------|---------|
| [Name] | [Desc] | [View](./code/classes.md) |
```

### classes.md

```markdown
# Code: [Component Name] Classes

<!-- Last updated: YYYY-MM-DD -->

**Parent:** [Component Name](../component.md)
**Container:** [Container Name](../../../container.md)
**System:** [System Context](../../../../../context.md)

## Class Diagram

![Classes](./classes.png)

## Classes

| Class | File | Purpose | Pattern |
|-------|------|---------|---------|
| [Name] | [path:line] | [Desc] | [Pattern] |

## Design Patterns

| Pattern | Implementation | Description |
|---------|----------------|-------------|
| [Pattern] | [Class] | [Desc] |

## Key Methods

### [ClassName]
- `method_name(args)` - Description
```

---

## PlantUML Reference

### Include Statements by Level

| Level | Include Statement |
|-------|-------------------|
| Context | `!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml` |
| Container | `!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml` |
| Component | `!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml` |
| Code | Standard PlantUML (no C4 include) |

### Valid Macros by Level

| Level | Valid Macros |
|-------|-------------|
| Context | `Person()`, `System()`, `System_Ext()`, `Rel()` |
| Container | `Container()`, `ContainerDb()`, `ContainerQueue()`, `Rel()` |
| Component | `Component()`, `Rel()` |
| Code | `class`, `interface`, `abstract`, arrows |

---

## JSON Output Schemas

### Context Phase Output

```json
{
  "SYSTEM_ID": "kebab-case-id",
  "SYSTEM_NAME": "Human Readable Name",
  "SYSTEM_DESCRIPTION": "Description",
  "EXTERNAL_SYSTEMS": [
    {"id": "string", "name": "string", "type": "string", "evidence": "file:line"}
  ],
  "ACTORS": [
    {"id": "string", "name": "string", "description": "string"}
  ],
  "PRELIMINARY_CONTAINERS": [
    {"id": "string", "name": "string", "type": "Application|Database|Queue"}
  ]
}
```

### Container Phase Output

```json
{
  "SYSTEM_ID": "from-context",
  "CONTAINERS": [
    {
      "id": "string",
      "name": "string",
      "technology": "string",
      "description": "string",
      "source_path": "path/",
      "external_deps": ["external-id"],
      "container_deps": ["container-id"],
      "PRELIMINARY_COMPONENTS": [
        {"id": "string", "name": "string", "path": "path/"}
      ]
    }
  ],
  "CONTAINER_RELATIONSHIPS": [
    {"from": "id", "to": "id", "protocol": "SQL|HTTP|gRPC", "description": "string"}
  ]
}
```

### Component Phase Output

```json
{
  "SYSTEM_ID": "from-context",
  "COMPONENTS_BY_CONTAINER": {
    "container-id": [
      {
        "id": "string",
        "name": "string",
        "parent_container": "container-id",
        "source_path": "path/",
        "responsibility": "string",
        "internal_deps": ["component-id"],
        "cross_container_deps": [],
        "KEY_CLASSES": [
          {"name": "ClassName", "file": "path:line", "importance": "core|supporting"}
        ]
      }
    ]
  }
}
```

### Code Phase Output

```json
{
  "SYSTEM_ID": "from-context",
  "CODE_BY_COMPONENT": {
    "container-id": {
      "component-id": {
        "classes": [
          {
            "name": "ClassName",
            "file": "path:line",
            "purpose": "string",
            "methods": ["method1", "method2"],
            "inherits": "ParentClass|null",
            "pattern": "Factory|Repository|null"
          }
        ],
        "patterns_found": ["Pattern1"],
        "class_relationships": [
          {"from": "ClassA", "to": "ClassB", "type": "uses|inherits"}
        ]
      }
    }
  }
}
```

### Validation Issue Schema

```json
{
  "id": "ISSUE-001",
  "severity": "error|warning|info",
  "category": "completeness|accuracy|hierarchy|diagram|image_pairing",
  "description": "string",
  "location": "file/path",
  "fix": "How to resolve"
}
```

### Change Detection Schema

```json
{
  "id": "change-001",
  "type": "ADDITION|DELETION|MODIFICATION|RENAME",
  "level": "CONTEXT|CONTAINER|COMPONENT|CODE",
  "affected_element": {"id": "string", "current_path": "string", "source_path": "string"},
  "description": "string",
  "cascade_up": true,
  "cascade_down": false,
  "priority": "high|medium|low"
}
```

---

## Search Strategies

### External System Detection

```
Glob: **/*.env*, **/config.*, **/settings.*
Grep: "requests\.", "httpx\.", "import.*azure", "import.*aws"
Check: docker-compose.yml for external services
```

### Container Detection

```
Glob: **/Dockerfile, **/docker-compose.yml, **/main.py, **/app.py
Grep: "FastAPI", "Express", "Flask", "if __name__"
Check: Directory structure for deployable units
```

### Component Detection

```
Glob: **/__init__.py, **/index.ts
Grep: "class \w+", "def \w+", "export"
Check: Package/module structure under each container
```

### Code/Class Detection

```
Grep: "class \w+\(", "class \w+:", "interface \w+"
Check: Inheritance patterns, design pattern implementations
```

---

## Navigation Link Patterns

| From Level | Parent Link | Example |
|------------|-------------|---------|
| Container | `../../context.md` | Go to system context |
| Component | `../../container.md` | Go to parent container |
| Code | `../component.md` | Go to parent component |

### Drill-Down Table Format

```markdown
| Element | Description | Details |
|---------|-------------|---------|
| [Name] | [Desc] | [View](./path/to/file.md) |
```

---

## PNG Generation

```bash
# Generate all PNGs
find codemap -name "*.puml" -exec plantuml -tpng {} \;

# Generate single PNG
plantuml -tpng codemap/<system-id>/context.puml
```

---

## Error Handling

### Phase Failure Response

- Report which phase failed and why
- Do NOT proceed to dependent phases
- Suggest resolution steps

### Validation Failure Response

- List all error-severity issues first
- Offer to proceed with warnings only
- Flag items requiring manual review

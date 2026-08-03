# kokko-env

Dev environment setup and maintenance: install the
[kokko-ng/kokko-devcontainer](https://github.com/kokko-ng/kokko-devcontainer)
starter into a project, refresh the devcontainer config inside a running
container, and update Claude Code plugins to their latest marketplace
versions.

```bash
/plugin install kokko-env@kokko-ng-kokko-cmds
```

## Commands

| Command | Purpose |
| ------- | ------- |
| `/devcontainer-update` | Pull the latest `.devcontainer/` from kokko-devcontainer and apply it live, reporting what still needs a rebuild |
| `/plugins-update` | Refresh the marketplaces, update installed plugins to the published versions, then prompt for `/reload-plugins` |

## Skills

| Skill | Purpose |
| ----- | ------- |
| `devcontainer-setup` | Install the kokko-devcontainer starter into a directory (defaults to the current one), tailor it to that project, and bring the container up |

`devcontainer-setup` is the first-time install and runs on the host;
`/devcontainer-update` is the follow-up for a project that already has a
`.devcontainer/`. It applies config by re-running the project's own
`post-create.sh --config-only`; a `.devcontainer/` copied before that flag
existed needs updating first — the command detects this and says so.

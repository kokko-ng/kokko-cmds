# Devcontainer Templates

Templates live in `${CLAUDE_PLUGIN_ROOT}/devcontainer-templates/`.

## base.json — Python 3.13 + Node 20 + uv

Always included. Provides:
- Python 3.13 via `ghcr.io/devcontainers/features/python:1`
- Node 20 via `ghcr.io/devcontainers/features/node:1`
- uv (fast Python package manager) via `postCreateCommand`
- Claude Code npm package via `postCreateCommand`
- `~/.claude/` bind-mounted from host (auth + config persistence)
- `~/.claude.json` copied at creation (preferences/state)
- Workspace bind-mounted at `/workspace`
- `ANTHROPIC_API_KEY` forwarded if set on host

## with-dotnet.json — adds .NET 8 SDK

Everything from base.json plus:
- .NET 8 SDK via `ghcr.io/devcontainers/features/dotnet:2`

## How the Skill Generates a devcontainer.json

When the project has no `.devcontainer/devcontainer.json`, the skill:
1. Asks user which runtimes they want via AskUserQuestion
2. Reads the appropriate template from this directory
3. Writes it to `<project>/.devcontainer/devcontainer.json`

## Customising a Generated Config

After generation you can edit `.devcontainer/devcontainer.json` freely. The skill will
use the existing file on subsequent runs and will NOT overwrite it.

## Key Config Notes

- `workspaceFolder: /workspace` — all project files are at `/workspace` inside the container
- `postCreateCommand` runs as the `vscode` user (UID 1000) after container creation
- The `~/.claude/` mount is read-write so credentials and sessions persist back to the host
- The `~/.claude.json` is copied (not mounted) so the container can write to it freely
- `ANTHROPIC_API_KEY` is forwarded via `remoteEnv` but only if set in the host shell

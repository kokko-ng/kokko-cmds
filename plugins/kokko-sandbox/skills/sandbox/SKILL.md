---
name: sandbox
description: Launch Claude Code inside an isolated devcontainer. Sandboxes file system access to the project workspace while providing full Python, Node, and optional .NET runtimes.
argument-hint: "[--dotnet] [--rebuild] [--workspace <path>]"
---

# Sandbox Skill

Starts a devcontainer for the current project and launches Claude Code inside it.
Claude in the sandbox can only access `/workspace` (the project directory) — not the
host filesystem, other projects, or system files.

## Arguments

Parse `$ARGUMENTS` for:

- `--dotnet` - Include .NET 8 SDK in the container (default: omit)
- `--rebuild` - Force rebuild the container image even if it already exists
- `--workspace <path>` - Override workspace path (default: current working directory)

## Workflow

### 1. Resolve Workspace

Determine the workspace directory:

- If `--workspace <path>` provided, use that path
- Otherwise use the current working directory from context

Verify the workspace is under `$HOME`. If not, stop and explain:

```text
The workspace must be under your home directory because colima only mounts ~/
into the container VM. Move the project under ~/Documents/ or similar.
```

### 2. Check Prerequisites

Run the following checks in parallel:

**devcontainer CLI:**

```bash
which devcontainer 2>/dev/null
```

If missing, install it:

```bash
npm install -g @devcontainers/cli
```

**Docker / colima:**

```bash
docker info 2>/dev/null | grep "Server Version"
```

If Docker is not running:

```bash
colima start
```

Wait up to 30 seconds for Docker to become available, checking every 3 seconds.

### 3. Find or Create devcontainer.json

Check if `<workspace>/.devcontainer/devcontainer.json` already exists.

**If it exists:**
Confirm with the user in a brief message: "Using existing .devcontainer/devcontainer.json."
Do NOT overwrite or modify the existing file.

**If it does not exist:**
Use AskUserQuestion to ask:

- Which runtimes to include (multiSelect):
  - "Python 3.13 + uv" (always pre-selected, recommended)
  - "Node 20 / npm" (always pre-selected, recommended)
  - ".NET 8 SDK" (optional)

Based on the selection:

- If .NET is selected: use the template at `${CLAUDE_PLUGIN_ROOT}/devcontainer-templates/with-dotnet.json`
- Otherwise: use `${CLAUDE_PLUGIN_ROOT}/devcontainer-templates/base.json`

Create `<workspace>/.devcontainer/devcontainer.json` by copying the chosen template.
Confirm: "Created .devcontainer/devcontainer.json with [selected runtimes]."

### 4. Check Auth Status

Read `references/auth-guide.md` for full auth details.

Check in order:

1. `[ -n "$ANTHROPIC_API_KEY" ]` — API key auth (immediate, no setup needed)
2. `[ -f "$HOME/.claude/.credentials.json" ]` — OAuth credentials already exist

If **neither** is true, warn the user:

```text
First-time login required inside the sandbox.

After the container starts, open a NEW terminal tab and run:

  docker exec -it <containerId> bash
  claude
  # then type: /login
  # Complete the browser OAuth flow
  # Credentials are saved to ~/.claude/.credentials.json on the host
  # All future sandbox starts will authenticate automatically

Continuing with container setup...
```

Note that `<containerId>` will be shown after the container starts in step 5.

### 5. Start the Container

```bash
devcontainer up --workspace-folder <workspace> [--config <workspace>/.devcontainer/devcontainer.json] [--rebuild-image]
```

Include `--rebuild-image` only if `--rebuild` argument was passed.

This command:

- Builds the image if not cached (slow: ~5 min first time, cached thereafter)
- Runs `postCreateCommand` (installs uv + Claude Code npm package, copies ~/.claude.json)
- Mounts `~/.claude/` and the workspace

Parse the JSON output to extract `containerId`.

If the command fails, check for common issues:

- "bind source path does not exist" → workspace is not under `$HOME`
- "Cannot connect to Docker" → run `colima start` and retry
- Build errors → show the full output to the user

### 6. Show Connect Commands

Once the container is up, output clear instructions:

```text
Sandbox container ready.

Container ID: <containerId>
Workspace:    /workspace (mapped from <workspace>)

To start a sandboxed Claude Code session, run in your terminal:

  docker exec -it <containerId> bash -c "cd /workspace && claude"

The sandboxed Claude can only read/write /workspace.
It cannot access ~/Documents, ~/.ssh, system files, or other projects.

To stop the sandbox when done:

  docker stop <containerId>
```

If first-time login was flagged in step 4, also show the `/login` instructions here,
with the actual container ID filled in.

## Reference Files

- `references/auth-guide.md` - OAuth credential setup, first-time login steps
- `references/devcontainer-templates.md` - Template contents and customisation guide

## Success Criteria

- `devcontainer up` exits with `"outcome":"success"` in its JSON output
- Container ID is printed clearly
- `docker exec -it <containerId> claude --version` would succeed (optionally verify this)
- Auth status is communicated clearly: either "ready" or "first-time login required with exact steps"

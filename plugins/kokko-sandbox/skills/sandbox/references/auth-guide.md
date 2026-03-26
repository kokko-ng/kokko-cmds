# Claude Auth in Sandbox Containers

## How Auth Works

The sandbox uses the npm `@anthropic-ai/claude-code` package inside the container.
This version reads OAuth credentials from `~/.claude/.credentials.json`.

The `~/.claude/` directory is bind-mounted from the host, so:
- Credentials written inside the container persist to the host's `~/.claude/`
- A **one-time login** inside the container makes all future container starts automatic

## Checking Auth Status

Auth is ready if either of these exist:
1. `~/.claude/.credentials.json` (OAuth) - created by running `/login` in the container once
2. `ANTHROPIC_API_KEY` env var set in the shell (API key auth)

Check command:
```bash
[ -f "$HOME/.claude/.credentials.json" ] && echo "OAuth ready" || echo "Login required"
[ -n "$ANTHROPIC_API_KEY" ] && echo "API key set" || echo "No API key"
```

## First-Time Login (one-time only)

After the container starts, open a new terminal and run:

```bash
docker exec -it <containerId> bash
claude
# Inside claude, type: /login
# Complete the browser OAuth flow
# Credentials saved to ~/.claude/.credentials.json on the host
# Exit claude with: /exit
```

After this, all future container starts authenticate automatically.

## API Key Auth (alternative)

If you have an `ANTHROPIC_API_KEY` in your environment:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

Add this to `~/.zshrc` or `~/.bashrc` so it persists. The devcontainer forwards it
via `remoteEnv`.

## Important Constraint: Workspace Must Be Under Home Directory

Colima (the container runtime) only mounts `~/` into the VM by default. The workspace
folder passed to `devcontainer up` must be under `$HOME`. Paths like `/tmp/` will fail
with "bind source path does not exist".

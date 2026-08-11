---
name: devcontainer-setup
description: Install the kokko-ng/kokko-devcontainer starter into a directory (defaults to the current one), tailor it to that project, and bring the container up. Accepts an optional target directory plus --ref <branch-or-tag>, --docs, and --no-up flags.
---

# Devcontainer Setup Skill

Install the [kokko-ng/kokko-devcontainer](https://github.com/kokko-ng/kokko-devcontainer)
starter into a project: copy `.devcontainer/`, adapt it to what that project
actually is, and start the container.

This is the **first-time install**. Use `/devcontainer-update` instead when the
project already has a `.devcontainer/` and the job is to pull newer upstream
files into it.

Run this on the **host** (macOS), not inside a devcontainer. The starter assumes
Colima as the Docker runtime and the `devcontainer` CLI as the launcher.

## Arguments

`$ARGUMENTS`:

| Argument | Effect |
| -------- | ------ |
| `[target-directory]` | Where to install. Defaults to the current working directory. |
| `--ref <branch-or-tag>` | Take the starter from that ref instead of the default branch. |
| `--docs` | Also copy the root-level docs (`INSTRUCTIONS.md`, `MANAGING.md`) and `ghostty/config`. Off by default. |
| `--no-up` | Install and tailor the files, then stop. Do not build or start the container. |

## Steps

### 1. Preflight

```bash
TARGET="${1:-$PWD}"     # resolve to an absolute path
ls -la "$TARGET"
ls -la "$TARGET/.devcontainer" 2>/dev/null && echo "ALREADY HAS .devcontainer"
git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null || echo "NOT A GIT REPO"
[ -f /.dockerenv ] && echo "INSIDE A CONTAINER" || echo "on the host"
```

Stop and ask when any of these is true:

- **The target is a folder of projects, not a project.** The default target is
  `$PWD`, and a `~/code`-style parent directory passes every other check here
  while being the wrong answer — one shared container across ten unrelated
  projects. Suspect this when the target itself has no project markers
  (`pyproject.toml`, `package.json`, `*.csproj`, `go.mod`, `src/`) but two or
  more of its subdirectories do. Confirm the intended project before copying
  anything.
- **The target directory does not exist.** Do not invent a path. But when the
  user has explicitly named a new directory ("a new folder called `sandbox/`"),
  that *is* the confirmation — create it, `git init` it, and say so in the
  report.
- **`.devcontainer/` already exists.** This skill would overwrite it. Report
  what is there and recommend `/devcontainer-update`, which merges instead.
- **Inside a container.** The build has to happen on the host. Say so and stop.
- **Target is not a git repo.** Not fatal — the starter works in a plain
  directory — but without a repo there is no version control and no reflog to
  recover from, and the container's git recoverability settings protect
  nothing. For a directory this skill just created, `git init` it rather than
  merely reporting the gap; for a pre-existing directory, say so and let the
  user decide.

Then check the host toolchain (report what is missing; do not install anything
without asking):

```bash
command -v colima devcontainer docker || true
colima list                     # existing profiles and their specs
colima status 2>&1 | head -5
docker ps >/dev/null 2>&1 && echo "docker OK" || echo "docker NOT reachable"
```

Missing tooling maps to:

```bash
brew install colima docker docker-compose devcontainer
brew install --cask ghostty     # only with --docs, or if the user wants it
colima start --cpu 8 --memory 16 --disk 150
```

Those `colima start` flags create a *new* profile. They are not the common case:
usually `colima list` shows an existing profile that is merely `Stopped`, often
with smaller specs. A bare `colima start` reuses that profile's existing specs —
the flags above are ignored on a profile that already exists, except that
`--disk` can grow one. A disk can never shrink, so recreating the VM is the only
way back down. `--disk 150` is deliberately large because each image built from
this starter is 5-6 GB.

Starting the VM also restarts every container that was running when it stopped,
including ones belonging to other projects. Worth a line in the report if
`docker ps` shows containers this skill did not create.

`colima status` on a stopped VM exits non-zero with
`level=fatal msg="colima is not running"` — that, not a `docker ps` error, is
usually the first symptom you see.

If Colima reports "already running" but `docker ps` fails, check the VM disk
before anything else — a full disk kills the daemon while `colima status` still
looks healthy:

```bash
colima ssh -- df -h /
```

### 2. Fetch the starter

```bash
UPSTREAM=/tmp/kokko-devcontainer-setup
rm -rf "$UPSTREAM"
git clone --depth=1 https://github.com/kokko-ng/kokko-devcontainer "$UPSTREAM"
# with --ref: git clone --depth=1 --branch <ref> ...
git -C "$UPSTREAM" log -1 --format='%h %ad %s' --date=short
```

Clone failed (no network, bad ref) → report the actual error and stop. Never
hand-write a `.devcontainer/` as a fallback.

### 3. Copy it in

```bash
cp -R "$UPSTREAM/.devcontainer" "$TARGET/.devcontainer"
```

With `--docs`, also copy `INSTRUCTIONS.md`, `MANAGING.md` and
`ghostty/config` — but never overwrite a file the project already has. Name any
skipped file in the report.

Do **not** copy the starter's `README.md` over the project's own.

Merge the starter's `.gitignore` entries into the project's rather than
replacing the file. The entries that matter are `.devcontainer/certs/` (real CA
certs extracted from the host keychain at build time) and the Playwright runtime
artifacts (`.playwright*/`, `test-results/`, `playwright-report/`). If the
project has no `.gitignore`, copy the starter's.

### 4. Tailor it to this project

The starter targets FastAPI (`src/`) + Vue (`ui/`). Inspect the target and
adjust — read the actual layout, do not assume it:

| What | Where | Adjust when |
| ---- | ----- | ----------- |
| `"name"` | `devcontainer.json` | Always — set it to the project name (default is `fastapi-vue-dev`). |
| `PYTHONPATH` | `devcontainer.json` `containerEnv` | Python source is not in `src/`. Drop the variable for a non-Python project. |
| `forwardPorts` | `devcontainer.json` | The project's real ports differ from `[8000, 5173]`. |
| Frontend directory | `post-create.sh` (`cd ui`) | The frontend lives elsewhere, or there is none. |
| `azure-cli` feature | `devcontainer.json` `features` | The project has no Azure usage — remove the feature. |
| `docker-in-docker` feature | `devcontainer.json` `features` | Nothing builds containers inside the devcontainer. It costs real disk (see `MANAGING.md`). |
| ODBC block (`msodbcsql18`) | `Dockerfile` | No Azure SQL / pyodbc — remove the block, it is a slow layer. |
| Node version | `devcontainer.json` node feature | The project pins a different major. |
| Python version | `Dockerfile` base image tag | The project targets a different Python. |
| Plugin roster | `config/claude/settings.json` | The user wants a different set of Claude Code plugins. |

Evidence to read before editing: `pyproject.toml`, `package.json`, `uv.lock`,
`requirements.txt`, `*.csproj`, the presence of `src/`/`app/`/`ui/`/`frontend/`,
existing port numbers in config or compose files, and any `.env.example`.

`HOST_USER` needs no edit — `devcontainer.json` injects it from
`${localEnv:USER}`. Bundled config paths resolve relative to `post-create.sh`,
so the workspace folder can be named anything.

Report every edit you make and why. Where the right value is genuinely
ambiguous (a monorepo with three candidate frontends, say), ask rather than
guessing.

**Greenfield target.** An empty directory — a scratch or sandbox project — has
none of that evidence, so the table above has nothing to act on. Do not infer a
stack from the directory name. Instead:

- Set `"name"`, and leave `PYTHONPATH` and `forwardPorts` at the starter
  defaults. They are harmless when they point at paths and ports that do not
  exist yet, and they are right again as soon as the directory has content.
- Ask once, in a single question, which of the expensive optional pieces to
  keep: `docker-in-docker`, the `azure-cli` feature, the ODBC block, the Node
  feature. Each costs real build time or disk, and nothing in an empty
  directory justifies either keeping or dropping it.
- Say in the report that the defaults were kept for want of evidence, so the
  user knows to revisit them.

The dependency steps in `post-create.sh` are all guarded, so an empty target
builds cleanly — expect `Skipping Python dependencies (no pyproject.toml)` and
friends in the log rather than failures.

### 5. Bring the container up

Skip this whole step with `--no-up`, and say clearly that nothing was built.

```bash
cd "$TARGET"
devcontainer up --workspace-folder .
```

First build downloads the base image and runs `post-create.sh` — 3-8 minutes is
normal. It installs zsh plugins, Claude Code, Copilot CLI, the Playwright CLI
and Chromium, the bundled Claude config (Auto permission mode by default), the
Claude Code plugin roster, git recoverability settings, and then the project's
own dependencies (`uv sync`, `npm ci` in the frontend directory, pre-commit
hooks, `.env` from `.env.example`).

Failure handling:

- `Command failed: docker ps` → Colima is not running, or its disk is full.
  Step 1 covers both.
- A post-create step failed → the container is still usable. Report which step,
  and that the config can be re-applied in place with
  `bash .devcontainer/post-create.sh --config-only`.

Then confirm it before reporting success. `devcontainer up` can return
`{"outcome":"success"}` over a post-create step that failed, so read the log for
skipped or failed steps and check the container is actually up:

```bash
docker ps --format '{{.Names}}\t{{.Status}}'
```

Then open a shell:

```bash
devcontainer exec --workspace-folder . zsh
```

### 6. Report

Report in the reply — do not write a setup report file:

- Target directory, upstream commit installed
  (`git -C "$UPSTREAM" rev-parse --short HEAD`), and whether the directory was
  created and `git init`ed as part of this run
- Files copied, files skipped because they already existed
- Every tailoring edit made, with the evidence behind it — and, on a greenfield
  target, which defaults were kept for want of evidence
- Host state worth knowing: the Colima profile that was started and its specs if
  they differ from the recommended 8/16/150, plus any unrelated containers the
  VM brought back up
- Container status as verified by `docker ps`, or not built and why
- The first-run sign-ins still owed, inside the container:

  ```bash
  gh auth login
  az login          # only if the azure-cli feature was kept
  claude            # authenticates on first launch
  git config --global user.name "$(gh api user --jq .name)"
  git config --global user.email "$(gh api user --jq .email)"
  ```

- That `.devcontainer/` is left uncommitted for review. Do not commit or push
  it — that is the user's call.

Finally: `rm -rf "$UPSTREAM"`.

## Afterwards

- `/devcontainer-update` pulls later upstream changes into this project.
- `/plugins-update` moves the installed Claude Code plugins to their published
  versions.
- Claude Code runs in Auto permission mode by default
  (`permissions.defaultMode: "auto"` in the bundled settings.json); edit
  `~/.claude/settings.json` inside the container to change it.

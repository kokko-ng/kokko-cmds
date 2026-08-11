---
description: Refresh this project's devcontainer config from kokko-ng/kokko-devcontainer and apply it to the running container without a rebuild.
argument-hint: '[--check] [--ref <branch-or-tag>] [--all]'
allowed-tools: Bash(git:*), Bash(bash:*), Bash(diff:*), Bash(cp:*), Bash(mkdir:*), Bash(rm:*), Bash(ls:*), Bash(find:*), Bash(cat:*), Bash(jq:*), Read, Write, Edit
disable-model-invocation: true
---

# Update the Devcontainer Config

Pull the latest `.devcontainer/` from
[kokko-ng/kokko-devcontainer](https://github.com/kokko-ng/kokko-devcontainer)
into this project and apply everything that can take effect **without rebuilding
the container**. Run it from inside the devcontainer.

`$ARGUMENTS`:

| Flag | Effect |
| ---- | ------ |
| `--check` | Report the drift and stop. Change nothing. |
| `--ref <branch-or-tag>` | Compare against that ref instead of the default branch. |
| `--all` | Also offer the root-level docs (`README.md`, `INSTRUCTIONS.md`, `MANAGING.md`, `ghostty/`). Off by default — most projects have their own. |

## What this can and cannot do

Applied live by this command:

- `.devcontainer/config/claude/**` — `CLAUDE.md`, `settings.json` (permission
  mode and plugin roster), `merge-settings.jq`, `prune-roster.jq`
- `.devcontainer/config/zsh/**`
- Global git configuration
- The Claude Code plugin roster (marketplaces registered, enabled plugins
  installed)

**Needs a rebuild** — these only take effect at image build or container create
time, so the command updates the files and then tells you:

- `.devcontainer/Dockerfile`
- `.devcontainer/devcontainer.json` — `features`, `containerEnv`, `runArgs`,
  `mounts`, `forwardPorts`
- `.devcontainer/init-host-certs.sh` (runs on the **host** at `initializeCommand`)

Never claim a rebuild-only change is live. Report it in the rebuild list.

## Steps

### 1. Preflight

```bash
git rev-parse --show-toplevel
git status --short
ls -la .devcontainer/
ls /.dockerenv
```

`ls -la .devcontainer/` failing means the project has no `.devcontainer/`;
`ls /.dockerenv` succeeding means you are inside a container.

- Run from the repo root; use it for every path below.
- **Uncommitted changes under `.devcontainer/` → stop and ask.** This command
  overwrites those files. Do not stash, do not tidy — ask the user to commit
  first, per the git rules in `CLAUDE.md`.
- No `.devcontainer/` at all → this is a first-time install rather than an
  update. Say so and confirm before copying the whole starter in.
- Not inside a container → the file sync still works, but nothing can be applied
  live. Say so and offer `--check` instead.

### 2. Fetch upstream into a temp clone

The temp clone lives at `/tmp/kokko-devcontainer-upstream` — use that literal
path in every command below.

```bash
rm -rf /tmp/kokko-devcontainer-upstream
git clone --depth=1 https://github.com/kokko-ng/kokko-devcontainer /tmp/kokko-devcontainer-upstream
# with --ref: git clone --depth=1 --branch <ref> ...
git -C /tmp/kokko-devcontainer-upstream log -1 --format='%h %ad %s' --date=short
```

Clone failed (no network, private repo, bad ref) → report the actual error and
stop. Do not fall back to a cached copy.

### 3. Diff against the project

```bash
diff -ruq /tmp/kokko-devcontainer-upstream/.devcontainer .devcontainer
```

Then, for every file that differs, `diff -u` it to see the actual change.

Sort the differing files into three buckets:

1. **Upstream-only additions** — new files. Safe to copy.
2. **Changed, not customized here** — the local copy matches an older upstream
   version. Safe to copy.
3. **Changed and customized here** — the local file carries project-specific
   edits. `devcontainer.json` (name, `forwardPorts`, `PYTHONPATH`, mounts) and
   `post-create.sh` (frontend directory, extra setup) are the usual ones.

To tell bucket 2 from bucket 3, check whether the local edit exists in upstream
history:

```bash
git -C /tmp/kokko-devcontainer-upstream log --oneline -5 -- .devcontainer/<file>
```

If the local content is not any upstream version, it is a local customization.

### 4. Report the drift

Present a table before changing anything:

| File | Change | Bucket | Live or rebuild |
| ---- | ------ | ------ | --------------- |
| `config/claude/CLAUDE.md` | 1 section added | not customized | live |
| `devcontainer.json` | new `runArgs` entry | customized here | rebuild |

Then the upstream commits you are pulling in:

```bash
git -C /tmp/kokko-devcontainer-upstream log --oneline -20 -- .devcontainer
```

**Stop here if `--check`.**

If nothing differs, say the config is already current and stop — do not run the
refresh for the sake of it.

### 5. Apply the file updates

Buckets 1 and 2: copy straight over.

```bash
cp /tmp/kokko-devcontainer-upstream/.devcontainer/<path> .devcontainer/<path>
```

Bucket 3 (customized here): **never blind-copy.** For each file, show the diff,
say which hunks are upstream improvements and which are this project's
customizations, and merge by hand so the customizations survive. When a hunk is
genuinely ambiguous, present the options and a recommendation and let the user
pick.

Deleted upstream: report files that upstream removed. Do not delete them
without asking — a project may depend on one.

### 6. Refresh `~/.claude/CLAUDE.md`

`post-create.sh` deliberately will not overwrite an existing `~/.claude/CLAUDE.md`,
so a bundled-CLAUDE.md change reaches a running container only here.

```bash
diff -u "$HOME/.claude/CLAUDE.md" .devcontainer/config/claude/CLAUDE.md
```

- Identical → nothing to do.
- Differs only by the upstream additions → back up and copy:

  ```bash
  cp "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak"
  cp .devcontainer/config/claude/CLAUDE.md "$HOME/.claude/CLAUDE.md"
  ```

- Contains local edits → show them, and merge the upstream sections in rather
  than overwriting. Ask before discarding anything the user wrote.

### 7. Apply live

```bash
bash .devcontainer/post-create.sh --config-only
```

This re-merges the bundled settings and plugin roster into
`~/.claude/settings.json` (keeping the user's own settings and any plugin they
explicitly disabled), removes any leftovers of the retired git safety layer,
re-registers the marketplaces, installs any newly rostered plugin, re-applies
the git configuration, and relinks the zsh config. It is idempotent.

Older config without that flag → the script exits 2 on the unknown argument.
Say so and point at this repo's `post-create.sh`.

### 8. Report

Report in the reply — do not write an update report file:

- Files updated, files merged by hand, files skipped and why
- The upstream commit now matched (`git -C /tmp/kokko-devcontainer-upstream rev-parse --short HEAD`)
- **What is live now** versus **what needs a rebuild**, explicitly
- Plugin changes: run `/plugins-update` next if plugin versions also moved, and
  `/reload-plugins` to load them into this session
- The rebuild command, if anything in the rebuild bucket changed — printed
  for the user to run on the host, never run from here:

  ```text
  devcontainer up --workspace-folder . --remove-existing-container
  ```

Finally: `rm -rf /tmp/kokko-devcontainer-upstream`.

The `.devcontainer/` changes are left uncommitted in the working tree for review.
Do not commit or push them — that is the user's call.

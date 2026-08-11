---
description: Update Claude Code plugins to the latest marketplace versions, then prompt to run /reload-plugins.
argument-hint: '[--check] [--all] [<plugin@marketplace> ...]'
allowed-tools: Bash(claude plugin:*), Bash(claude plugins:*), Bash(jq:*), Bash(cat:*), Bash(ls:*), Read
disable-model-invocation: true
---

# Update Claude Code Plugins

Refresh every configured marketplace, bring the installed plugins up to the
versions those marketplaces now publish, install anything enabled but missing,
and hand back a before/after table.

`$ARGUMENTS`:

| Flag | Effect |
| ---- | ------ |
| _(none)_ | The `kokko-ng` marketplaces: `kokko-ng-kokko-cmds` and `kokko-ng-kokko-janitor`. |
| `--all` | Every configured marketplace, including third-party ones. |
| `--check` | Report what would change. Install and update nothing. |
| `<plugin@marketplace> ...` | Only these plugins. |

`claude plugin update` writes the new version to disk but does not load it into
the running session — that is why this command ends by asking you to run
`/reload-plugins`.

## Steps

### 1. Record the current state

```bash
claude plugin marketplace list --json
claude plugin list --json
```

Keep the `id` and `version` of every installed plugin. That is the "before"
column, and without it the final report cannot say what actually moved.

### 2. Register anything missing from the roster

The roster is `enabledPlugins` plus `extraKnownMarketplaces` in settings —
`~/.claude/settings.json`, or `.devcontainer/config/claude/settings.json` when
this project bundles a devcontainer.

```bash
jq -r '(.extraKnownMarketplaces // {}) | to_entries[]
       | select(.value.source.source == "github")
       | "\(.key) \(.value.source.repo)"' ~/.claude/settings.json
jq -r '(.enabledPlugins // {}) | to_entries[] | select(.value == true) | .key' ~/.claude/settings.json
```

An entry in `enabledPlugins` does **not** install anything — it only enables a
plugin that is already installed. Any rostered marketplace not in step 1's list
gets added; any rostered plugin missing from step 1's list gets installed:

```bash
claude plugin marketplace add <owner/repo>
claude plugin install <plugin@marketplace>
```

A plugin set to `false` in `enabledPlugins` is a deliberate opt-out. Leave it
alone, and say in the report that it was skipped for that reason.

### 3. Refresh the marketplaces

```bash
claude plugin marketplace update <name>      # per marketplace
claude plugin marketplace update             # or all of them, with --all
```

This re-pulls each marketplace's `marketplace.json` from GitHub. Skip it and
every version comparison below is against stale metadata.

### 4. Compare installed against published

The published version lives in the refreshed marketplace clone, whose path is
the `installLocation` from step 1:

```bash
jq -r '.plugins[] | "\(.name) \(.version)"' \
  <installLocation>/.claude-plugin/marketplace.json
```

Build the comparison:

| Plugin | Installed | Published | Action |
| ------ | --------- | --------- | ------ |
| `kokko-git@kokko-ng-kokko-cmds` | 3.0.1 | 3.1.0 | update |
| `kokko-janitor@kokko-ng-kokko-janitor` | 1.1.0 | 1.1.0 | current |
| `kokko-env@kokko-ng-kokko-cmds` | — | 3.1.0 | install (new) |

**Stop here if `--check`**, and report the table.

### 5. Apply

```bash
claude plugin update <plugin@marketplace>     # one call per outdated plugin
claude plugin install <plugin@marketplace>    # for rostered-but-missing plugins
```

Run one call per plugin so a single failure is attributable. If a call fails,
record the error against that plugin, keep going with the rest, and report the
failures — do not abort the run.

### 6. Verify

```bash
claude plugin list --json
```

Confirm each version actually moved. A plugin still on its old version after a
successful-looking `update` is a real finding: report it rather than assuming.

### 7. Report and prompt

Report in the reply — no report file. Give the before/after table, anything
newly installed, anything skipped (with the reason), and any failures.

Then end with exactly this, because the new versions are on disk but not in the
session:

> Plugins updated. Run **`/reload-plugins`** to load them into this session.

If a plugin ships hooks (`kokko-notifications`), note that hook
changes need a full Claude Code restart, not just a reload.

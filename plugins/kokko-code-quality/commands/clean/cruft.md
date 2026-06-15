---
description: Find and remove repository cruft not covered by .gitignore, with confirmation.
argument-hint: [dry-run|auto|gitignore-only|<pattern>]
allowed-tools: Bash, AskUserQuestion, Edit
---

# Remove Unnecessary Files

Find cruft files NOT already covered by `.gitignore` and remove them with
confirmation. Properly ignored files are excluded from results.

Modes via `$ARGUMENTS`: `dry-run` (report only), `auto` (remove untracked
cruft without asking; still confirm tracked files), `gitignore-only` (suggest
`.gitignore` additions, delete nothing), or a custom pattern (e.g. `*.bak`).

## 1. Scan (Excluding Gitignored)

Run the category searches in [cruft-patterns.md](./references/cruft-patterns.md).
Each pipes results through `git check-ignore -q "$f" || echo "$f"` to drop
ignored files. Categories: AI-generated reports, temp/dev files, stray logs,
test/coverage artifacts, orphaned drafts, and misplaced database files.

## 2. Collect Metadata

```bash
ls -lh "$file" | awk '{print $5}'                 # size
stat -c '%y' "$file" | cut -d' ' -f1              # last modified (Linux)
# macOS: stat -f '%Sm' -t '%Y-%m-%d' "$file"
git ls-files --error-unmatch "$file" 2>/dev/null && echo "tracked" || echo "untracked"
```

## 3. Present Results

Only show files not in `.gitignore`, split into tracked (shouldn't be) vs.
untracked (remove or ignore).

```text
## Cruft Scan Results
### Should Remove (untracked cruft)
| File | Size | Last Modified | Action |
| ./server.log | 16KB | 2024-01-10 | Delete or add to .gitignore |
### Should Not Be Tracked (committed cruft)
| File | Size | Last Modified | Action |
| ./VALIDATION_REPORT.md | 12KB | 2024-01-08 | git rm and add to .gitignore |
```

If nothing matches: "Repository is clean - no cruft found".

## 4. Confirm via AskUserQuestion

Offer: "Remove all and update .gitignore" / "Remove files only" / "Update
.gitignore only" / "Select individually" / "Skip".

## 5. Execute

```bash
rm -rf <file_or_dir>        # untracked
git rm -r <file_or_dir>     # tracked
```

## 6. Update .gitignore (if selected)

```bash
grep -q "pattern" .gitignore || echo "pattern" >> .gitignore
```

Suggest patterns from findings: `*_REPORT.md`, `*.log`, `.coverage`,
`htmlcov/`, `.DS_Store`, `*.db` (if unintentional).

## 7. Summary

Report files/dirs deleted (with sizes) and patterns added to `.gitignore`.

## Safety Rules

- NEVER remove files in src/, lib/, or other code directories without explicit confirmation.
- NEVER remove package.json, pyproject.toml, or config files.
- NEVER remove README.md, CLAUDE.md, or intentional documentation.
- NEVER remove files modified in the last hour (likely work in progress).
- Always show what will be removed BEFORE doing it.
- Require explicit confirmation for tracked files — they were committed for a reason.
- When in doubt, suggest adding to .gitignore rather than deleting.

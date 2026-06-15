# Cruft Patterns

Find patterns by category, then filter out gitignored results:

```bash
find ... | while read f; do git check-ignore -q "$f" || echo "$f"; done
```

## AI-Generated Reports

```bash
find . -type f \( \
  -name "VALIDATION_REPORT*.md" \
  -o -name "ANALYSIS_REPORT*.md" \
  -o -name "QUALITY_REPORT*.md" \
  -o -name "REVIEW_REPORT*.md" \
  -o -name "DEBT_REPORT*.md" \
  -o -name "COVERAGE_REPORT*.md" \
  -o -name "*_REPORT.md" \
  -o -name "report*.md" \
  -o -name "claude_*.md" \
  -o -name "ai_*.md" \
\) -not -path "./.git/*" -not -path "./tmp/*" 2>/dev/null \
| while read f; do git check-ignore -q "$f" || echo "$f"; done
```

## Temporary / Development Files

```bash
find . -type f \( \
  -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -o -name "*.backup" \
  -o -name "*.orig" -o -name "*.swp" -o -name "*.swo" -o -name "*~" \
  -o -name ".DS_Store" -o -name "Thumbs.db" -o -name "desktop.ini" \
\) -not -path "./.git/*" -not -path "./node_modules/*" \
  -not -path "./.venv/*" 2>/dev/null \
| while read f; do git check-ignore -q "$f" || echo "$f"; done
```

## Log Files Outside tmp

```bash
find . -type f \( \
  -name "*.log" -o -name "*.logs" \
  -o -name "debug*.txt" -o -name "error*.txt" \
\) -not -path "./.git/*" -not -path "./tmp/*" \
  -not -path "./logs/*" -not -path "./node_modules/*" \
  -not -path "./.venv/*" 2>/dev/null \
| while read f; do git check-ignore -q "$f" || echo "$f"; done
```

## Test / Coverage Artifacts Outside tmp

```bash
find . \( -type f -o -type d \) \( \
  -name "test_output*.json" -o -name "test_results*.xml" \
  -o -name "coverage*.xml" -o -name "junit*.xml" \
  -o -name ".coverage" -o -name "htmlcov" -o -name ".pytest_cache" \
\) -not -path "./.git/*" -not -path "./tmp/*" \
  -not -path "./node_modules/*" -not -path "./.venv/*" 2>/dev/null \
| while read f; do git check-ignore -q "$f" || echo "$f"; done
```

## Orphaned Config / Draft Files

```bash
find . -type f \( \
  -name "*.draft" -o -name "*.wip" \
  -o -name "scratch*.py" -o -name "scratch*.js" -o -name "scratch*.ts" \
  -o -name "test_scratch*" -o -name "temp_*" -o -name "tmp_*" \
\) -not -path "./.git/*" -not -path "./tmp/*" \
  -not -path "./node_modules/*" -not -path "./.venv/*" 2>/dev/null \
| while read f; do git check-ignore -q "$f" || echo "$f"; done
```

## Database Files in Unexpected Locations

```bash
find . -maxdepth 2 -type f \( \
  -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" \
\) -not -path "./.git/*" -not -path "./tmp/*" 2>/dev/null \
| while read f; do git check-ignore -q "$f" || echo "$f"; done
```

#!/usr/bin/env bash
# Stop hook: reminds Claude to fill the ADR REASON section when source code has changed
# without a corresponding docs/adr/ file being created or updated.

STAGED=$(git diff --name-only --cached 2>/dev/null)
UNSTAGED=$(git diff --name-only 2>/dev/null)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null)
ALL_CHANGED=$(printf '%s\n%s\n%s' "$STAGED" "$UNSTAGED" "$UNTRACKED")

HAS_SRC=$(echo "$ALL_CHANGED" | grep -cE "^src/|^pom\.xml|^\.github/" || true)
HAS_ADR=$(echo "$ALL_CHANGED" | grep -cE "^docs/adr/" || true)

if [ "$HAS_SRC" -gt 0 ] && [ "$HAS_ADR" -eq 0 ]; then
  echo "ADR REQUIRED: Source code was changed but no ADR exists in docs/adr/."
  echo ""
  echo "Before committing, create docs/adr/ADR-NNNN-title.md using docs/adr/template.md."
  echo "Start with the REASON section — fill it before writing any more code."
fi

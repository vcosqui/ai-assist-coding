#!/usr/bin/env bash
# PreToolUse hook: gates git commit on branch naming convention and a staged ADR.
# Receives tool input JSON on stdin.

INPUT=$(cat)
COMMAND=$(python3 -c "import sys,json; print(json.load(sys.stdin).get('command',''))" <<< "$INPUT" 2>/dev/null || echo "")

# Only inspect git commit commands
if ! echo "$COMMAND" | grep -qE "git commit"; then
  exit 0
fi

ERRORS=()

# 1. Branch must follow issue-{N}-{description}
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if ! echo "$BRANCH" | grep -qE "^issue-[0-9]+-[a-z0-9-]+$"; then
  ERRORS+=("Branch '$BRANCH' does not follow the required pattern: issue-{number}-{kebab-description}")
  ERRORS+=("  Create the correct branch: git checkout -b issue-42-your-description")
fi

# 2. Every commit that touches source must also stage an ADR
SRC_STAGED=$(git diff --name-only --cached 2>/dev/null | grep -cE "^src/|^pom\.xml|^\.github/" || true)
ADR_STAGED=$(git diff --name-only --cached 2>/dev/null | grep -cE "^docs/adr/" || true)

if [ "$SRC_STAGED" -gt 0 ] && [ "$ADR_STAGED" -eq 0 ]; then
  ERRORS+=("Commit includes $SRC_STAGED source file(s) but no ADR is staged.")
  ERRORS+=("  Create docs/adr/ADR-NNNN-title.md (start with the REASON section) and stage it.")
fi

if [ "${#ERRORS[@]}" -gt 0 ]; then
  echo "Commit blocked — workflow requirements not met:"
  echo ""
  for ERR in "${ERRORS[@]}"; do
    echo "  $ERR"
  done
  echo ""
  echo "See the Development Workflow section in CLAUDE.md."
  exit 2
fi

exit 0

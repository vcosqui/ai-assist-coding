#!/usr/bin/env bash
# Installs global Claude config and all skills to ~/.claude/
# Run from the repo root: ./scripts/install-global.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing global Claude config to $CLAUDE_DIR..."

# Global instruction files
cp "$REPO_ROOT/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
cp "$REPO_ROOT/global/agents-rules.md" "$CLAUDE_DIR/agents-rules.md"
cp "$REPO_ROOT/global/writing-rules.md" "$CLAUDE_DIR/writing-rules.md"
echo "  Copied global instruction files."

# Skills
mkdir -p "$CLAUDE_DIR/skills"
for skill_dir in "$REPO_ROOT/skills"/*/; do
  skill_name="$(basename "$skill_dir")"
  cp -r "$skill_dir" "$CLAUDE_DIR/skills/$skill_name"
  echo "  Installed skill: $skill_name"
done

echo ""
echo "Done. Skills available: $(ls "$CLAUDE_DIR/skills" | tr '\n' ' ')"
echo "Restart Claude Code to pick up new skills."

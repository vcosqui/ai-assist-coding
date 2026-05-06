#!/usr/bin/env bash
# Installs a hook group into the current project's .claude/hooks/
# and merges the required hooks config into .claude/settings.json.
#
# Usage (run from inside a project repo):
#   /path/to/ai-assist-coding/scripts/install-project.sh <hook-group>
#
# Example:
#   /path/to/ai-assist-coding/scripts/install-project.sh adr

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_GROUP="${1:-}"

if [ -z "$HOOK_GROUP" ]; then
  echo "Usage: install-project.sh <hook-group>"
  echo "Available hook groups: $(ls "$REPO_ROOT/hooks")"
  exit 1
fi

HOOK_SRC="$REPO_ROOT/hooks/$HOOK_GROUP"
if [ ! -d "$HOOK_SRC" ]; then
  echo "Hook group '$HOOK_GROUP' not found in $REPO_ROOT/hooks/"
  exit 1
fi

# Copy hook scripts
mkdir -p .claude/hooks
cp "$HOOK_SRC"/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
echo "Installed hooks from $HOOK_GROUP:"
ls .claude/hooks/

# Merge settings.json if a template exists for a known group
TEMPLATE_SETTINGS="$REPO_ROOT/project-templates"
case "$HOOK_GROUP" in
  adr)
    TEMPLATE="$TEMPLATE_SETTINGS/spring-boot-kotlin/.claude/settings.json"
    if [ ! -f .claude/settings.json ]; then
      cp "$TEMPLATE" .claude/settings.json
      echo "Created .claude/settings.json from template."
    else
      echo ""
      echo "WARNING: .claude/settings.json already exists. Merge the following hooks manually:"
      cat "$TEMPLATE"
    fi
    ;;
esac

echo ""
echo "Done. Hook group '$HOOK_GROUP' installed into .claude/hooks/."

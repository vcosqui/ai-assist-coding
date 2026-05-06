# Hooks

Reusable Claude Code hook scripts grouped by workflow.

## adr/

Enforces the ADR development workflow at the git level. Both hooks assume:
- Source files live under `src/`, `pom.xml`, or `.github/`
- ARDs live under `docs/adr/`
- Branches follow `issue-{number}-{kebab-description}`

| File | Event | Behavior |
|---|---|---|
| `check-adr-reminder.sh` | `Stop` | Prints a reminder if source changed but no ADR exists/was touched |
| `check-commit.sh` | `PreToolUse(Bash)` | Blocks `git commit` if branch name is wrong or no ADR is staged |

### Install

Run `scripts/install-project.sh adr` from the repo root, or manually:

```bash
mkdir -p .claude/hooks
cp hooks/adr/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

Then add to `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/check-adr-reminder.sh"}]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/check-commit.sh"}]
      }
    ]
  }
}
```

### Adapting to other source layouts

Edit the `grep -cE` patterns in both scripts to match your project:

- Maven/Gradle: `^src/|^pom\.xml|^build\.gradle`
- Node: `^src/|^lib/|^package\.json`
- Go: `^cmd/|^internal/|^pkg/|^go\.mod`

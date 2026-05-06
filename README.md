# ai-assist-coding

A personal library of Claude Code skills, hooks, and global configuration — designed to be shared across projects.

## Structure

```
ai-assist-coding/
├── global/                    # Global Claude config (~/.claude/)
│   ├── CLAUDE.md              # Top-level instruction file
│   ├── agents-rules.md        # Coding agent rules (Anbeeld/AGENTS.md)
│   └── writing-rules.md       # Writing rules (Anbeeld/WRITING.md)
│
├── skills/                    # Installable Claude Code skills
│   ├── reasons-canvas/        # REASONS planning canvas
│   └── adr-workflow/          # Issue-first ADR + ATDD development workflow
│
├── hooks/                     # Reusable Claude Code hook scripts
│   └── adr/                   # Hooks that enforce the ADR workflow
│
├── project-templates/         # Per-stack CLAUDE.md + .claude/ starters
│   └── spring-boot-kotlin/
│
└── scripts/                   # Install and sync helpers
```

## Install

### Global config

Copies global instructions and all skills to `~/.claude/`:

```bash
./scripts/install-global.sh
```

### Project hooks (ADR workflow)

Run from inside a project repo to install the ADR enforcement hooks:

```bash
/path/to/ai-assist-coding/scripts/install-project.sh adr
```

### Skills only

To install a single skill globally:

```bash
cp -r skills/adr-workflow ~/.claude/skills/
```

## Skills

| Skill | Trigger | What it does |
|---|---|---|
| `reasons-canvas` | `/reasons-canvas` | Walks through the REASONS planning canvas before any code |
| `adr-workflow` | `/adr-workflow` | Full issue-first workflow: issue → ADR → branch → explore → plan → ATDD → implement → commit |

## Hooks

| Hook | Event | What it enforces |
|---|---|---|
| `adr/check-adr-reminder.sh` | `Stop` | Reminds Claude to create an ADR when source changed but no ADR exists |
| `adr/check-commit.sh` | `PreToolUse(Bash)` | Blocks `git commit` unless branch follows `issue-{N}-{desc}` and an ADR is staged |

## Project templates

`project-templates/spring-boot-kotlin/` is a CLAUDE.md starter for Spring Boot + Kotlin projects following hexagonal architecture. Copy it into a new repo and fill in the project-specific sections.

## Credits

- `global/agents-rules.md` — [Anbeeld/AGENTS.md](https://github.com/Anbeeld/AGENTS.md)
- `global/writing-rules.md` — [Anbeeld/WRITING.md](https://github.com/Anbeeld/WRITING.md)
- Skill format inspired by [LukasNiessen/kubernetes-skill](https://github.com/LukasNiessen/kubernetes-skill)

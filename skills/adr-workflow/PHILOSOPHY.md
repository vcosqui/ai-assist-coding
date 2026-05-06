# ADR Workflow — Philosophy

## The core problem this solves

Diffs capture what changed. Commit messages capture what was done. Neither captures why — why this problem now, why this approach, what was ruled out, what the cost of inaction was. That context evaporates within days of a change landing.

An ADR (Architectural Reasoning Document) is a one-page record of the reasoning. It is not a design doc and not a post-mortem. It is a structured capture of intent written at the moment intent is clearest: before implementation starts.

## Why REASON before code

Most documentation debt happens because developers write docs after the fact, from memory, compressing nuance they no longer hold. The REASON section must be written before opening any source file because:

1. It forces explicit problem framing — you often discover the real problem is different from the stated one.
2. It is the only moment the full decision space is visible. Once you start coding, you become invested in one path.
3. It is the only artifact that cannot be reconstructed from the diff later.

If you cannot fill in the REASON section clearly, the work is not ready to start.

## Why issue-first

Every change should be traceable to a user-visible problem or explicit decision. "Issue-first" enforces this at the start of every session, not as a retrospective tag. The branch naming convention (`issue-{N}-{desc}`) makes the traceability machine-readable and allows hooks to enforce it automatically.

## Why ATDD

Tests written before implementation describe behavior from the caller's perspective, not the implementer's. Black-box acceptance tests at the outermost integration boundary:

- Prevent tests that verify implementation details (which break on refactors)
- Force a clear definition of "done" before work starts
- Catch integration failures that unit tests miss by design

Seeing a test fail first is not ceremony. It confirms the test actually exercises the behavior and that the behavior does not yet exist.

## Token efficiency

The SKILL.md uses conditional reference loading — it only points to `references/adr-template.md` when relevant, rather than inlining all reference material. This keeps the context window clean for projects that use the adr-workflow skill without running the full eight-step sequence each session.

## Enforcement vs. guidance

The skill provides guidance. The hooks (`hooks/adr/`) provide enforcement. The combination means:

- Claude follows the workflow because it understands the reasoning (skill)
- Claude cannot accidentally commit without an ADR because the hook blocks it (enforcement)

Neither alone is sufficient. Guidance without enforcement drifts. Enforcement without guidance produces workarounds.

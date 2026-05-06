---
name: adr-workflow
description: Issue-first development workflow with mandatory ADR documentation. Use when starting any feature, fix, or non-functional change. Enforces: issue reference → ADR REASON before code → branch → explore → plan → ATDD → implement → complete ADR → commit.
argument-hint: "[brief description of what to build or fix]"
---

# ADR Workflow

Full context for this task: $ARGUMENTS

Follow these steps in strict order. Never skip, reorder, or parallelize steps unless explicitly noted.

---

## Step 1 — Issue reference

Before any other action, confirm a GitHub issue number. If one was not provided, ask:

> "Which GitHub issue does this work address? (e.g., #42)"

Never start work without a traceable issue. If no issue exists yet, offer to create one with `gh issue create`.

---

## Step 2 — ADR: REASON section first

Create `docs/adr/ADR-NNNN-{kebab-title}.md` using the template at `references/adr-template.md`.

Fill in **only the REASON section** before opening any source file:

- **Problem being solved** — observable symptom or unmet need, not the solution
- **Why now** — what triggered this work at this moment
- **Cost of not doing this** — concrete consequence if never done
- **Why this approach over alternatives** — at least one alternative ruled out and why

This is the only information that cannot be reconstructed from the diff later. If you cannot fill it in clearly, stop and ask the user to clarify before proceeding.

---

## Step 3 — Branch

Create a branch following `issue-{number}-{kebab-description}`. Never work on `main` or `master`.

```bash
git checkout -b issue-42-add-employee-endpoint
```

---

## Step 4 — Explore

Use the Explore subagent to understand the relevant code paths. Gather evidence before forming conclusions. Do not suggest solutions yet.

---

## Step 5 — Plan

Use the Plan subagent to design the solution. Present the plan to the user and wait for explicit approval before writing any production code.

---

## Step 6 — ATDD (tests before implementation)

Write a failing acceptance test first. Tests must be black-box — use the outermost integration layer available in the project (e.g., full HTTP round-trip, CLI entry point, or public API surface).

1. Write the test expressing the new behavior.
2. Run it and confirm it **fails**.
3. Implement the minimum code to make it pass.
4. Re-run and confirm it **passes**.

Do not write implementation code before seeing a red test.

---

## Step 7 — Complete the ADR

After the change is implemented and tests pass, return to the ADR and fill in:

- **Change** — which layers were touched, which contracts were altered, which invariants preserved
- **Consequences** — trade-offs accepted, new risks introduced (and mitigations), follow-up work, metrics to watch

---

## Step 8 — Commit

Stage the ADR together with the source changes. The commit message must reference the issue number.

```bash
git add src/ docs/adr/ADR-NNNN-title.md
git commit -m "issue #42: ..."
```

Non-functional changes (CI, deps, refactors, config) require ARDs too.

---

## Conditional references

Load these only when relevant:

- `references/adr-template.md` — blank ADR to copy for Step 2

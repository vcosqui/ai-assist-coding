---
name: reasons-canvas
description: Fill out and apply the REASONS Canvas before implementing a coding task. Use when the user invokes /reasons-canvas or asks to plan a coding task with the REASONS framework.
argument-hint: "[task description]"
---

Help the user fill out a REASONS Canvas for the following task: $ARGUMENTS

Work through each section interactively. For each section, propose a draft based on what you know about the task and the codebase, then ask the user to confirm or adjust before moving on. Do not write any code until the full canvas is approved.

---

## R — Requirements
What problem is being solved? What does "done" look like?
Include acceptance criteria and expected outcomes.

## E — Entities
What domain objects are involved?
List key data structures, models, or types and how they relate.

## A — Approach
What strategy or design direction will be used?
Explain the chosen solution and why.

## S — Structure
Where does this fit in the codebase?
Name the files, modules, components, or layers being touched.

## O — Operations
Concrete implementation steps, precise enough to act on.
Include method signatures, parameter types, and execution order if helpful.

## N — Norms
Engineering standards that apply here.
E.g. naming conventions, error handling style, logging, test coverage expectations.

## S — Safeguards
Non-negotiable constraints.
E.g. must not break X, must stay under Y ms, security rules, architectural boundaries.

---

Once the canvas is fully approved, proceed with implementation following it exactly.
If reality diverges from the canvas during implementation, stop and update the canvas first.

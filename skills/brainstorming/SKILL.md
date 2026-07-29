---
name: brainstorming
description: Use when a feature, product behavior, or technical direction is meaningfully ambiguous, has multiple viable approaches, or the user explicitly asks to explore ideas before implementation.
---

# Brainstorming

Clarify consequential uncertainty before implementation without turning every
change into a design ceremony.

## Triage

Use this workflow only when at least one decision would materially change scope,
behavior, architecture, or user experience. If the request is already concrete
and locally scoped, exit this workflow silently and return to the task.

## Workflow

1. Inspect the relevant project context before asking the user to repeat known facts.
2. Identify the smallest unresolved decision that blocks a sound implementation.
3. Ask one focused question at a time. Prefer concrete choices when they clarify trade-offs.
4. When enough context exists, present two or three viable approaches with costs and benefits.
5. Lead with a recommendation and explain why it best matches the stated constraints.
6. Summarize the agreed design at a level proportional to the risk and ask for approval.
7. Write a design document only when the user requests one or repository rules require it.

Cover only relevant dimensions: boundaries, data flow, failure behavior, user
experience, migration, and verification. Do not add sections merely to satisfy a template.

## Boundaries

- Do not modify code while a material design decision is still awaiting approval.
- Do not block trivial, explicit, or purely mechanical changes behind a design gate.
- Do not invoke planning, TDD, review, or implementation skills automatically.
- Do not commit a design document unless the user explicitly asks for a commit.
- End after the approved design or hand control back to the original task.

---
name: implementation-at-bat
description: Use whenever work enters an implementation phase with approved or already-clear boundaries and an eligible player is available.
---

# Implementation At Bat

Delegate every implementation phase to an eligible player regardless of size. The
manager retains goals, constraints, routing, integration, acceptance
verification, official decisions, scoring, and user communication.

## Scope

Use this workflow when implementation actually exists and its boundaries are
clear. It does not require creating a design or review phase. If material
product or architecture decisions remain, stop implementation and return them
for routing.

For each implementation task:

1. Define the exact outcome, owned files or module, constraints, and focused verification.
2. Prepare a plate-appearance brief using `references/implementer-prompt.md`.
3. Put one player at bat. Tell it that it is not alone in the codebase and must
   preserve and accommodate other changes.
4. Let the implementer inspect, edit, and run focused tests within its ownership.
5. Confirm only that returned files and evidence are present. Do not create a
   review phase automatically. If review is requested or separately determined
   necessary, route diff judgment to that review appearance.
6. Resolve cross-task conflicts and run combined verification in the primary agent.

Dispatch implementation tasks sequentially by default. Run them concurrently
only when the user explicitly requests parallel execution and
`parallel-lineup` independently applies. A single bounded
implementation task still requires one player appearance.

## Boundaries

- Do not delegate unresolved architecture or user decisions to an implementer.
- Do not give two implementers overlapping file ownership.
- Do not create worktrees automatically.
- Do not treat an implementer's self-test as proof that the integrated result works.
- Do not automatically commit or push implementer changes.
- If no eligible player is available in the harness, report the limitation
  instead of silently replacing the appearance with manager implementation.

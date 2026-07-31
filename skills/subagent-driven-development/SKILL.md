---
name: subagent-driven-development
description: Use when an approved or already-clear implementation contains multiple bounded coding tasks that benefit from focused implementation ownership and subagents are available.
---

# Player-driven Implementation

Delegate implementation plate appearances only. The manager retains architecture,
integration, verification, and user communication.

## Scope

Use this workflow when task boundaries are already clear. If material product or
architecture decisions remain, resolve them first without automatically invoking
another skill.

For each implementation task:

1. Define the exact outcome, owned files or module, constraints, and focused verification.
2. Prepare a plate-appearance brief using `references/implementer-prompt.md`.
3. Put one player at bat. Tell it that it is not alone in the codebase and must
   preserve and accommodate other changes.
4. Let the implementer inspect, edit, and run focused tests within its ownership.
5. Inspect the returned changes and evidence before scoring or integrating the result.
6. Resolve cross-task conflicts and run combined verification in the primary agent.

Dispatch implementation tasks sequentially by default. Run them concurrently
only when the user explicitly requests parallel execution and
`dispatching-parallel-agents` independently applies.

## Boundaries

- Do not delegate unresolved architecture or user decisions to an implementer.
- Do not give two implementers overlapping file ownership.
- Do not create worktrees automatically.
- Do not treat an implementer's self-test as proof that the integrated result works.
- Do not automatically commit or push implementer changes.

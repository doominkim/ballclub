---
name: using-superpowers-lite
description: Requires checking and invoking potentially relevant Superpowers Lite skills without imposing a bundled methodology. Use at the start of any conversation and before any response or action when there is even a 1% chance an installed skill applies.
---

# Using Superpowers Lite

Superpowers Lite provides composable development skills. Skill discovery is
strict, while the methodology selected after discovery remains narrow.

## Selection rules

1. Follow direct user instructions and repository rules first.
2. Before any response or action, consider the available skill descriptions.
3. If there is even a 1% chance a skill applies, invoke it before proceeding.
4. Invoke every potentially relevant skill; do not substitute memory for its current content.
5. Treat invocation as loading one skill's instructions, not enabling a methodology bundle.
6. Apply TDD, design, planning, worktrees, or review only when its own skill independently applies.
7. Do not create an automatic chain between skills unless the user explicitly requests one.

## Platform adaptation

Read only the reference for the active harness when tool translation is needed:

- Codex: `references/codex-tools.md`
- Claude Code: use its native skills, hooks, and tool names.

If a harness lacks a requested capability, use a safe inline alternative or
state the limitation. Do not invent unavailable tools.

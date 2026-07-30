---
name: capacity-routing
description: Use when a substantial task may be delegated and Codex must decide whether to keep it in the main thread or select the least-sufficient available capacity profile. Trigger for model or effort selection, Batter or Bench selection, or a request that needs context-isolated design, implementation, investigation, or review work. Do not use for short questions, status checks, trivial edits, or when the user already selected a profile.
---

# Capacity Routing

Choose capacity independently from the work phase. Design, implementation,
investigation, and review are assignments in a handoff, not agent identities.

## Route

1. Decide `MAIN` first. Keep work in the main thread when it is small, tightly
   coupled to live conversation, or does not justify handoff overhead.
2. Inventory only the capacity profiles exposed by the current harness. Do not
   invent model names, effort levels, or profile aliases.
3. Assess: ambiguity, change breadth, reversibility, security/financial/regulatory
   impact, failure cost, and repetition. Treat high-impact flags as overrides;
   do not average them away.
4. Choose the least sufficient profile. Prefer lower capacity for known,
   reversible work. Raise capacity for material uncertainty, blast radius, or
   costly failure. Prefer a lower-cost parallel profile for clear repetitive
   work when the current catalog provides one.
5. State the route before delegation:

   ```text
   ROUTE: MAIN | <profile>
   REASON: <one concrete sentence>
   PHASE: design | implementation | investigation | review
   ```

6. If delegating, include the phase, owned outcome, relevant constraints,
   completion criteria, and focused verification in the handoff. Keep final
   synthesis and user communication in the main thread.

## Escalation

If the selected profile discovers a missing decision, a larger blast radius, or
a high-impact risk, stop the affected work and report the evidence to the main
thread for rerouting. Do not silently upgrade or expand scope.

## Boundaries

- A user-selected profile wins.
- Do not implement routing as a global hook or force it on every message.
- Do not make a profile name imply a specialty or require a separate reviewer,
  planner, or implementer role.
- Do not delegate merely because a task contains the words design, implement,
  or review.

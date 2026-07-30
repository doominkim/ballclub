---
name: capacity-routing
description: Use when the Ballclub manager must keep a substantial task in the dugout or build a lineup from eligible, least-sufficient capacity profiles. Trigger for model or effort selection, player-class selection, or context-isolated design, implementation, investigation, or review work. Do not use for short questions, status checks, trivial edits, or a user-selected player.
---

# Building the Lineup

Choose capacity independently from the work phase. Design, implementation,
investigation, and review are assignments in a handoff, not agent identities.

## Set the lineup

1. Decide `MAIN` first. Keep work in the main thread when it is small, tightly
   coupled to live conversation, or does not justify handoff overhead.
   For a substantive retained task, announce `LINEUP: MANAGER` so the direct
   manager appearance can be distinguished from routine conversation.
2. Inventory only the capacity profiles exposed by the current harness. Do not
   invent model names, effort levels, or profile aliases.
3. Classify the required work boundary before comparing effort: full operation,
   bounded execution, support-only analysis, or independent coaching. Respect
   each profile's declared tools, allowed work, and mutation authority. A
   higher-effort profile in another class is not an upgrade if it lacks the
   required capability.
4. Assess eligible profiles for ambiguity, change breadth, reversibility,
   security/financial/regulatory impact, failure cost, and repetition. Treat
   high-impact flags as overrides; do not average them away.
5. Choose the least sufficient profile within the eligible class. Prefer lower
   effort for known, reversible work. Raise effort for material uncertainty,
   blast radius, or costly failure. Prefer a lower-cost parallel profile for
   clear repetitive work when the catalog provides one.
6. Announce the lineup decision before delegation:

   ```text
   LINEUP: MANAGER | <player-profile>
   REASON: <one concrete sentence>
   PHASE: design | implementation | investigation | review
   ```

7. If delegating, define one plate appearance: phase, player, owned outcome,
   relevant constraints, completion criteria, and focused verification. Keep
   official scoring, final synthesis, and user communication with the manager.

## Escalation

If the selected player discovers a missing decision, a larger blast radius, or
a high-impact risk, stop the affected work and report the evidence to the main
thread for rerouting. Do not silently upgrade or expand scope.

When a player believes user judgment is needed for policy, scope, cost,
irreversibility, or an external commitment, have it return a decision packet:
the decision, options, recommendation, evidence, and why it cannot proceed.
Before asking the user, the main may route that packet to an eligible
independent coach. The coach checks whether existing context resolves it or
whether the question can be narrowed. The coach advises; it does not mutate
files, make the final decision, or become a mandatory hook for trivial gaps.

## Boundaries

- A user-selected player wins.
- Do not implement routing as a global hook or force it on every message.
- Do not make a profile name imply a specialty or require a separate reviewer,
  planner, or implementer role.
- Do not delegate merely because a task contains the words design, implement,
  or review.

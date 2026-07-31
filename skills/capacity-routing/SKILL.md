---
name: capacity-routing
description: Use when the Ballclub manager must keep a substantial task in the dugout or build a lineup from eligible, least-sufficient capacity profiles. Trigger for model or effort selection, player-class selection, or context-isolated design, implementation, investigation, or review work. Do not use for short questions, status checks, trivial edits, or a user-selected player.
---

# Building the Lineup

Design, implementation, investigation, and review are assignments, not agent
identities.

## Set the lineup

1. Decide `MAIN` first. Keep work in the main thread when it is small, tightly
   coupled to live conversation, or does not justify handoff overhead.
   For a substantive retained task, announce `LINEUP: MANAGER` so the direct
   manager appearance can be distinguished from routine conversation.
2. Use only profiles exposed by the current harness. Do not invent aliases.
3. Classify the required work boundary before comparing effort: full operation,
   bounded execution, support-only analysis, or independent coaching. Respect
   each profile's tools and mutation authority. Another class is not an upgrade.
   Use Setter when unresolved design, interface, scope, or
   policy decisions are materially likely. Use Batter only when those decisions,
   mutation boundaries, contracts, and completion criteria are already fixed.
4. Assess ambiguity, breadth, reversibility, security/financial/regulatory
   impact, failure cost, and repetition. High-impact flags override averages.
5. Consult comparable verified scorebook history after fixing the eligible
   class. Repeated errors or confirmed rework favor higher effort or MAIN;
   repeated hits without errors favor the least-sufficient lower effort. Ignore
   unscored or incomparable appearances, never let history relax an authority
   gate, and use the static risk rules when evidence is sparse.
6. Choose the least sufficient eligible profile. Prefer lower effort for known,
   reversible work; raise it for uncertainty, blast radius, or costly failure.
   Parallelism is a dispatch decision, not a profile property.
7. Announce the lineup decision before delegation:

   ```text
   LINEUP: MANAGER | <player-profile>
   REASON: <one concrete sentence>
   PHASE: design | implementation | investigation | review
   ```

8. Define one appearance: phase, player, outcome, constraints, completion
   criteria, and focused verification. Keep
   official scoring, final synthesis, and user communication with the manager.

## Escalation

If the selected player discovers a missing decision, a larger blast radius, or
a high-impact risk, stop the affected work and report the evidence to the main
thread for rerouting. Do not silently upgrade or expand scope.

For user-owned policy, scope, cost, irreversibility, or external commitments,
return a decision packet with options, recommendation, evidence, and blocker.
Before asking, the main may ask an eligible coach whether context resolves or
narrows it. The coach advises but never mutates or decides.

## Boundaries

- A user-selected player wins.
- Do not implement routing as a global hook or force it on every message.
- Do not delegate merely because a task contains the words design, implement,
  or review.

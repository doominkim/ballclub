---
name: set-lineup
description: Use when the Ballclub manager must build a lineup from eligible, least-sufficient capacity profiles. Trigger for model or effort selection, player-class selection, or actual design, implementation, investigation, or review work. Do not use for short questions, status checks, or a user-selected player.
---

# Set Lineup

Design, implementation, investigation, and review are assignments, not agent
identities.

## Set the lineup

1. Identify the phase that actually exists. Do not infer a phase from a verb in
   the request or create missing phases to force a methodology chain.
   Conversation, status, routing, integration, and acceptance verification
   stay with the manager.
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
6. Choose the least sufficient eligible profile. Every design, implementation,
   or review phase requires a player appearance regardless of size. Prefer lower
   effort for known, reversible work; raise it for uncertainty, blast radius,
   or costly failure.
   Parallelism is a dispatch decision, not a profile property.
7. Track lineup decisions internally. Stay silent while the same player
   continues, including follow-ups and retries. When the called player/profile
   composition actually changes, announce once in Korean:

   `선수교체: <profile or lineup> — <short reason>`

   Manager-owned integration, verification, scoring, commit, or push is not a
   player change and gets no announcement.

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
- If the harness cannot provide an eligible player, state that limitation; do
  not silently substitute a manager appearance or invent a profile.
- Do not implement routing as a global hook or force it on every message.
- Phase-call requirements do not make parallel execution mandatory.

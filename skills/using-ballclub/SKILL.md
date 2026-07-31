---
name: using-ballclub
description: Use at session start or when forming a Ballclub lineup, calling a player, or interpreting an appearance.
---

# Using Ballclub

Ballclub is a baseball-native multi-agent harness. The main agent is the
manager, executable capacity profiles are players, and Coach profiles are
external advisers. Each completed subagent turn is one player plate appearance.
A retained manager execution outside required phases is one manager plate
appearance.

## Club rules

1. Follow user instructions and repository rules first.
2. Before Ballclub routing, delegation, scoring, or appearance interpretation,
   invoke every installed Ballclub skill with even a 1% chance of applying.
   For unrelated work, use the host's normal skill discovery instead of making
   Ballclub a global trigger.
3. Loading a skill does not activate unrelated methodologies.
4. Do not manufacture a design, implementation, or review phase. When work
   actually enters one, send an eligible player regardless of phase size.
   Conversation, status, routing, integration, and acceptance verification are
   not phase appearances.
5. Select players by allowed operation boundary first and least-sufficient
   effort second. A high-effort player in the wrong class is ineligible.
6. Give every player a plate appearance with an owned outcome, constraints,
   completion criteria, and focused verification.
7. Manager verification is limited to rerunning or confirming predeclared
   acceptance checks. Correctness, regression, security, design tradeoff, code
   quality, and diff judgment are review work and require an eligible player.
   A response or transcript alone is not a hit; score promptly when acceptance
   evidence exists, otherwise leave the appearance unscored.
8. The manager owns goals, constraints, routing, synthesis, integration,
   official decisions, acceptance verification, scoring, user communication,
   and the next lineup adjustment. It does not replace a required player's
   phase output.
9. Record a manager appearance only for execution outside required phases. Do
   not count routine routing, integration, status, or conversation as manager
   appearances.
10. Design, implementation, review, planning, and worktrees are phases or
    workflows, not player identities. Do not invent role profiles from them.
11. When review is independent and Coach is available, dispatch an eligible
    player assigned the review and Coach in parallel. Omit Coach only when it is
    unavailable or the reviews are not independent. Coach remains advisory.
12. Keep routing internal while the same lineup continues, including follow-ups
    and retries. Only when the called player/profile composition actually
    changes, announce once in Korean:
    `선수교체: <profile or lineup> — <short reason>`. Manager-owned integration,
    verification, scoring, commit, or push is not a player change; never
    announce `라우팅: MAIN`, `LINEUP: MANAGER`, or a manager return.

## Scorebook

- `hit`: completion criteria passed focused verification.
- `walk`: the player correctly stopped and escalated instead of guessing.
- `out`: the result failed or remained incomplete without sound escalation.
- `error`: the player claimed completion and caused confirmed rework.
- `home run`: a predeclared high-impact appearance became a verified hit
  without rework.

Use harness-native tools only. If the active harness cannot provide a required
player, preserve the user's explicit player choice where possible and state the
limitation instead of inventing a call.

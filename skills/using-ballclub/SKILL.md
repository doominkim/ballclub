---
name: using-ballclub
description: Establishes Ballclub's baseball-native multi-agent model and requires checking potentially relevant skills before responding or acting. Use at session start and whenever an agent must form a lineup, send a player to bat, or interpret an appearance.
---

# Using Ballclub

Ballclub is a baseball-native multi-agent harness. The main agent is the
manager, executable capacity profiles are players, Coach profiles are external
advisers, and each completed subagent turn is one plate appearance.

## Club rules

1. Follow user instructions and repository rules first.
2. Before responding or acting, invoke every installed skill with even a 1%
   chance of applying.
3. Loading a skill does not activate unrelated methodologies.
4. Keep small, tightly coupled work with the manager. Build a lineup only when
   delegation protects context or provides meaningful independent capacity.
5. Select players by allowed operation boundary first and least-sufficient
   effort second. A high-effort player in the wrong class is ineligible.
6. Give every player a plate appearance with an owned outcome, constraints,
   completion criteria, and focused verification.
7. A returned response is not automatically a hit. Official scoring requires
   verification evidence. Ambiguous appearances stay unscored.
8. The manager owns synthesis, official decisions, user communication, and the
   next lineup adjustment.

## Scorebook

- `hit`: completion criteria passed focused verification.
- `walk`: the player correctly stopped and escalated instead of guessing.
- `out`: the result failed or remained incomplete without sound escalation.
- `error`: the player claimed completion and caused confirmed rework.
- `home run`: a predeclared high-impact appearance became a verified hit
  without rework.

Use harness-native tools only. If the active harness cannot provide a required
player, hook, or verification surface, state the limitation instead of
inventing one.

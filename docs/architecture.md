# Architecture

Ballclub separates its baseball operating model from harness delivery.

## Core loop

1. The manager keeps small or conversation-coupled work in the main thread.
2. For substantial delegation, `capacity-routing` classifies the required
   operation boundary and builds an eligible, least-sufficient lineup.
3. A dispatch skill creates one or more bounded plate appearances with owned
   outcomes, constraints, completion criteria, and focused verification.
4. `SubagentStop` records player and Coach appearances without blocking return.
5. The manager inspects evidence and applies the official score. Returned text
   alone is not enough for a hit.
6. `scorecard` aggregates daily, weekly, and monthly scorecards. Coach tokens
   remain outside player salary and efficiency calculations.

```text
game state -> lineup -> plate appearance -> record -> verify -> score -> report
```

Runtime events and reports live under `~/.codex/ballclub` unless
`BALLCLUB_DATA` overrides the data root.

## Delivery layers

- `skills/`: harness-neutral decisions and operating rules
- `hooks/`: session bootstrap, update notices, and appearance collection
- `scripts/`: deterministic collection, scoring, reporting, and updates
- manifests: Codex and Claude Code plugin discovery
- tests: structure, lifecycle, and scorebook contract verification

The session bootstrap activates `using-ballclub`. It still requires strict
skill discovery, but invoking a skill does not activate unrelated methodology.

## Skill catalog

- `using-ballclub`: manager, player, Coach, appearance, and scorebook rules
- `capacity-routing`: lineup construction within allowed operation boundaries
- `dispatching-parallel-agents`: independent or context-isolated batting order
- `subagent-driven-development`: bounded implementation appearances
- `scorecard`: official score review and period reports
- `brainstorming`, `systematic-debugging`, `verification-before-completion`,
  `finishing-a-development-branch`, `writing-skills`: independently triggered
  development workflows

## Scoring boundary

Collection and scoring are deliberately separate. The hook writes an unscored
appearance. Only evidence-backed review may turn it into a hit, walk, out, or
error. A home run is a verified hit whose high-impact status was declared
before the appearance and which required no rework.

## Lifecycle

At startup, Ballclub injects the bootstrap and performs a non-blocking version
check. Updates require explicit approval and delegate to the active harness
package manager. Hooks never mutate the installed plugin directory directly.

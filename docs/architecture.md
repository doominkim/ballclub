# Architecture

Ballclub separates its baseball operating model from harness delivery.

## Core loop

1. The manager keeps small or conversation-coupled work in the main thread.
   Substantive manager-only execution becomes a manager appearance.
2. For substantial delegation, `capacity-routing` classifies the required
   operation boundary and builds an eligible, least-sufficient lineup.
3. A dispatch skill creates one or more bounded plate appearances with owned
   outcomes, constraints, completion criteria, and focused verification.
4. `SubagentStop` records player and Coach appearances, while `Stop` records
   substantive manager-only appearances without double-counting delegated turns.
5. The manager independently verifies the result and applies the official
   score. Returned text or transcript content alone is not enough for a hit.
6. `score` aggregates daily, weekly, and monthly scorecards. Comparable verified
   history adjusts effort only inside the already-eligible class; sparse or
   unscored data leaves the static routing rules unchanged.

```text
game state -> lineup -> plate appearance -> record -> verify -> score -> report
```

Runtime events and reports live under `~/.codex/ballclub` for Codex and
`~/.claude/ballclub` for Claude Code unless `BALLCLUB_DATA` overrides the root.
Legacy mixed data is preserved in place rather than migrated automatically.

## Delivery layers

- `skills/`: harness-neutral decisions and operating rules
- `hooks/`: session bootstrap, update notices, and behavior-neutral appearance dispatch
- `scripts/`: harness adapters plus deterministic collection, scoring, reporting, and updates
- `agents/codex/`, `rosters/claude/`: distributable custom-agent model and effort definitions
- manifests: Codex and Claude Code plugin discovery
- tests: structure, lifecycle, and scorebook contract verification

Claude Code plugin agents support `tools` and `disallowedTools`, but not
`permissionMode`. Bench and Coach boundaries therefore use the supported tool
fields plus explicit operating instructions. A Coach needs `Bash` to invoke the
external provider, so its read-only contract is behavioral rather than an OS
sandbox guarantee. Setup keeps identity-compatible custom instructions while
reporting supported security-field drift separately instead of overwriting it.

The session bootstrap activates `using-ballclub`. It still requires strict
skill discovery, but invoking a skill does not activate unrelated methodology.

## Skill catalog

- `using-ballclub`: manager, player, Coach, appearance, and scorebook rules
- `capacity-routing`: lineup construction within allowed operation boundaries
- `dispatching-parallel-agents`: independent or context-isolated batting order
- `subagent-driven-development`: bounded implementation appearances
- `score`: official score review and period reports
- `setup-ballclub`: explicit roster inspection, conflict repair, and custom-profile recovery
- `brainstorming`, `systematic-debugging`, `verification-before-completion`,
  `finishing-a-development-branch`, `writing-skills`: independently triggered
  development workflows

## Scoring boundary

Collection and scoring are deliberately separate. The hook writes an unscored
appearance. Only manager-owned focused verification may turn it into a hit,
walk, out, or error; transcript self-report alone cannot prove a hit. A home run
is a verified hit whose high-impact status was declared before the appearance
and which required no rework. Walks and unscored appearances are excluded from
at-bats.

## Lifecycle

At startup, Ballclub injects the bootstrap, synchronizes managed roster files,
and performs a non-blocking version check. Roster sync copies from the immutable
plugin payload into the harness agent directory; it never mutates the installed
plugin directory. Plugin updates require explicit approval and delegate to the
active harness package manager.

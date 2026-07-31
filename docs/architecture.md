# Architecture

Ballclub separates its baseball operating model from harness delivery.

## Core loop

1. The manager identifies the phases that actually exist without manufacturing
   a design-to-implementation-to-review chain. Conversation, status, routing,
   integration, and acceptance verification remain manager work.
2. Every design, implementation, or review phase calls an eligible player
   regardless of size. `capacity-routing` classifies the operation boundary and
   builds a least-sufficient lineup for that phase.
3. A dispatch skill creates one or more bounded plate appearances with owned
   outcomes, constraints, completion criteria, and focused verification.
4. `SubagentStop` records player and Coach appearances, while `Stop` records
   substantive manager-only appearances without double-counting delegated turns.
5. The manager reruns or confirms predeclared acceptance checks and applies the
   official score. Returned text or transcript content alone is not a hit.
6. `score` aggregates daily, weekly, and monthly scorecards. Comparable verified
   history adjusts effort only inside the already-eligible class; sparse or
   unscored data leaves the static routing rules unchanged.

When review is independent and Coach is available, its eligible player and
Coach run concurrently. Coach is omitted only when unavailable or the reviews
are not independent. Other phase appearances are sequential unless parallel
dispatch independently applies.

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
Mandatory player calls apply to existing phases regardless of size, not absent
phases or a global methodology chain.

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
appearance. Manager verification is limited to rerunning or confirming
predeclared acceptance checks. Correctness, regression, security, design
tradeoff, code quality, and diff judgment require a player review appearance;
transcript self-report alone cannot prove a hit. A home run
is a verified hit whose high-impact status was declared before the appearance
and which required no rework. Walks and unscored appearances are excluded from
at-bats.

## Lifecycle

At startup, Ballclub injects the bootstrap, synchronizes managed roster files,
and performs a non-blocking version check. Roster sync copies from the immutable
plugin payload into the harness agent directory; it never mutates the installed
plugin directory. Plugin updates require explicit approval and delegate to the
active harness package manager.

# Runtime flow

## Session bootstrap

`hooks/session-start` injects `using-ballclub` at startup, clear, and compact.
The bootstrap establishes the manager, player, Coach, lineup, plate appearance,
and scorebook boundaries. It does not force unrelated development workflows.

## Managed roster bootstrap

Codex discovers custom agents only from personal `~/.codex/agents/` or project
`.codex/agents/` configuration. Ballclub ships canonical definitions under
`agents/codex/`. On `SessionStart`, the plugin automatically installs missing
profiles and updates unchanged Ballclub-managed files using recorded hashes.
Compatible custom instructions and conflicting user profiles stay untouched.
When files changed, a fresh session loads the resulting roster.

Claude Code discovers personal subagents from `~/.claude/agents/`. The same
bootstrap installs Fable setters, Opus batters, Sonnet bench players, and
external GPT-5.6 Sol coaches from `rosters/claude/` without asking for a roster
choice.

`setup-ballclub` is reserved for explicit inspection, conflict repair, and
custom roster work. Forced replacement names the affected files, requires
approval, and creates a backup before replacement.

## Appearance collection

The `SubagentStop` hook matches declared player and Coach profiles. The `Stop`
hook identifies substantive manager-only turns and skips delegated or routine
turns. Both invoke `scripts/collect-appearance.mjs`; a harness adapter normalizes
runtime identity and token usage before writing an unscored event beneath:

```text
Codex:       ${BALLCLUB_DATA:-~/.codex/ballclub}/events/YYYY-MM-DD/
Claude Code: ${BALLCLUB_DATA:-~/.claude/ballclub}/events/YYYY-MM-DD/
```

An explicit `BALLCLUB_DATA` overrides both defaults. Existing mixed data is not
automatically moved because source attribution may be incomplete.

Claude Code can invoke `SubagentStop` before its final child transcript row is
flushed. The collector preserves the pending appearance and the parent `Stop`
reconciles its model and usage from the Agent result by `agentId` and
`promptId`; it does not estimate missing usage.

Collection errors are written separately and never block the subagent return.

## Review and scoring

The manager compares the owned completion criteria with fresh verification it
owns, such as a rerun check or confirmed external state. A transcript may
explain the attempt but cannot establish a hit alone. Scoring should happen
after integration when evidence is available rather than waiting for a report
request. `scripts/score-appearance.mjs` applies official player and manager
results while rejecting Coach scoring and paths outside the harness data root.

## Reporting

`scripts/generate-report.mjs` aggregates one daily, ISO-weekly, or monthly
period. Reports include appearances, at-bats, hits, average, home runs, errors,
player salary, direct-manager scoring and salary, pending reviews, player
rankings, Coach call counts, and runtime profile mismatches. Before a comparable
future assignment, `capacity-routing` uses verified history to adjust effort
inside the eligible class and falls back to static rules when evidence is
insufficient.

```text
lineup -> appearance -> collect -> verify -> score -> report -> next lineup
```

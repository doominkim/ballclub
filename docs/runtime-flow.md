# Runtime flow

## Session bootstrap

`hooks/session-start` injects `using-ballclub` at startup, clear, and compact.
The bootstrap establishes the manager, player, Coach, lineup, plate appearance,
and scorebook boundaries. It does not force unrelated development workflows.

## Codex roster setup

Codex discovers custom agents only from personal `~/.codex/agents/` or project
`.codex/agents/` configuration. Ballclub ships canonical definitions under
`agents/codex/` and installs them through `setup-ballclub` with managed hashes.
Missing and unchanged managed profiles update safely. Unknown or user-modified
files remain conflicts until explicit force approval, which creates a backup
before replacement. A fresh session loads the resulting roster.

## Appearance collection

The `SubagentStop` hook matches declared player and Coach profiles and invokes
`scripts/collect-appearance.mjs`. The collector reads the child transcript,
records runtime identity and token usage, and writes an unscored event beneath:

```text
${BALLCLUB_DATA:-~/.codex/ballclub}/events/YYYY-MM-DD/
```

Collection errors are written separately and never block the subagent return.

## Review and scoring

The manager compares the owned completion criteria with focused verification
evidence. `scripts/score-appearance.mjs` applies the official result while
rejecting Coach scoring and paths outside the Ballclub event directory.

## Reporting

`scripts/generate-report.mjs` aggregates one daily, ISO-weekly, or monthly
period. Reports include appearances, at-bats, hits, average, home runs, errors,
player salary, pending reviews, player rankings, Coach call counts, and runtime
profile mismatches.

```text
lineup -> appearance -> collect -> verify -> score -> report -> next lineup
```

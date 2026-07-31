---
name: scorebook
description: Score a verified Ballclub player or manager appearance after integration, or generate Ballclub agent-performance reports. Use for a resolved Ballclub appearance or report-specific requests such as scorecard, team report, token salary, token 연봉, 일봉, 주봉, 월봉, and 구단 성적, even when Ballclub is implicit. Treat player salary or 선수 연봉 as a trigger only with Ballclub, agent, team-report, or period-report context such as 월봉 or 이번 달. Treat 안타, 타율, 홈런, 실책, and 안타당 token as triggers only with Ballclub, agent, player-performance, or team-report context. Do not use for real-world baseball statistics or general baseball rules.
---

# Scorebook

Score verified work promptly and generate period reports without exposing task
names by default. Keep Setter, Batter, and Bench in one player leaderboard,
manager work in its own section, and Coach calls separate.

## Score an appearance

After integration, find the corresponding unscored event. Read its transcript
to understand the assignment and claimed result, but never award `hit` or
`homeRun` from transcript content or a returned response alone. Require fresh,
manager acceptance verification limited to rerunning or confirming predeclared
acceptance checks. Diff judgment, correctness, regression, security, design
tradeoff, and code quality require a separate player review appearance. `walk`,
`out`, and `error` also require focused evidence; leave ambiguity unscored.

Apply one result:

- `hit`: completion criteria passed focused verification;
- `walk`: correct escalation prevented unsupported guessing;
- `out`: work failed or remained incomplete without sound escalation;
- `error`: a completion claim caused confirmed rework;
- `homeRun`: a predeclared high-impact hit completed without rework.

```bash
node <plugin-root>/scripts/score-appearance.mjs \
  --event <absolute-appearance-json> \
  --result <hit|walk|out|error> \
  --home-run <true|false> \
  --rbi <non-negative-integer> \
  --evidence <manager-verification-summary>
```

`RBI` is the count of additional predeclared, independently verified outcomes
delivered beyond the appearance's primary owned outcome. Default to `0`; never
infer it from perceived impact.

## Generate a report

Use `$ballclub:scorebook d|w|m` in Codex or `/ballclub:scorebook d|w|m` in
Claude Code. Map either explicit form, or an equivalent natural Ballclub report
request, to `daily`, `weekly`, or `monthly`, then run:

```bash
node <plugin-root>/scripts/generate-report.mjs \
  --period <daily|weekly|monthly> [--date YYYY-MM-DD]
```

For a month use its first day as the anchor; for an ISO week use any date in
that week. Read the generated Markdown and return it with a clickable local
file link. Hide task descriptions unless evidence is explicitly requested.

## Accounting

- One collected player stop is one player PA; a substantive manager-only turn
  is one manager PA.
- Hits, outs, and errors count as at-bats. Walks and unscored appearances do
  not count as at-bats or reduce batting average.
- Salary uses normalized recorded `total_tokens`. It is token volume, not
  currency cost.
- Exclude Coach usage from every salary and efficiency calculation; show only
  Coach call counts.
- Show declared-versus-runtime identity mismatches as operating warnings.
- If no events exist, explain that collection starts after trusted hooks run.

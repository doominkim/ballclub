---
name: score
description: Generate and archive Ballclub daily, weekly, or monthly player reports from recorded plate appearances. Use when the user asks for 일봉, 주봉, 월봉, 구단 성적, 선수 호출 수, 안타, 타율, 홈런, 실책, token 연봉, 연봉 점유율, or 안타당 token. Exclude Coach profiles from every token salary calculation.
---

# Scorecard

Generate one period-level report without listing individual task names. Treat
`setter`, `batter`, and `bench` profiles as players in one leaderboard. Treat
`chief-coach`, `coach`, and `assistant-coach` as external advisers.

## Generate a report

1. Resolve the plugin root as two directories above this `SKILL.md`.
2. Map the explicit short form or natural request to one period:
   - `$score d`, `일봉`, today, or a calendar day -> `daily`
   - `$score w`, `주봉`, this week, or an ISO week -> `weekly`
   - `$score m`, `월봉`, this month, or a calendar month -> `monthly`
3. Run:

   ```bash
   node <plugin-root>/scripts/generate-report.mjs --period <daily|weekly|monthly> [--date YYYY-MM-DD]
   ```

4. Read the generated Markdown path printed by the command.
5. Return the report content and a clickable local file link. Keep individual
   task descriptions hidden unless the user explicitly asks for evidence.

For `$score d|w|m [date]`, treat the optional date as the period anchor. If the request gives a month but no day, use the first day of that month as
`--date`. If it gives an ISO week, use any date in that week.

## Score unresolved appearances

Never turn a returned response into an automatic hit. If the report shows
`검수대기`, inspect only the corresponding event's `transcriptPath` and final
verification evidence. Apply a score only when the evidence is clear:

- `hit`: the owned completion criteria passed focused verification.
- `walk`: the player correctly stopped and escalated instead of guessing.
- `out`: the owned result failed or remained incomplete without a sound
  escalation.
- `error`: the player claimed completion but caused confirmed rework.
- `homeRun`: a predeclared high-impact or high-risk assignment became a
  verified hit without rework.

Record a score with:

```bash
node <plugin-root>/scripts/score-appearance.mjs \
  --event <absolute-appearance-json> \
  --result <hit|walk|out|error> \
  --home-run <true|false> \
  --rbi <non-negative-integer> \
  --evidence <short-verification-summary>
```

Leave ambiguous appearances unscored. After scoring, regenerate the report.

## Accounting rules

- Count one collected subagent stop as one plate appearance.
- Exclude unscored events from at-bats and batting average.
- Calculate player salary from recorded `total_tokens` only.
- Never include Coach token usage in player salary, team salary, salary share,
  or tokens per hit.
- Show Coach calls separately without token columns.
- Surface declared-profile versus actual model/provider mismatches as operating
  warnings, not task details.
- Do not infer currency cost from token volume.

## Empty data

If no records exist for the requested period, say that collection begins after
the plugin hook is installed and trusted. Do not fabricate a sample season
unless the user explicitly asks for one.

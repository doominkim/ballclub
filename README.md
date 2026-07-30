# Ballclub

**English** | [한국어](README_KR.md)

> **Upstream origin:** [obra/superpowers](https://github.com/obra/superpowers)
> is the original project. Ballclub retains adapted plugin, skill, hook, and
> script infrastructure under its upstream MIT notice, but introduces its own
> baseball-native multi-agent operating model.

**Build the lineup. Send agents to bat. Keep the score.**

Ballclub is a multi-agent harness for Codex and Claude Code. The main agent is
the manager, executable capacity profiles are players, Coach profiles are
external advisers, and each completed subagent turn is a plate appearance.
Ballclub routes work to an eligible player, records the appearance, requires
verification before awarding a hit, and generates daily, weekly, and monthly
team reports.

## The game model

| Baseball | Agent operation |
|---|---|
| Manager | Main agent that owns goals, lineup, synthesis, and user communication |
| Player | Setter, Batter, or Bench capacity profile allowed to execute an assignment |
| Coach | External adviser that can refine decisions but cannot mutate or score work |
| Lineup | Eligible, least-sufficient profile selection for the current work |
| Plate appearance | One bounded subagent turn with completion and verification criteria |
| Hit | Owned completion criteria passed focused verification |
| Walk | Correct escalation instead of guessing |
| Out | Failed or incomplete result without sound escalation |
| Error | Completion claim that caused confirmed rework |
| Home run | Predeclared high-impact appearance completed and verified without rework |
| Salary | Recorded player tokens; Coach tokens are excluded |

A returned response is never an automatic hit. Ambiguous appearances remain
unscored until the manager can inspect verification evidence.

## Install

### Codex CLI and Codex app

```bash
codex plugin marketplace add doominkim/ballclub
codex plugin add ballclub@ballclub-marketplace
```

### Claude Code

```bash
claude plugin marketplace add doominkim/ballclub
claude plugin install ballclub@ballclub-marketplace
```

Approve the bundled hooks and start a fresh session.

## Core loop

```text
manager reads the game state
  -> builds an eligible lineup
  -> defines a bounded plate appearance
  -> sends a player to bat
  -> records the returned appearance
  -> verifies and officially scores it
  -> updates the scorecard and next lineup
```

`skills/using-ballclub` establishes the club rules. `capacity-routing` builds
the lineup, dispatch skills define plate appearances, and `scorecard`
generates scorecards. Existing development skills remain independently
triggered; baseball terminology does not force TDD, planning, review, or any
other methodology chain.

## Reports

Call the report skill explicitly:

```text
$scorecard Show today's daily report.
```

Natural requests such as `Show today's scorecard`, `Show this week's team
report`, and `Show this month's player salaries` trigger the same skill.

Ballclub stores runtime data under `~/.codex/ballclub` by default. Override it
with `BALLCLUB_DATA`.

```bash
node scripts/generate-report.mjs --period daily
node scripts/generate-report.mjs --period weekly
node scripts/generate-report.mjs --period monthly
```

Official scoring uses:

```bash
node scripts/score-appearance.mjs \
  --event <appearance-json> \
  --result <hit|walk|out|error> \
  --home-run <true|false> \
  --rbi <non-negative-integer> \
  --evidence <verification-summary>
```

## Update lifecycle

On a fresh startup Ballclub checks for a newer version at most once per day.
It never updates without explicit approval, and a successful update requires a
fresh session. Disable the check with `BALLCLUB_DISABLE_UPDATE_CHECK=true`.

## Verify

```bash
npm test
claude plugin validate .
```

## License and attribution

Ballclub is licensed under the MIT License. Adapted portions originating from
`obra/superpowers` retain the upstream notice in
`third_party/superpowers-LICENSE`. Ballclub is an independent project and is
not affiliated with or endorsed by the upstream maintainers.

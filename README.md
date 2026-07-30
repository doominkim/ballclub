# Ballclub

**English** | [한국어](README_KR.md)

> **Not a team-report plugin. A harness for operating multi-agent work like a real club.**

You have plenty of models. You should not have to choose one from scratch for every task,
hand-write vague delegation prompts, trust every returned answer, and forget the result before
the next assignment.

That is the manager's job.

Install Ballclub and give it the objective. The manager reads the game state, selects the
least-sufficient eligible player, creates a bounded plate appearance, and verifies the result.
A returned response is not a hit. Only evidence-backed work enters the official scorebook and
informs the next lineup.

**Build the lineup. Send a player to bat. Verify the result. Keep the score.**

> **Upstream origin:** Ballclub retains adapted plugin, skill, hook, and script
> infrastructure from [obra/superpowers](https://github.com/obra/superpowers) under its MIT
> notice. Its baseball-native operating model, routing, appearance collection, and verified
> scoring loop are Ballclub's independent core.

## Install

### Codex CLI and Codex app

```bash
codex plugin marketplace add doominkim/ballclub
codex plugin add ballclub@ballclub-marketplace
```

To start the roster interview without typing into a blank conversation, install the launcher
once from the repository:

```bash
bash scripts/install-launcher
ballclub
```

`ballclub` opens Codex and submits the setup request as the first prompt. Codex options are
forwarded unchanged, for example `ballclub -C /path/to/project`.

In a fresh session, run the roster interview once:

```text
$setup-ballclub
```

If player profiles are missing or only partially installed, the interview starts automatically
on the first conversation in a new session. Use the command above to start it immediately.

Setup first asks for the main harness and manager model, then installs the matching model and
effort definitions. GPT managers get the recommended `Sol / Terra / Luna` roster; Claude
managers get `Fable / Opus / Sonnet`. It never silently overwrites a different existing file.

### Claude Code

```bash
claude plugin marketplace add doominkim/ballclub
claude plugin install ballclub@ballclub-marketplace
```

Approve the bundled hooks and start a fresh session.

Run `$setup-ballclub` in Claude Code to install the actual player profiles under
`~/.claude/agents/`.

## Ballclub in 30 seconds

```text
user provides an objective
  -> manager reads goals, constraints, risk, and game state
  -> manager chooses the required operation boundary
  -> manager selects the least-sufficient eligible player
  -> player receives a bounded appearance with completion and verification criteria
  -> hook records runtime identity, metadata, and tokens
  -> manager scores only from focused verification evidence
  -> scorecard feeds the next lineup
```

Ballclub does not delegate everything. Small or conversation-coupled work stays with the
manager. A player goes to bat only when substantial independent work protects the main context
or adds meaningful execution capacity.

## Highlights

| Feature | What it does |
|---|---|
| ⚾ Boundary-first routing | Chooses `Setter`, `Batter`, or `Bench` authority before comparing effort |
| 📋 Least-sufficient lineup | Selects the lowest sufficient effort inside the eligible player class |
| 🎯 Contracted appearances | Requires ownership, constraints, completion criteria, and focused verification |
| 🧠 Context protection | Isolates large investigation or implementation while the manager retains game state |
| ✅ Evidence-backed scoring | Never awards a hit because a response merely returned |
| 📈 Operational scorecards | Uses calls, average, errors, home runs, and token salary as lineup feedback |
| 🪝 Automatic collection | Records actual player and Coach appearances through `SubagentStop` |
| 🔌 Two harnesses | Delivers the same operating model to Codex and Claude Code |

## This is not a reporting plugin

The scorecard is the end of Ballclub's loop, not the beginning.

The harness joins three decisions that are usually disconnected: **who should take the work**,
**what boundary they own**, and **what proves completion**. Reports are the dashboard for that
operating loop. They are feedback for the next lineup, not decorative call counts.

## Harness anatomy

### Manager

The main agent is the manager. It owns the objective, constraints, user communication, lineup,
integration, official scoring, and next adjustment. It is not a relay that forwards player text.

### Roster

Design, implementation, investigation, and review are assignments, not player identities.
Player classes are separated by their permitted operation boundary.

| Class | Model family | Operation boundary | Profiles |
|---|---|---|---|
| `Setter` | GPT-5.6 Sol | Full operations, including design, implementation, and complex judgment | `1setter(max)` to `5setter(low)` |
| `Batter` | GPT-5.6 Terra | Bounded execution inside an already-defined scope | `1batter(xhigh)` to `4batter(low)` |
| `Bench` | GPT-5.6 Luna | Investigation, classification, repeated verification, and evidence collection | `1bench(high)` to `3bench(low)` |
| `Coach` | Cross-provider external adviser | Independent context analysis and decision-packet refinement; no mutation or official scoring | `chief-coach`, `coach`, `assistant-coach` |

This is the default GPT/Codex roster, not a set of documentation-only aliases.
`$setup-ballclub` installs 15 Codex custom-agent TOML files with explicit model and effort values.
For a Claude manager it installs 15 Claude Code subagent Markdown files with Fable setters, Opus
batters, Sonnet bench players, and external GPT-5.6 Sol coaches. Actual use still depends on model
availability for the account or workspace.

### Roster interview

Setup does not ask for all 15 profiles individually. It asks for the main harness and manager,
then confirms one grouped roster:

| Main manager | Setter | Batter | Bench | Coach |
|---|---|---|---|---|
| GPT / Codex | GPT-5.6 Sol | GPT-5.6 Terra | GPT-5.6 Luna | external Claude Opus |
| Claude Fable or Opus | Claude Fable | Claude Opus | Claude Sonnet | external GPT-5.6 Sol |

Coach deliberately uses the other provider so that planning and independent review do not share
the same model family by default.

There is no single global profile ranking. A high-effort player in the wrong class is still
ineligible. Ballclub chooses the operation boundary first, then the least-sufficient effort only
inside that class.

### Plate-appearance contract

One completed subagent turn is one plate appearance. Each appearance declares:

1. work phase and selected player;
2. owned outcome;
3. mutation boundary and constraints;
4. completion criteria;
5. focused verification;
6. predeclared high-impact eligibility when a home run is possible.

Overlapping work and shared unresolved decisions stay sequential. Parallel players are used only
when independence or context isolation outweighs coordination and merge risk.

### Verification and official scoring

```text
returned response != hit
```

The manager inspects current verification evidence before applying an official result. Ambiguous
appearances remain pending.

| Result | Rule |
|---|---|
| Hit `hit` | Owned completion criteria passed focused verification |
| Walk `walk` | Correct escalation prevented unsupported guessing |
| Out `out` | Work failed or remained incomplete without sound escalation |
| Error `error` | A completion claim caused confirmed rework |
| Home run `homeRun` | A predeclared high-impact appearance became a verified hit without rework |

### Runtime collection

The `SubagentStop` hook detects declared player and Coach profiles, reads runtime identity and
token usage from the transcript, and stores an unscored event without blocking the return path.

```text
${BALLCLUB_DATA:-~/.codex/ballclub}/events/YYYY-MM-DD/
```

Coach calls are reported separately and excluded from player salary, team salary, salary share,
and tokens per hit. Token volume is never converted into currency without an explicit price source.

## Scorecards

The short form is deliberately small:

```text
$score d                 # today
$score w                 # this week
$score m                 # this month
$score d 2026-07-30      # a specific day
$score m 2026-07         # a specific month
```

Natural requests such as `Show today's scorecard`, `Show this week's team report`, and `Show this
month's player salaries` trigger the same skill.

Reports cover appearances, at-bats, hits, average, home runs, errors, player token salary,
pending reviews, Coach calls, and declared-profile versus runtime-identity warnings.

Direct report generation and scoring are also available:

```bash
node scripts/generate-report.mjs --period daily
node scripts/generate-report.mjs --period weekly
node scripts/generate-report.mjs --period monthly

node scripts/score-appearance.mjs \
  --event <appearance-json> \
  --result <hit|walk|out|error> \
  --home-run <true|false> \
  --rbi <non-negative-integer> \
  --evidence <verification-summary>
```

## Skills are play cards, not a ritual chain

The session bootstrap activates `using-ballclub` and requires checking every potentially relevant
skill. Invoking one skill does not automatically force TDD, brainstorming, planning, review, or a
worktree. Each workflow runs only when its own trigger applies.

The core catalog is:

- `using-ballclub`: manager, player, Coach, appearance, and scorebook rules
- `capacity-routing`: boundary-first, least-sufficient lineup construction
- `dispatching-parallel-agents`: independent batting order and context isolation
- `subagent-driven-development`: ownership for already-bounded implementation appearances
- `score`: pending review plus daily, weekly, and monthly scorecards
- development workflow skills: independently triggered supporting methods

### Configuration boundaries

Do not copy Ballclub's common rules wholesale into a global `AGENTS.md`. When the same policy
evolves independently in two places, routing formats and delegation conditions can diverge.

| Location | Responsibility |
|---|---|
| Ballclub skills | Shared lineup, operation-boundary, least-sufficient, appearance, verification, and scoring rules |
| Host `AGENTS.md` | User- or repository-specific overrides such as language, display format, and approval policy |
| Codex `agents/*.toml`, Claude Code `agents/*.md` | Actual profile model, effort, tools, and mutation authority |
| Plugin config and hook trust | Installation activation and hook execution approval |

User instructions and repository rules override Ballclub's shared defaults. Keep only the
differences in host configuration instead of repeating the entire operating model.

`$setup-ballclub` records hashes for Ballclub-managed profiles. It safely updates files previously
installed by Ballclub, treats files with matching name, model, and effort as compatible while
preserving their custom instructions, and keeps other unknown files as conflicts. Force replacement
requires explicit approval and creates a backup first.

Read [Architecture](docs/architecture.md), [Runtime flow](docs/runtime-flow.md), and
[Game model](docs/game-model.md) for the deeper contracts.

## Updates

On fresh startup Ballclub checks for a newer version at most once per day. It never updates
without explicit approval, and a successful update requires a fresh session.

```bash
BALLCLUB_DISABLE_UPDATE_CHECK=true
```

## Verify

```bash
npm test
claude plugin validate .
```

## License and attribution

Ballclub is licensed under the MIT License. Adapted portions originating from
`obra/superpowers` retain the upstream notice in `third_party/superpowers-LICENSE`. Ballclub is
an independent project and is not affiliated with or endorsed by the upstream maintainers.

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

The plugin manages its bundled roster automatically. On the first approved `SessionStart`, it
installs the matching Codex profiles and asks for a fresh session only when the loaded catalog
changed. There is no roster interview or per-profile installation prompt.

An optional launcher is available if you want a short `ballclub` command for opening Codex:

```bash
bash scripts/install-launcher
ballclub
```

`ballclub` opens Codex without injecting a setup prompt. Codex options are forwarded unchanged,
for example `ballclub -C /path/to/project`.

### Claude Code

```bash
claude plugin marketplace add doominkim/ballclub
claude plugin install ballclub@ballclub-marketplace
```

Approve the bundled hooks and start a fresh session.

The first approved `SessionStart` synchronizes the bundled Claude Code profiles under
`~/.claude/agents/`. Start a fresh session if Ballclub reports that the roster changed.

## Ballclub in 30 seconds

```text
user provides an objective
  -> manager reads goals, constraints, risk, and game state
  -> actual design, implementation, or review phases require a player appearance
  -> manager chooses the required operation boundary
  -> manager selects the least-sufficient eligible player
  -> player receives a bounded appearance with completion and verification criteria
  -> harness adapter records runtime identity, metadata, and tokens
  -> manager scores only from independent focused verification evidence
  -> verified scorecard history adjusts effort inside the eligible class
```

Ballclub does not manufacture a design-to-implementation-to-review chain. It does require an
eligible player whenever work actually enters a design, implementation, or review phase,
regardless of size. Conversation, status, routing, integration, and acceptance verification stay
with the manager and are not phase appearances.

Routing remains internal until the called player/profile composition changes. At that point the
manager announces `선수교체: <profile or lineup> — <reason>` once. Continuing with the same player,
retrying, or returning to manager-owned integration and delivery produces no routing banner.

## Highlights

| Feature | What it does |
|---|---|
| ⚾ Boundary-first routing | Chooses `Setter`, `Batter`, or `Bench` authority before comparing effort |
| 📋 Least-sufficient lineup | Selects the lowest sufficient effort inside the eligible player class |
| 🎯 Contracted appearances | Requires ownership, constraints, completion criteria, and focused verification |
| 🧠 Context protection | Isolates large investigation or implementation while the manager retains game state |
| ✅ Evidence-backed scoring | Never awards a hit because a response merely returned |
| 📈 Operational scorecards | Uses calls, average, errors, home runs, and token salary as lineup feedback |
| 🪝 Automatic collection | Records players and Coach through `SubagentStop`, plus direct manager work through `Stop` |
| 🔌 Two harnesses | Delivers the same operating model to Codex and Claude Code |

## This is not a reporting plugin

The scorecard is the end of Ballclub's loop, not the beginning.

The harness joins three decisions that are usually disconnected: **who should take the work**,
**what boundary they own**, and **what proves completion**. Reports are the dashboard for that
operating loop. They are feedback for the next lineup, not decorative call counts.

## Harness anatomy

### Manager

The main agent is the manager. It owns the objective, constraints, user communication, lineup,
integration, official decisions, acceptance verification, scoring, and next adjustment. It does
not replace the player's output for a required phase. Direct manager appearances may
still cover substantive work outside mandatory design, implementation, and review phases.

### Roster

Design, implementation, investigation, and review are assignments, not player identities.
Player classes are separated by their permitted operation boundary.

| Class | Model family | Operation boundary | Profiles |
|---|---|---|---|
| `Setter` | GPT-5.6 Sol | Full operations, including design, implementation, and complex judgment | `1setter(max)` to `5setter(low)` |
| `Batter` | GPT-5.6 Terra | Bounded execution inside an already-defined scope | `1batter(xhigh)` to `4batter(low)` |
| `Bench` | GPT-5.6 Luna | Investigation, classification, repeated verification, and evidence collection | `1bench(high)` to `3bench(low)` |
| `Coach` | Cross-provider external adviser | Independent context analysis and decision-packet refinement; no mutation or official scoring | `chief-coach`, `coach`, `assistant-coach` |

This is the default GPT/Codex roster, not a set of documentation-only aliases. Ballclub's
`SessionStart` bootstrap synchronizes 15 Codex custom-agent TOML files with explicit model and
effort values. Under Claude Code it synchronizes 15 subagent Markdown files with Fable setters,
Opus batters, Sonnet bench players, and external GPT-5.6 Sol coaches. Actual use still depends on
model availability for the account or workspace.

### Managed roster lifecycle

The active harness selects one bundled roster automatically:

| Main manager | Setter | Batter | Bench | Coach |
|---|---|---|---|---|
| GPT / Codex | GPT-5.6 Sol | GPT-5.6 Terra | GPT-5.6 Luna | external Claude Opus |
| Claude Fable or Opus | Claude Fable | Claude Opus | Claude Sonnet | external GPT-5.6 Sol |

Coach deliberately uses the other provider so that planning and independent review do not share
the same model family by default. Missing profiles and unchanged Ballclub-managed profiles update
automatically. Compatible user instructions and conflicting custom profiles are preserved.
Claude Code plugin agents do not support `permissionMode`; their enforceable profile surface is
`tools` and `disallowedTools`. Coach still needs `Bash` for its external-provider wrapper, so its
no-mutation rule is an operating contract rather than an OS sandbox boundary.
Compatible profiles whose supported security fields drift are preserved but surfaced as a
`roster-security-drift` warning for explicit repair.

There is no single global profile ranking. A high-effort player in the wrong class is still
ineligible. Ballclub chooses the operation boundary first, then the least-sufficient effort only
inside that class.

Setter is required when unresolved design, interface, scope, or policy decisions are materially
likely. Batter is eligible only when those decisions, mutation boundaries, contracts, and
completion criteria are already fixed. This is an authority and decision boundary; shared tools
do not make the two classes interchangeable.

### Plate-appearance contract

One completed player turn is one player plate appearance. Each delegated appearance declares:

1. work phase and selected player;
2. owned outcome;
3. mutation boundary and constraints;
4. completion criteria;
5. focused verification;
6. predeclared high-impact eligibility when a home run is possible.

Overlapping work and shared unresolved decisions stay sequential. Parallel players are used only
when independence or context isolation outweighs coordination and merge risk.
During review, when independent review is possible and Coach is available, an eligible player
assigned the review and Coach run in parallel. Coach is omitted only when unavailable or when the
reviews are not independent. It remains advisory and does not replace the player appearance or
manager acceptance verification. Phase-call requirements do not otherwise imply parallelism.

### Verification and official scoring

```text
returned response != hit
```

The manager reruns or confirms only the predeclared acceptance checks before applying an official
result. Correctness, regression, security, design tradeoff, code quality, and diff judgment form a
review phase and require an eligible player. A transcript alone cannot prove a hit; ambiguous
appearances remain pending.

| Result | Rule |
|---|---|
| Hit `hit` | Owned completion criteria passed focused verification |
| Walk `walk` | Correct escalation prevented unsupported guessing |
| Out `out` | Work failed or remained incomplete without sound escalation |
| Error `error` | A completion claim caused confirmed rework |
| Home run `homeRun` | A predeclared high-impact appearance became a verified hit without rework |

### Runtime collection

The `SubagentStop` hook detects declared player and Coach profiles. The `Stop` hook records a
manager appearance only for a substantive manager-only turn, skipping delegated and routine
conversation turns. Both collectors store unscored events without blocking the return path.

```text
Codex:       ${BALLCLUB_DATA:-~/.codex/ballclub}/events/YYYY-MM-DD/
Claude Code: ${BALLCLUB_DATA:-~/.claude/ballclub}/events/YYYY-MM-DD/
```

`BALLCLUB_DATA` remains an explicit shared-root override. Ballclub does not automatically move
legacy mixed data from `~/.codex/ballclub`; new default writes are separated by harness.

Claude Code may fire `SubagentStop` before the final child transcript row is durable. Ballclub
writes that appearance as pending runtime metadata, then reconciles model and usage from the
parent Agent result at `Stop` using `agentId` plus `promptId`.

Manager results are reported separately from the player leaderboard. Coach calls remain separate
and excluded from salary and tokens per hit. Codex and Claude retain their raw usage components;
`total_tokens` is normalized token volume, never currency cost.

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

Reports cover player and direct-manager appearances, at-bats, hits, average, home runs, errors,
token salary, pending reviews, Coach calls, and declared-profile versus runtime-identity warnings.
Before a later comparable assignment, verified history is used only inside the already-eligible
class: repeated errors or rework favor higher effort or MAIN, while repeated hits without errors
favor the least-sufficient lower effort. Sparse, unscored, or incomparable data leaves the static
routing rules unchanged.

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

The session bootstrap activates `using-ballclub`. During Ballclub routing, delegation, scoring, or
appearance interpretation, every Ballclub skill with even a 1% chance of applying must be checked.
Unrelated work uses the host's normal skill discovery instead of making Ballclub a global trigger.
Invoking one skill does not automatically force TDD, brainstorming, planning, review, or a
worktree. Each workflow runs only when its own trigger applies. The phase-call rule applies only
to design, implementation, or review phases that actually exist; it does not create
those phases or a mandatory methodology chain.

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

Ballclub records hashes for managed profiles. It safely updates files previously installed by
Ballclub, treats files with matching name, model, and effort as compatible while preserving their
custom instructions, and keeps other unknown files as conflicts. `$setup-ballclub` is the explicit
diagnostic and repair surface for those conflicts. Force replacement requires approval for the
named files and creates a backup first.

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

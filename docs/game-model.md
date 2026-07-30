# Ballclub game model

Ballclub uses baseball as its operating model rather than as a reporting skin.

## Participants

- The main agent is the manager. It owns the game objective, constraints,
  lineup, official decisions, integration, and user communication. A
  substantive task it retains and executes without a player is a manager plate
  appearance.
- Setter, Batter, and Bench profiles are players. Their declared operation
  boundary determines eligibility; effort is compared only within an eligible
  class.
- Chief Coach, Coach, and Assistant Coach are external advisers. They can
  inspect decision packets but cannot mutate work or receive a player score.

## Plate appearance contract

Every delegated player turn declares:

1. player and work phase;
2. owned outcome;
3. constraints and mutation boundary;
4. completion criteria;
5. focused verification;
6. whether high-impact home-run eligibility was declared before execution.

## Official scoring

| Result | Rule |
|---|---|
| Hit | Completion criteria passed focused verification |
| Walk | Correct escalation prevented unsupported guessing |
| Out | Result failed or stayed incomplete without sound escalation |
| Error | A completion claim caused confirmed rework |
| Home run | A predeclared high-impact appearance became a verified hit without rework |

Returning an answer closes an appearance but does not award a hit. When
evidence is insufficient, the record remains unscored.

A manager appearance is recorded only when the manager performs substantive
work without sending a player to bat. Routine routing, integration, status, and
conversation do not create manager appearances. Manager results use the same
verified scoring rules but appear separately from the player leaderboard.

## Club economics

Recorded player and direct-manager tokens are called salary. Coach tokens are
excluded from salary and tokens-per-hit. Token volume is never converted into
currency cost without an explicit pricing source.

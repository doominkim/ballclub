---
name: setup-ballclub
description: Interview the user about their main harness and manager model, then install, repair, or update Ballclub's model-defined Codex or Claude Code roster without overwriting custom agents. Use after installing or updating Ballclub, when configuring player models, or when Setter, Batter, Bench, or Coach profiles are missing or stale.
---

# Set Up Ballclub

Choose a roster from the manager's actual harness and model, then install it safely.

## Run the roster interview

Ask one question at a time. Skip any answer already known from the current runtime.

1. Ask which main harness they use: Codex, Claude Code, or both.
2. Ask which model runs the main manager.
3. Present the matching roster and ask whether to install it:

   | Manager | Setter | Batter | Bench | Coach |
   |---|---|---|---|---|
   | GPT / Codex | GPT-5.6 Sol | GPT-5.6 Terra | GPT-5.6 Luna | external Claude Opus |
   | Claude Fable or Opus | Claude Fable | Claude Opus | Claude Sonnet | external GPT-5.6 Sol |

   Explain that effort tiers remain `Setter max..low`, `Batter xhigh..low`, and `Bench high..low`. Do not ask the user to choose all 15 profiles individually.
4. If they reject the matching roster, collect one model family for each of Setter, Batter, Bench, and Coach. Do not write a custom roster until you have shown the exact generated mapping and received confirmation.

## Install a bundled roster

Resolve the plugin root as two directories above this `SKILL.md`. Use `scripts/setup-codex-agents.mjs` for Codex and `scripts/setup-claude-agents.mjs` for Claude Code. For `both`, run each flow separately.

1. Inspect with `node <script> --check --json`.
2. If every profile is `current` or `compatible`, do not write anything.
3. If profiles are `missing` or `managed-update` and none are `conflict`, run `node <script> --install --json`.
4. Preserve every `conflict`. Report only its filenames. Use `--install --force --json` only after explicit approval; it backs up replaced files first.
5. Re-run `--check --json` and require all profiles to be `current` or `compatible`.
6. Tell Codex users to start a fresh session. Claude Code detects changes within seconds unless its agents directory did not exist when the session started, in which case restart it.

## Boundaries

- Invoking this skill authorizes missing and safely managed profile installation, not forced replacement.
- Never edit `config.toml`, `settings.json`, `AGENTS.md`, `CLAUDE.md`, or unrelated agents.
- Do not claim account availability merely because a profile installed. Claude Fable requires an eligible account and supported Claude Code version.
- A matching name, model, and effort with different user instructions is `compatible` and stays untouched.

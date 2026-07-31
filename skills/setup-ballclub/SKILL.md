---
name: setup-ballclub
description: Inspect or repair Ballclub's managed Codex or Claude Code roster when automatic SessionStart synchronization reports conflicts, security drift, degraded setup, missing profiles, or stale profiles, or when the user explicitly asks to customize or reset player models.
---

# Set Up Ballclub

Inspect or repair the roster without turning normal plugin installation into an interview.

## Normal lifecycle

Ballclub bundles one roster per harness. Its `SessionStart` bootstrap detects Codex or Claude Code, installs missing managed profiles, updates unchanged Ballclub-managed profiles, and preserves compatible or conflicting user files. Do not ask about the harness, manager model, roster mapping, or installation during a healthy startup.

The bundled mappings are:

- Codex: Setter GPT-5.6 Sol, Batter GPT-5.6 Terra, Bench GPT-5.6 Luna, external Claude Opus Coach.
- Claude Code: Setter Claude Fable, Batter Claude Opus, Bench Claude Sonnet, external GPT-5.6 Sol Coach.

## Inspect or repair

Resolve the plugin root as two directories above this `SKILL.md`. Use `scripts/setup-codex-agents.mjs` for Codex and `scripts/setup-claude-agents.mjs` for Claude Code.

1. Detect the active harness from runtime context. Ask only if it genuinely cannot be determined.
2. Run `node <script> --check --json` and report only non-current filenames and statuses.
3. For `missing` or `managed-update`, run `node <script> --install --json`; this is the same safe managed synchronization used by SessionStart.
4. Preserve every `compatible` and `conflict` file. Report any `security-drift`
   warning and its fields separately; do not hide it behind compatibility.
   Never convert a conflict into a bundled profile merely to make the check green.
5. Use `--install --force --json` only after explicit approval for the exact conflict filenames. The command backs up replaced files first.
6. Re-run `--check --json`. A repaired bundled roster must be `current` or intentionally `compatible`.
7. Tell the user to start a fresh session before relying on newly installed or updated players.

## Boundaries

- Normal installation and managed updates belong to plugin bootstrap, not a conversational setup flow.
- Invoking this skill authorizes diagnosis plus missing and safely managed profile repair, not forced replacement.
- Never edit `config.toml`, `settings.json`, `AGENTS.md`, `CLAUDE.md`, or unrelated agents.
- Custom model mappings are user configuration. Show the exact files and mapping before editing, and preserve them as user-owned overrides afterward.
- Do not claim model availability merely because a profile installed.
- A matching name, model, and effort with different user instructions is `compatible` and stays untouched.
- Supported security fields such as `tools` and `disallowedTools` do not change
  identity compatibility; drift requires an explicit repair decision.

---
name: setup-ballclub
description: Install, repair, or update Ballclub's bundled Codex custom-agent profiles with their actual model, reasoning effort, instructions, and sandbox settings. Use after installing or updating Ballclub, when the user asks to configure the roster or player models, or when Setter, Batter, Bench, or Coach profiles are missing or stale.
---

# Set Up Ballclub

Install the bundled Codex roster without silently overwriting user-customized agents.

## Configure the roster

1. Resolve the plugin root as two directories above this `SKILL.md`.
2. Inspect profile state:

   ```bash
   node <plugin-root>/scripts/setup-codex-agents.mjs --check --json
   ```

3. If every profile is `current` or `compatible`, report that no profile write is needed. `compatible` means the actual name, model, and reasoning effort match while user instructions differ and remain preserved.
4. If profiles are `missing` or `managed-update` and none are `conflict`, run:

   ```bash
   node <plugin-root>/scripts/setup-codex-agents.mjs --install --json
   ```

5. If any profile is `conflict`, preserve it. Report only the conflicting filenames and explain that Ballclub did not overwrite user configuration. Use `--force` only after explicit user approval:

   ```bash
   node <plugin-root>/scripts/setup-codex-agents.mjs --install --force --json
   ```

   Forced replacement backs up conflicting files beneath the Ballclub data directory first.
6. Re-run `--check --json`. Require every bundled profile to be `current` or `compatible` before reporting success.
7. Tell the user to start a fresh Codex session so the new custom agents are discovered.

## Boundaries

- Treat invoking this setup skill as authorization to install missing and safely managed profiles.
- Never infer authorization to force-replace a conflicting profile.
- Do not edit `config.toml`, global `AGENTS.md`, or unrelated custom agents.
- Do not claim that a model is available to the account merely because its profile file installed.
- This setup targets local Codex custom agents. Do not install these TOML files for Claude Code.

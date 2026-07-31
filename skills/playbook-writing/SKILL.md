---
name: playbook-writing
description: Use when creating a new skill, editing an existing skill, narrowing or expanding its trigger, or validating skill behavior before distribution.
---

# Playbook Writing

Create concise, discoverable instructions that add judgment or reusable workflow
without duplicating what the model already knows.

## Workflow

1. Collect concrete examples that should and should not trigger the skill.
2. Define its responsibility boundary and identify repeated deterministic work.
3. For a new skill, use the host's canonical skill initializer when available.
4. Write frontmatter:
   - `name`: lowercase hyphen-case matching the directory;
   - `description`: specific triggering conditions, not a workflow summary.
5. Keep the body focused on decisions, sequencing, guardrails, and failure modes.
6. Move long reference material to `references/` and deterministic operations to `scripts/`.
7. Keep agent-facing interface metadata aligned with the skill's real behavior.
8. Validate structure and test realistic positive, negative, and pressure scenarios.

## Design rules

- Default to high freedom when context should guide judgment.
- Use exact steps only where ordering or safety is fragile.
- Keep frequently loaded skills especially short.
- Avoid deep reference chains and duplicate guidance.
- Do not add README, changelog, or process-history files inside a skill.
- Do not require unrelated skills merely because they existed in the source framework.
- Do not claim a skill works solely because its Markdown is valid.

When editing an installed or user-owned skill, preserve local decisions and
validate the changed trigger against both false positives and false negatives.
Testing may use examples, dry runs, or independent agents when available; TDD,
subagents, review, and commits are not automatic requirements.

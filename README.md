# Superpowers Lite

> **Upstream origin:** [obra/superpowers](https://github.com/obra/superpowers)
> is the original project. Superpowers Lite is a reduced adaptation that keeps
> its plugin, skill, hook, and script structure while removing mandatory
> methodology chains.

Superpowers Lite is a lightweight skill framework for Codex and Claude Code,
derived from Superpowers. It keeps strict skill discovery without forcing a
methodology bundle.

## Policy

- If there is even a 1% chance a skill applies, invoke it before responding or acting.
- Invoking one skill does not activate TDD, design, planning, worktrees, review, or another skill.
- Each methodology applies only when its own skill independently matches the task.
- User instructions and repository rules take precedence.

## Install

One repository supplies the shared `skills/` directory and lifecycle hooks for
both supported harnesses.

### Codex CLI and Codex app

```bash
codex plugin marketplace add doominkim/superpowers-lite
codex plugin add superpowers-lite@superpowers-lite-marketplace
```

Approve the bundled hooks when prompted, then start a new session. Codex IDE
extensions do not currently expose plugins.

### Claude Code

```bash
claude plugin marketplace add doominkim/superpowers-lite
claude plugin install superpowers-lite@superpowers-lite-marketplace
```

## Session-start update flow

The skill router bootstrap runs on `startup`, `clear`, and `compact`. A resumed
session reuses its existing context and does not inject the bootstrap again.

On a fresh `startup`, Superpowers Lite checks for updates at most once per day.
It stays silent when current, offline, or unable to read the remote version.
When a newer version exists, the agent asks in natural English adapted to the
current conversational context and tone. For example:

```text
There's a newer version of superpowers-lite available. Want me to update it now? We'll need to start a fresh session afterward.
```

Nothing changes until the user explicitly approves. Codex or Claude Code then
uses its native plugin manager. A successful update ends with:

```text
Updated superpowers-lite completed. End this session and start a new one.
```

The current session must stop because its already-loaded skills and hooks may
still be the old version. Disable checks with
`SUPERPOWERS_LITE_DISABLE_UPDATE_CHECK=true`.

## Repository structure

```text
.agents/plugins/        Codex marketplace metadata
.claude-plugin/         Claude Code plugin and marketplace metadata
.codex-plugin/          Codex plugin metadata
hooks/                  bootstrap and update SessionStart hooks
skills/                 harness-neutral behavior modules
scripts/                update and maintenance scripts
tests/                  structure and behavior tests
```

The package includes the mandatory skill router plus independently triggered
skills for focused brainstorming, systematic debugging, capacity routing,
completion verification, parallel dispatch or context isolation,
implementation-only subagents, branch finishing, and skill authoring. Update
handling lives in hooks and management scripts rather than the
skill catalog. Skills never form an automatic cross-skill chain.

## Verify

```bash
npm test
claude plugin validate .
```

## License and attribution

Superpowers Lite is licensed under the MIT License. Infrastructure patterns and
adapted portions originating from `obra/superpowers` retain their upstream MIT
notice in `third_party/superpowers-LICENSE`. Superpowers is the original
upstream project; Superpowers Lite is not presented as an independently
originated framework.

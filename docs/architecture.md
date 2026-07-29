# Architecture

Superpowers Lite keeps behavior separate from delivery:

1. `skills/` contains harness-neutral behavior.
2. manifests expose the same skill directory to each harness.
3. hooks or runtime adapters deliver the small bootstrap only where needed.
4. references translate abstract actions to native harness tools.
5. tests verify delivery without testing a mandatory methodology.

The bootstrap is intentionally small but keeps strict skill discovery: if there
is even a 1% chance a skill applies, invoke it before responding or acting.
Invocation only loads that skill. It does not automatically activate planning,
worktrees, TDD, review, branch completion, or any other methodology.

## Current skill catalog

- `using-superpowers-lite`: strict discovery without workflow chaining
- `brainstorming`: consequential ambiguity and approach selection
- `systematic-debugging`: evidence-led root-cause diagnosis
- `verification-before-completion`: fresh evidence before success claims
- `dispatching-parallel-agents`: independent concurrent subtasks or isolated disposable context
- `subagent-driven-development`: implementation roles only, without reviewers
- `finishing-a-development-branch`: explicit branch integration requests
- `writing-skills`: concise skill authoring and validation

Every skill must match independently. The catalog does not include planning,
TDD, worktree, or review skills, so selected skills must not depend on them.

## Session lifecycle

At a genuine session start, the delivery layer injects the bootstrap and runs a
non-blocking version check. A newer version produces an update notice containing
the approval boundary and exact management command. After approval, the runtime
script delegates the change to the active harness package manager. Plugin
lifecycle management never appears in the skill catalog.

```text
session start -> bootstrap -> update check -> no update: continue
                                      \-> update: ask user
                                                   \-> decline: continue
                                                   \-> approve: native update
                                                               \-> end session
```

Compaction may re-inject the skill bootstrap but must not re-ask the update
question. Network failures are silent, and version checks are cached for one
day. The installed plugin directory is never modified directly by a hook.

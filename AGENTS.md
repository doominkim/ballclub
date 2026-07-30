# Ballclub contributor guidance

- Keep all runtime-facing explanations and documentation concise.
- Treat `skills/` as the source of behavior; keep adapters behavior-neutral.
- Preserve the rule that a skill must be invoked when there is even a 1% chance it applies.
- Do not turn skill invocation into a mandatory TDD, design, planning, worktree, or review chain.
- Skill descriptions must name concrete triggers and must not match trivial or unrelated work.
- Preserve user instructions and repository-local rules over plugin guidance.
- Keep the baseball model structural: main is the manager, executable profiles are players, Coach profiles are advisers, and one completed subagent turn is one plate appearance.
- Never award a hit from a returned response alone; official scoring requires focused verification evidence.
- Run `npm test` and both validators before claiming a change is complete.

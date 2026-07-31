---
name: debugging-replay
description: Use when diagnosing a bug, test or build failure, unexpected behavior, performance regression, flaky result, or integration problem before proposing a fix.
---

# Debugging Replay

Find the root cause before changing production behavior. A plausible symptom is
not evidence of cause.

## Workflow

### 1. Establish the failure

- Read the complete error, stack trace, and relevant logs.
- Reproduce the problem with exact inputs and environment details when possible.
- Inspect recent changes and find the real runtime, request, storage, or data path.
- In multi-component systems, gather evidence at each boundary to locate where state diverges.

### 2. Compare patterns

- Find the closest working example in the same codebase.
- Compare dependencies, configuration, inputs, and control flow.
- List meaningful differences instead of dismissing small ones without evidence.
- For a bad value deep in the stack, use `references/root-cause-tracing.md`.

### 3. Test one hypothesis

- State one specific cause and the evidence supporting it.
- Use the smallest diagnostic or change that can disprove the hypothesis.
- Change one variable at a time and inspect the result before continuing.
- If evidence contradicts the hypothesis, discard it rather than stacking fixes.

### 4. Fix and verify

- Fix the source of the problem with the smallest repo-conforming change.
- Add a regression test or deterministic reproduction when practical; do not
  invoke a TDD skill automatically.
- Run focused verification, then broaden it in proportion to integration risk.
- If three distinct fix attempts fail, stop and discuss whether the architecture
  or assumption is wrong before attempting another fix.

## Supporting references

- Timing or flaky waits: `references/condition-based-waiting.md`
- Backward value tracing: `references/root-cause-tracing.md`
- Validation after root-cause repair: `references/defense-in-depth.md`

Do not propose a fix merely because it is common, easy, or similar to a past bug.
Report uncertainty and missing evidence plainly.

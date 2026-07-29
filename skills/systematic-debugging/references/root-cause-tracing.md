# Root-cause tracing

When a bad value appears deep in a call stack, trace it backward instead of
adding a guard at the failure site.

1. Record the first observable invalid state and the exact failing operation.
2. Identify the caller that supplied the value.
3. Repeat upward until reaching the first boundary where valid state became invalid.
4. Confirm the origin with a focused log, breakpoint, query, or test.
5. Repair that origin and verify both the original failure and adjacent callers.

If tracing crosses a service, process, queue, or database boundary, record both
the outgoing and incoming representation. Names that look equivalent do not
prove that serialization, identity, units, or defaults stayed equivalent.

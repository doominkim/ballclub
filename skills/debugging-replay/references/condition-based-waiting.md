# Condition-based waiting

Replace arbitrary sleeps with polling for the state the test or process actually needs.

- Define the observable condition and a bounded timeout.
- Poll at a modest interval and return as soon as the condition is true.
- On timeout, report the last observed state and relevant diagnostics.
- Keep the timeout as a safety bound, not the expected execution duration.

Do not use condition polling to hide an event or lifecycle contract that can be
awaited directly. Prefer the strongest deterministic completion signal available.

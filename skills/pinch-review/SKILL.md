---
name: pinch-review
description: Use when reviewing a migration, port, refactor, or any change to irreversible / money-touching / data-integrity behavior, before trusting it is correct. Complements final-out-verification (which proves the contract); pinch-review attacks the contract's hidden assumptions. Triggers on "port as-is", "matches the original", "same behavior", a cutover or deploy of ported logic, or an explicit request to red-team a change. Do not use for local, low-risk, forward-only changes with no inherited contract.
---

# Pinch Review

Send in a hitter off the bench whose job is to *break the at-bat for the author* —
to disprove the change, not confirm it. Call pinch-review when a change reproduces
or ports existing behavior, or touches irreversible / money / data-integrity paths,
where "it matches the original" is the wrong bar for correctness.

## When to send the pinch hitter

- A migration, port, or refactor whose success has been framed as "same output as
  before" / "matches the original."
- Changes to irreversible or money-moving paths (payments, refunds/cancels,
  balances, deletes, external side effects).
- Before a cutover or deploy that activates ported logic for real traffic.
- When someone claims done and final-out-verification passed, but the contract
  being verified is inherited from the thing being replaced.

Skip for local, low-risk, forward-only changes with no inherited contract.

## The stance: attack, don't confirm

Equivalence is not correctness. A faithful port of a buggy original passes every
equivalence check. Review against *correctness in itself*, independent of the
original — including "improvements" made during the port, which can break an
invariant the old code silently relied on.

## Attack moves

1. **Distrust the doc.** "Verified / complete / safe" in prose is a claim; confirm
   from code, data, or a fresh run.
2. **Challenge every stated mitigation** — "really? for which cases?" Name what is
   proven versus assumed, and leave the unproven explicit.
3. **Ask the invariant question** — what property did the old code *implicitly* rely
   on that this change drops? (e.g., autocommit that made a dedup marker durable, so
   wrapping it in one transaction now erases the marker on rollback.)
4. **Walk the failure paths** — timeout, crash / restart / deploy, deadlock or
   lock-timeout, retry, concurrency, rollback. Ask what happens in each, and whether
   a callback or re-query exists to recover an ambiguous outcome.
5. **Equivalence != correctness** — re-ask "is this safe on its own?", not "does it
   match the original?"
6. **Separate loud from silent failures.** Loud/safe: the user is harmed, complains,
   and it gets caught. Silent/dangerous: the house loses, nobody reports it, and it
   accumulates. Rank the silent ones up.
7. **Follow the money / blast radius** — not just frequency but per-event magnitude
   and who is exposed.
8. **Confirm with data** — turn a hypothesis into a query or probe against real state
   before believing it.
9. **Trace past incidents** — git log and incidents for "did this already break, and
   was only one target patched while others were left?"
10. **State blind spots honestly** — what you could not confirm (unpushed forks,
    deploy scope, external service behavior) is part of the finding, not an omission.

## Cross-model relief

Run the independent pass with a *different* model than the one that authored the
change — a different model does not share the author's blind spots. Hand a decision
packet to **Chief Coach (xhigh, read-only cross-model) by default**; use Coach for
lower-stakes reviews. Frame the packet with the attack moves above and the specific
invariant and failure questions — not "please review." Integrate the verdict; the
final judgment stays with the manager.

## Boundaries

- Do not accept "matches the original" as proof of correctness for ported or
  refactored logic.
- Do not confirm safety from the change's own author or model alone; require a
  cross-model or otherwise separate lane.
- Do not soften an unproven mitigation into a proven one; keep "which cases / which
  targets" explicit.
- Do not stop at loud failures; the silent, self-benefiting failures are the priority.
- This is a review lane, not authoring. Report the attack surface and unresolved
  risks; do not implement fixes in the same pass.

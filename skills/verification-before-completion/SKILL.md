---
name: verification-before-completion
description: Use immediately before claiming that work is complete, fixed, passing, deployed, or ready, especially before a commit, push, pull request, or handoff.
---

# Verification Before Completion

Success claims require fresh evidence from the state being handed off.

## Verification gate

Before claiming success:

1. Identify the command or observation that directly proves the requested outcome.
2. Run it after the final relevant change, not from memory or an earlier snapshot.
3. Inspect the exit status and complete meaningful output.
4. Confirm that the verification covers the user's actual contract, not a proxy.
5. Report what passed, what was not tested, and any remaining limitation.

Evidence is fresh when it was produced after the final relevant change and still
directly covers the current state. Reuse such evidence; do not rerun an unchanged
command merely because this skill was loaded later.

Use verification proportional to risk:

- Documentation or metadata: syntax, schema, links, and focused checks.
- Local behavior: focused tests plus nearby regression coverage.
- Shared interfaces: contract tests and affected consumers.
- Deployment: running artifact or commit plus the real protected route or workflow.

## Boundaries

- Do not say "done", "fixed", "passing", or equivalent before fresh evidence.
- Do not treat a successful build as proof of runtime behavior it does not exercise.
- Do not hide skipped tests, warnings, unavailable environments, or partial coverage.
- Do not automatically request code review or finish a branch; those are separate decisions.
- If verification fails, report the failure and continue diagnosis instead of softening the claim.

# Implementer brief

Provide these fields in plain language:

- **Outcome:** the behavior or artifact to deliver.
- **Ownership:** exact files, module, or responsibility boundary.
- **Context:** relevant contracts, existing patterns, and user decisions.
- **Constraints:** behavior that must not change and actions that are not authorized.
- **Verification:** focused commands or observations expected before handoff.

Always include:

> You are not alone in this codebase. Preserve other changes, do not revert work
> you do not own, and adjust your implementation to accommodate concurrent edits.

Ask the implementer to return changed files, verification output, and unresolved
risks. Do not ask it to review, commit, push, or make product decisions.

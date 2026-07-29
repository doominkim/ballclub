---
name: finishing-a-development-branch
description: Use when the user explicitly asks to finish, integrate, publish, merge, or wrap up work on a development branch or detached workspace.
---

# Finishing a Development Branch

Verify the branch, expose integration choices, and preserve recoverability.

## Workflow

1. Inspect `git status`, the current branch or detached HEAD, remotes, and recent commits.
2. Identify the likely base branch from repository evidence; ask if it is ambiguous.
3. Reuse directly relevant verification produced after the final change, or run
   fresh verification when that evidence is missing or stale.
4. Summarize commits, uncommitted changes, verification, and integration risks.
5. Present only safe applicable choices:
   - merge locally into the confirmed base branch;
   - push and create a pull request;
   - keep the branch or workspace as-is.
6. Wait for the user's explicit choice before committing, merging, pushing, or cleaning up.
7. After the chosen operation, verify the resulting branch, remote, or pull request state.

## Safety boundaries

- Never infer permission to commit, push, merge, rebase, or delete from a generic completion request.
- Never offer deletion as a routine completion option.
- Delete a branch or worktree only after an explicit discard request and confirmation.
- Never force-push unless the user explicitly requests that exact action.
- Preserve externally managed workspaces and worktrees you did not create.
- If verification or integration fails, stop with state intact and report the evidence.

This skill is not an automatic post-implementation step. It applies only to an
explicit branch-integration or publication request.

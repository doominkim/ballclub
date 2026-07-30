---
name: dispatching-parallel-agents
description: Use when the user explicitly requests parallel agent work, when independent bounded subtasks can run concurrently, or when large disposable research, investigation, audit, or verification context should be isolated from the main conversation.
---

# Calling Multiple Players

Send multiple players to bat only when independence, context isolation, or saved latency
outweighs coordination cost and merge risk.

For coding tasks that need implementation ownership, `subagent-driven-development`
is the primary workflow. This skill adds concurrency to implementation only when
the user explicitly requests parallel execution and both skills independently apply.

## Independence check

A subtask is safe to parallelize when it has:

- a concrete question or deliverable;
- a distinct file or responsibility boundary;
- enough context to complete without guessing;
- no dependency on another running task's result;
- no conflicting external mutation.

Keep tasks sequential when they touch the same files, diagnose the same root
cause, require a shared design decision, or mutate one deployment or data source.

## Context isolation

Isolation can justify one subagent even when there is no parallel speedup. Use
it when intermediate work is large or disposable, an investigation should avoid
the parent's conclusions, or the parent needs only a compact result.

Do not delegate small, tightly coupled, or stateful work that requires repeated
clarification. Delegation does not guarantee a clean context by itself; use the
host's minimal-context controls when available.

For an isolated plate appearance:

1. Pass only required constraints and raw artifacts.
2. Omit the parent's preferred answer when independence matters.
3. Request conclusions, evidence, risks, and relevant paths instead of an activity log.
4. Keep final synthesis and decisions in the parent agent.

## Set the batting order

1. Split work by outcome, not arbitrary file count.
2. Give each player an explicit plate appearance, ownership, and success criteria.
3. State that other agents may be working in the same repository and that it
   must preserve and accommodate their changes.
4. Provide only the context needed for its task; avoid leaking a desired conclusion.
5. Continue useful local work that does not duplicate a delegated task.
6. Collect all appearances before making an integration claim or official score.

Validate overlaps, contradictions, and combined behavior after results return.
Parallel agent completion is not integration verification.

Do not create reviewer, planner, or worktree roles automatically. Those require
their own independently applicable skill or explicit user request.

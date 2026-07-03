# premier: Orchestrator Mode - Design

Date: 2026-07-03
Status: approved, pending implementation plan

## Problem

premier today is two one-shot skills invoked in sequence.
`design` decomposes a task and writes one row to Notion, then ends.
`premier` reads Notion and batch-executes the task in worktrees with auto-review and auto-merge, then ends.
Each `premier` invocation is a run that starts, executes, and dies.

The user does not want two doors he opens in turn.
He wants a single persistent mode: he enters "orchestrator mode" and then just talks to a main thread.
That thread accepts a stream of tasks over time, decomposes and dispatches each, and stays available to converse.
Crucially, the main thread must never do the work itself - it dispatches, coordinates, reports.
Today the thread often goes off and does work inline instead.

The derived constraint the user raised: context pollution.
A persistent thread and a clean context pull in opposite directions.

## Model: three levels

The design resolves the persistent-chat vs clean-context tension by splitting into levels.

**L1 - Orchestrator (the chat you talk to).**
Thin. Long-lived. Sole interface to the human.
Its context holds only the current conversation plus a compact ledger (one status line per task).
It never runs git, review, or merge itself.
When asked for status it reads Notion, not its own memory.
When its own context gets heavy it can drop old conversation and rehydrate the ledger from Notion.

**L2 - Execution (one isolated context per task).**
This is the "session per task."
The full premier pipeline (worktrees, crewmates, review sub-agents, auto-fix, merge) runs in a context that is born and dies with the task.
All diff noise stays here.
Only a compact status flows up to L1, plus a Notion write-back.
L2 is headless and mute: it never talks to the human directly.

**Ledger - Notion plus a light local log.**
The through-line memory and continuity.
Execution detail is discarded when a task completes; task status lives in Notion permanently.
L1 is essentially a thin shell over this ledger.

How the levels satisfy both wants:
- "Continuous chat" = L1 lives long and is always with you.
- "Session per task, details discarded" = L2, an isolated context per task.
- Throw a task, L1 decomposes it, writes a Notion row, hands execution down to L2, and is immediately free for the next message.

## Decomposition stays at L1

Decomposition and the need for clarification are the same place.
Task ambiguity surfaces exactly when you break the task down.
So "can L2 decompose" and "will L2 interrupt L1 for clarification" are one question: wherever decomposition lives, questions to the human come from there.

Decomposition therefore lives at L1, where the human already is.
Breaking a task down is the interactive "design" capability.
All clarifications happen naturally in the chat, before anything is handed down.
Once the task is fully specified (phases/subtasks/accept written to Notion), it goes to L2 headless.

This dissolves the session-switching problem:

> L1 is the single interface to the human.
> L2 never speaks to you directly - no questions, no reports bypassing L1.
> You are always in one chat. There is no "go into task Y's session, a question is waiting there."

This preserves premier's current division of labor: `design` = interactive decomposition with the human, `premier` = headless execution.
It is repackaged as two capabilities of one persistent orchestrator rather than two separate invocations.

**Unforeseeable ambiguity mid-execution.**
When an unknown could not be seen at decomposition time and surfaces mid-run, graceful degradation with no interactivity from below:
L2 blocks the subtask (`blocked: reason`) and returns.
L1 reports it to you.
You answer in L1.
L1 launches a continuation (either send the instruction into the same branch, or a fresh short L2 with the added context).
You never leave L1.

## Task lifecycle

1. You throw into chat: "do X for web-remarq".
2. L1 decomposes the task with you (design capability): phases/subtasks/accept, asking about ambiguity right there. The heavy part of the breakdown may be pushed to a design sub-agent so only the final plan lands in L1.
3. L1 writes one task row to Notion (spec block in the body, as today).
4. L1 hands execution down to L2 and is immediately free. L1 context keeps one line: `X -> launched, 3 subtasks`.
5. L2 runs the full pipeline in its own context: worktree crewmates, review sub-agents, auto-fix, merge to integration, final merge. None of this flows into L1.
6. L2 finishes, returns a compact summary to L1 and writes `Status`/`Result` to Notion. L1 shows you: `X done: 5 files, merged` or `X: subtask Y blocked - reason`.
7. You throw the next thing, or ask for status (L1 reads Notion).

## Parallelism and status

Several tasks may be in flight in the background at once (the crewmate limit of 5 stays).
"How is everything?" -> L1 reads the board, not memory.
L1 is not required to remember statuses; it re-reads them from Notion.
So even if L1's context collapses (compaction), it rehydrates from the board and loses nothing.
This is the "session per task plus ledger": L2 detail dies with the task, status in Notion lives on.

## What changes in the skill files

- New entry point - orchestrator mode (a reframed `premier`): not a one-shot run, but entering the L1 loop "accept tasks -> decompose -> dispatch -> report."
- `design` stops being a separate door - it becomes an internal L1 capability (lifecycle step 2). You no longer call `/design` then `/premier` in turn.
- The current `Algorithm` (premier steps 1-8) moves into an "execute one task" routine = the body of L2. The pipeline logic is untouched; what changes is who runs it and in which context.

## What does not change

Pipeline internals stay as-is: worktree naming, integration branch, review agents, auto-fix (2 attempts), merge policy, Notion status write-back, the limit of 5, 429 back-off.

## Open technical risk (resolve first in the plan)

How exactly to isolate L2 is the one unknown.

- **L2a:** L2 is a single background coordinator agent per task that runs the whole pipeline in its own context. Cleanest possible L1 context. Requires that a background agent can itself spawn background crewmates and receive wake-on-completion - nested background agents, which the harness may not support.
- **L2b:** L1 drives the pipeline itself but offloads every heavy step (review, merge) into sub-agents, and flushes its context from the Notion ledger between tasks. No nesting required, but compact per-subtask summaries accumulate in L1.

Target **L2a**, with **L2b as a guaranteed fallback**.
Which is possible is the first thing to verify empirically in the plan.

## Success criteria

- Entering orchestrator mode once yields a persistent chat that accepts a stream of tasks.
- Throwing a task decomposes it interactively at L1, writes it to Notion, dispatches execution, and returns control to the chat without the thread going off to code inline.
- After a task is dispatched, L1's context growth for that task is bounded to the request plus compact status lines - no diffs, no git output, no review transcripts.
- Status questions are answered from Notion, so L1 survives compaction by rehydrating from the board.
- L2 never prompts the human; blockers come back through L1 as reports the human acts on.

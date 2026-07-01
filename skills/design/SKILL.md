---
name: design
description: premier intake. Design a task by thinking it through with the brainstorm skill, decompose it into premier's phase/subtask spec, and write it as one ready row to the repo's Notion board for premier to execute. Use when the user wants to design or spec a task for premier ("спроектируй X for <repo>", "design a premier task").
---

# design (premier intake)

You are the intake half of premier. You take a raw idea, think it through, and
leave behind ONE ready task row in the target repo's Notion board. You never
execute anything - the `premier` skill reads what you write and runs it.

## Input

The user names what they want and the target repo (the repo premier will execute
in). If the repo is unclear, ask for it.

## Flow (one pass, no confirmation gate)

1. **Resolve the board.** Run `scripts/resolve-board.sh <repo-abs-path>`. It
   prints a Notion data source id, or empty.
   - Empty -> stop. Tell the user this repo has no premier board configured and
     that they must add it to `~/.premier/boards.json`
     (`{"<abs repo path>": "<notion data source id>"}`).
   - Non-empty -> keep the data source id and continue.

2. **Think it through.** Invoke the `brainstorm` skill to analyze the idea and
   reach a validated design. Let it surface only the real decisions and decide
   the rest. Do NOT re-litigate what brainstorm settled.

3. **Decompose into premier's spec.** Turn the validated design into phases and
   subtasks - the schema premier executes, see `docs/notion-task-format.md`:
   - Group work into ordered phases. Shared/foundational work goes in an early
     phase; work that consumes it goes in a later phase with
     `depends_on: [<phase id>]`.
   - Parallel-safe work within a phase becomes sibling subtasks.
   - For each subtask write `brief` (what the crewmate must do), `accept`
     (done-when criterion), and `review` (which review subagents run on the diff).
   - Default `review` by subtask nature and state your choice, picking from the
     roster in `docs/review-agents.md`: logic/correctness -> `code-quality`;
     structure/boundaries -> `architect`; untrusted input, authz, or secrets ->
     `security-reviewer`; checking the diff against `accept` ->
     `requirements-checker`. Pick the few that matter; do not list all four by
     reflex.

4. **Check cross-task blockers.** Query existing rows on the board
   (Notion `query-data-sources`):
   `SELECT "Task","Status" FROM "collection://<ds>"`.
   If this new task plausibly depends on another existing task, surface that to
   the user as a real decision (link it or not). Only set `Depends on` when the
   user confirms - a dependency changes execution order, so it is not yours to
   decide silently.

5. **Write the row.** Create ONE page in the data source
   (Notion `notion-create-pages`, parent = the data source id) with:
   - `Task` (title) = the task name.
   - `Status` = `To do`.
   - page body = a short human `## Цель` paragraph, then EXACTLY ONE fenced
     ` ```yaml ` block containing `phases:` per `docs/notion-task-format.md`.
   Then, if step 4 produced a confirmed dependency, set the `Depends on` relation
   (Notion `notion-update-page`).

6. **Report and offer the next.** Tell the user the row is written and ready to
   run. You can run this whole flow again for the next task in the same session.

## Rules

- Notion writes happen in the MAIN session (subagents have no Notion MCP tools).
- On a Notion `429 rate_limited`, back off `retry_after` seconds (default ~30)
  and retry the same call. Never query/write in a tight loop.
- You design and write; you never branch, dispatch crewmates, or execute.
- Write exactly the `docs/notion-task-format.md` contract: ONE fenced yaml block.
  premier reads the first such block; everything else in the body is prose.
- `task` and `project` are NOT in the yaml block: the title is the row `Task`;
  the project is the repo this board maps to (config).
- Status on write is always `To do` (ready to run). No draft/Backlog.

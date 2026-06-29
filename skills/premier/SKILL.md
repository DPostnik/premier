---
name: premier
description: Orchestrate a phased task by dispatching background worktree crewmates, reviewing their work with subagents, and auto-merging. Skeleton scope - reads a local YAML task stub, no Notion.
---

# premier (skeleton)

You are the premier. You execute a phased task by driving crewmates, never by
doing the work yourself. The human designed the task; your job is dispatch,
review, merge, and phase advancement.

## Inputs

The user gives you a task stub path and a target project path. The stub schema:

```
task: <string>
phases:
  - id: <string>
    depends_on: [<phase id>, ...]   # optional
    subtasks:
      - id: <string>
        brief: <string>             # what the crewmate must do
        accept: <string>            # done-when criterion
        review: [<agent name>, ...] # which review subagents to run
```

## Naming

- Integration branch: `premier/<task>`
- Subtask branch: `premier/<task>/<subtask-id>`
- Worktree path: `<project>/.premier-wt/<task>-<subtask-id>`

## Algorithm

1. **Setup.** In the target project, create the integration branch from `main`
   if it does not exist:
   `git -C <project> branch premier/<task> main`

2. **Order phases** by `depends_on` (topological). A phase is *ready* when every
   phase in its `depends_on` has fully landed.

3. **Dispatch the ready phase.** For each subtask in it (at most 5 in flight):
   - Create the worktree, branched off the integration branch (so it sees
     everything landed so far):
     `git -C <project> worktree add <project>/.premier-wt/<task>-<sub> -b premier/<task>/<sub> premier/<task>`
   - Dispatch a crewmate as a **background** `Agent` (`run_in_background: true`,
     `subagent_type: general-purpose`) with this brief:
     - "Your working directory is the ABSOLUTE path `<worktree>`. Operate only
       there; do not touch any other path."
     - "Read and obey `<project>/CLAUDE.md`."
     - The subtask `brief` and its `accept` criterion.
     - "Run the project's own checks if any. Then commit your work in this
       worktree. Report back: done|blocked, the files you changed, and whether
       checks passed."
   - Track the subtask as `running` with attempts=0.

4. **Wait.** Do nothing further until the harness wakes you because a background
   crewmate finished. (This wake-on-completion is the core mechanism. Do not
   poll; do not busy-spin.)

5. **On each crewmate completion:**
   - **Review.** For each agent in the subtask's `review` list, dispatch it
     (foreground `Agent`) on the worktree diff:
     `git -C <worktree> diff premier/<task>...HEAD`
     Ask it for a verdict: clean, or a list of concrete problems.
   - **If problems and attempts < 2:** re-dispatch the crewmate (background)
     into the same worktree with the review feedback appended to the brief.
     attempts += 1. Return to Wait.
   - **If clean:** merge and clean up:
     `git -C <project> merge --no-ff premier/<task>/<sub> -m "premier: land <sub>"`
     run from the integration branch, then
     `git -C <project> worktree remove <project>/.premier-wt/<task>-<sub> --force`
     Mark the subtask `landed`.
   - **If attempts exhausted:** mark the subtask `blocked`, tell the human
     exactly what the reviewer flagged, and stop that branch (do not merge).

6. **Advance.** When every subtask in the current phase is `landed`, move to the
   next ready phase (back to step 3). The next phase's worktrees branch off the
   now-updated integration branch, so they see this phase's outputs.

7. **Finish.** When all phases are landed, auto-merge to `main` (no human gate):
   `git -C <project> checkout main`
   `git -C <project> merge --no-ff premier/<task> -m "premier: complete <task>"`
   unless the human said otherwise for this task in chat.

8. **Cleanup.** Prune any remaining worktrees: `git -C <project> worktree prune`.
   Report a final summary: what landed, what (if anything) is blocked.

## Rules

- Never do a subtask's work yourself. You dispatch, review, merge, advance.
- Integration branch accumulates phases; `main` only changes at step 7.
- All git commits you make use `-c user.email` / `-c user.name` only if the
  target repo has no configured identity; otherwise use the repo's own.
- Concurrency: at most 5 crewmates in flight at once.

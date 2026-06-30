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

## Task source (Notion vs YAML)

Given the target project path, resolve its board:
`scripts/resolve-board.sh <project>` prints a Notion data source id, or empty.

- Non-empty -> Notion mode (this section + Status write-back below).
- Empty -> YAML mode: read the local stub the user named, exactly as in the
  core Algorithm. Nothing else in this section applies.

## Notion mode

On `запускай` (the user says "запускай" / "launch" / "go"):

1. Query ready tasks from the data source (Notion `query-data-sources`, SQL):
   `SELECT url, "Task", "Depends on" FROM "collection://<ds>" WHERE "Status" = 'To do'`
2. Build the cross-task graph from `Depends on`: a task is runnable only when
   every task it depends on is already `Done`. Tasks with an unfinished
   dependency stay queued (do not start them; see write-back for `Blocked`).
3. For each runnable task, fetch its page (Notion `fetch`) and extract the FIRST
   fenced ```yaml block from the body. Parse its `phases:` - this is the same
   phase structure the YAML stub uses. The `Task` title is the `<task>` name;
   the project is this board's repo.
4. Run each task through the SAME core Algorithm (steps 1-8: integration branch,
   worktrees, dispatch, wait, review, auto-fix, merge, phase barrier, final merge
   to `main`). Nothing in the loop changes; only the source of the spec differs.
5. Respect the cross-task limit of 5 crewmates in flight across all running tasks.

## Status write-back (Notion mode only)

Update the task's Notion page (Notion `update-page`) at these transitions:

- A task is picked up for execution -> set `Status = In Progress`.
- A task's final merge to `main` succeeds -> set `Status = Done` and write the
  crewmate summary into `Result`.
- A task cannot start because a dependency is not yet `Done`, OR a subtask is
  stuck after the 2 auto-fix attempts -> set `Status = Blocked` and put the
  reason in `Result`.
- Total give-up -> set `Status = Failed`.

After any task reaches `Done`, re-evaluate the queued tasks: any whose
dependencies are now all `Done` become runnable (back to step 3).

## Naming

- Integration branch: `premier/<task>/_integration`
- Subtask branch: `premier/<task>/<subtask-id>`
- Worktree path: `<project>/.premier-wt/<task>-<subtask-id>`

Git stores refs as files under `refs/heads/`, so a ref cannot also be a
directory of other refs. The integration branch is therefore a sibling leaf
`premier/<task>/_integration`, never `premier/<task>` itself - otherwise
`premier/<task>/<subtask-id>` cannot be created.

## Algorithm

1. **Setup.** Check out the integration branch in the target project's main
   working tree, created from `main` if absent:
   `git -C <project> switch -c premier/<task>/_integration main`
   (or `git -C <project> switch premier/<task>/_integration` if it already
   exists). Subtask branches merge INTO this checked-out branch; `main` is only
   touched at step 7.

2. **Order phases** by `depends_on` (topological). A phase is *ready* when every
   phase in its `depends_on` has fully landed.

3. **Dispatch the ready phase.** For each subtask in it (at most 5 in flight):
   - Create the worktree, branched off the integration branch (so it sees
     everything landed so far):
     `git -C <project> worktree add <project>/.premier-wt/<task>-<sub> -b premier/<task>/<sub> premier/<task>/_integration`
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
     `git -C <worktree> diff premier/<task>/_integration...HEAD`
     Ask it for a verdict: clean, or a list of concrete problems.
   - **If problems and attempts < 2:** re-dispatch the crewmate (background)
     into the same worktree with the review feedback appended to the brief.
     attempts += 1. Return to Wait.
   - **If clean:** merge into the integration branch (the main tree is on it)
     and clean up:
     `git -C <project> merge --no-ff premier/<task>/<sub> -m "premier: land <sub>"`
     then
     `git -C <project> worktree remove <project>/.premier-wt/<task>-<sub> --force`
     Mark the subtask `landed`.
   - **If attempts exhausted:** mark the subtask `blocked`, tell the human
     exactly what the reviewer flagged, and stop that branch (do not merge).

6. **Advance.** When every subtask in the current phase is `landed`, move to the
   next ready phase (back to step 3). The next phase's worktrees branch off the
   now-updated integration branch, so they see this phase's outputs.

7. **Finish.** When all phases are landed, auto-merge to `main` (no human gate):
   `git -C <project> switch main`
   `git -C <project> merge --no-ff premier/<task>/_integration -m "premier: complete <task>"`
   unless the human said otherwise for this task in chat.

8. **Cleanup.** Prune any remaining worktrees: `git -C <project> worktree prune`.
   Report a final summary: what landed, what (if anything) is blocked.

## Rules

- Never do a subtask's work yourself. You dispatch, review, merge, advance.
- Integration branch accumulates phases; `main` only changes at step 7.
- All git commits you make use `-c user.email` / `-c user.name` only if the
  target repo has no configured identity; otherwise use the repo's own.
- Concurrency: at most 5 crewmates in flight at once.

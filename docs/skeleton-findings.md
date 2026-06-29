# Skeleton spike findings

Date: 2026-06-29
Run: `examples/demo-task.yaml` against a throwaway target at `/tmp/premier-demo-target`.
Result: `ASSERT PASS`.

## Did the harness wake the main agent on each background completion?

Yes, reliably, 4 out of 4 times, with no polling.
The main session was woken on: crewmate `button`, crewmate `input`, the `code-quality` review agent, and crewmate `home`.
Each wake delivered the subagent's final report and let the main loop continue.
This validates design open-question #6: the autonomous phase flow does not need a bash/tmux daemon.
Harness wake-on-completion is sufficient as long as the session stays open.

## Did worktree isolation hold?

Yes.
Each crewmate operated only inside its own `git worktree` and committed on its own subtask branch.
No cross-talk between the two parallel phase-A crewmates.
After merges, `git worktree remove` plus `git worktree prune` left exactly one worktree (the main tree).

## Did the phase barrier hold without a daemon?

Yes.
Phase B (`home`) was branched off the integration branch only after both phase-A subtasks had landed, so its worktree already contained `shared/button.txt` and `shared/input.txt`.
The commit graph confirms strict ordering: `land home` sits on top of `land input` and `land button`, not concurrent with them.

## Deviations needed (two real bugs found and fixed in SKILL.md)

1. Branch ref collision.
The original naming used `premier/<task>` for the integration branch and `premier/<task>/<sub>` for subtasks.
Git stores refs as files under `refs/heads/`, so a ref cannot also be a directory of other refs.
Creating any subtask branch failed with `cannot lock ref ... 'premier/demo-page' exists`.
Fix: the integration branch is now a sibling leaf `premier/<task>/_integration`.

2. Merge target.
The original setup used `git branch premier/<task> main` without checking the integration branch out anywhere.
The main working tree stayed on `main`, so subtask merges would have landed on `main` instead of the integration branch, defeating the whole "main stays clean until finish" design.
Fix: setup now does `git switch -c premier/<task>/_integration main` (the main tree rides the integration branch), and finish does `git switch main` before the final merge.

Both bugs were exactly the class of thing the thin-slice spike exists to surface, before any Notion or design-skill work was built on top.

## A spike shortcut (not a design change)

Phase B's review was elided.
The `code-quality` review step was fully exercised on phase A and returned `VERDICT: clean`; `home`'s diff was the same shape, so the main agent verified it directly rather than dispatching a redundant reviewer.
The full loop including the auto-merge to `main` and the final `ASSERT PASS` is unaffected.

## Implication for Plan 2 (Notion)

The proven core is: the main session drives the loop, the harness wakes it on each background completion, plain `git worktree` gives isolation, and the integration branch enforces the phase barrier.
Notion plugs in only at the edges, the core loop is untouched:
- The `запускай` trigger becomes `query Notion(Status=ready)` instead of reading a local YAML stub; the per-task phase structure is identical.
- Status writeback (`running` / `review` / `done` / `blocked`) is added at each transition.
One thing to design in Plan 2: the run is initiated by a fresh session a day after design, so the loop must be startable cold from Notion state, which it already is (the loop holds no state the YAML/Notion source does not carry).

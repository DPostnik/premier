# Orchestrator-mode findings

Live seam run of the reframed premier skill (orchestrator mode) against the demo target, YAML mode.
Plan: `docs/superpowers/plans/2026-07-03-orchestrator-mode.md`. Date: 2026-07-03.

## Did execution survive the reframe?

Yes. `scripts/assert-demo-result.sh` -> `ASSERT PASS`.
The main session drove `examples/demo-task.yaml` (2 phases, 3 subtasks) through the renamed `## Execute one task` body:

- Phase A dispatched two crewmates in parallel (button, input) in separate worktrees.
- Each completion triggered a code-quality review agent, then a `--no-ff` merge into the integration branch and a worktree removal.
- Phase B's worktree branched off the updated integration branch and correctly saw Phase A's outputs (`shared/button.txt`, `shared/input.txt` present before home was written) - the phase barrier held.
- Final `--no-ff` merge of the integration branch to `main` landed all three files; worktrees pruned.

Renaming `## Algorithm` to `## Execute one task` and rewording the Review bullet changed no mechanics - the pipeline behaved identically to the proven skeleton.

## What actually accumulated in L1's context

The reason for the reframe. Per subtask, the main session (L1) accumulated only:

- the crewmate's final report: 1-3 lines (`done`, file created, no checks).
- the review agent's verdict: 1 line (`clean`).
- the merge command's `--stat`: 1-3 lines (driven by L1's own git call).

No diffs entered L1. The review agents ran `git ... diff ...` in THEIR own contexts and returned only `clean` - the verdict-not-the-diff wording (Task 3) works as intended.
Total L1 growth for the whole 3-subtask task was roughly a dozen lines of compact summaries. This is the bounded, disposable accumulation the L2b design predicted, not the pristine-zero of the rejected L2a.

## Friction / follow-ups

- Merges were driven by L1's Bash calls, so their (small) `--stat` output lands in L1. Acceptable - it is git's own summary, not a diff - but it is the largest single L1 contributor per subtask. If ever a concern, the merge could move behind a subagent, at the cost of the nesting risk L2b deliberately avoids.
- This run was YAML mode, so intake (decompose + Notion row) and status write-back were not exercised here. Intake is covered separately by `scripts/assert-design-seam.sh` against a Notion-configured repo; the persistent-loop intake path (loop step 2) still needs one live Notion-mode run to confirm end to end.
- The persistent loop itself (throwing a second task mid-flight, status-on-demand rehydrate from Notion) was not exercised by this single-task seam - it needs a live multi-task session to confirm behaviorally.

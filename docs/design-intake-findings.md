# Design intake spike findings

Date: 2026-07-01
Run: `design` authored a task on board `collection://43bcba00-...` -> `premier` executed it against `/tmp/premier-seam-demo`.
Result: `ASSERT PASS` + the design-authored row reached `Done` with `Result` populated.

## How the spike was run

As in the Plan 1/2 spikes, the top-level session acted as each skill: it followed
`skills/design/SKILL.md` to author the row, then `skills/premier/SKILL.md` to
execute it. The row was NOT hand-edited between the two halves - premier consumed
exactly what design wrote.

## Did `design` resolve the board correctly?

Yes.
`resolve-board.sh /tmp/premier-seam-demo` returned the data source id, so design
took the Notion path and wrote there. The unconfigured-refuse branch was not
re-tested live in this run; it is the proven empty-return behavior of
`resolve-board.sh` (Plan 2, Task 1), which design keys off directly.

## Did invoking `brainstorm` from `design` behave?

Yes, for a no-fork idea.
The seam idea ("create greeting.txt whose only line is HELLO") has no material
decisions, so the brainstorm step asked nothing and design decided the details
and stated them. The `brainstorm` skill stayed premier-agnostic (it contains no
Notion/phase/crewmate/premier terms - verified 0 by grep in Task 1). A richer,
genuinely forked idea was not exercised here; the question-threshold behavior on
real forks is still only proven by the skill text, not by a spike.

## Did `design` emit exactly the contract?

Yes.
A fetch of the created row (before running premier, unedited) showed: `Status=To do`;
body = a human `## Цель` paragraph plus exactly ONE fenced ```yaml block with
`phases:`; the single subtask had `brief`, `accept`, `review: [requirements-checker]`;
no `Depends on` set (correctly - the task is standalone). This is exactly the
`docs/notion-task-format.md` contract that premier reads.

## Did `premier` consume it unedited to Done?

Yes.
premier queried `Status='To do'` (picked up the seam-demo row; the Plan-2 `Done`
and `Backlog` rows were excluded), set `In Progress`, branched an integration
branch + worktree, dispatched a crewmate that wrote `greeting.txt`, ran
`requirements-checker` (verdict CLEAN), merged to the integration branch, then
merged to `main`, and wrote back `Done` + a `Result` summary.
`assert-design-seam.sh /tmp/premier-seam-demo greeting.txt HELLO` -> `ASSERT PASS`.

## Format friction / deviations

- No structural deviation from either SKILL.md.
- The Notion `query-data-sources` call hit a 429 rate limit TWICE during this run
  (both `retry_after: 30`); a ~35s back-off + retry cleared each. This is the
  third 429 across Plans 2-3. It never affected correctness, but it is now clearly
  worth a one-line rule in `premier`/`design` SKILL.md: on 429, back off
  `retry_after` seconds and retry; do not query in a tight loop.
- Task slug for git refs: the row title "Seam demo: greeting file" cannot be a git
  ref, so premier used the slug `seam-demo` for `premier/seam-demo/...` branches.
  Slugifying the title for branch names should be stated explicitly in the premier
  SKILL.md naming section (currently it assumes `<task>` is already ref-safe).

## Verdict

The intake -> execution loop is CLOSED. A task designed and written by `design`
runs end to end through `premier` with no manual bridging. Premier Plans 1-3 are
complete and proven.

Follow-ups (backlog):
- Package the `brainstorm` dependency for premier distribution (or bundle a copy),
  so third parties get a working `design`.
- Add the 429 back-off rule to the SKILL.md (Notion-touching steps).
- Add a title -> ref-safe slug rule to the premier naming section.
- Exercise `design` on a genuinely forked idea to prove the question-threshold in
  practice, not just in the skill text.

# Notion layer spike findings

Date: 2026-06-30
Run: Notion-driven, board `collection://43bcba00-fef7-4c3f-8e42-69fa2c2045e6` -> target `/tmp/premier-notion-demo`.
Result: `ASSERT PASS` + Notion statuses written back correctly.

## Did Notion mode select correctly via the config resolver?

Yes.
`~/.premier/boards.json` mapped `/tmp/premier-notion-demo` to the board, and `resolve-board.sh` returned the data source id, so premier took the Notion path.

## Did the cross-task `Depends on` ordering hold?

Yes, and this is the key new thing Plan 2 adds.
`Build Home page` depended on `Build shared Button component`.
premier ran Button first (no deps), merged it to `main`, then branched Home's integration off the updated `main` - so Home's worktree already contained `shared/button.txt`.
The commit graph confirms `complete home` sits on top of `complete button`.
Home referencing the dependency's output is the proof the dependency was actually delivered, not just sequenced.

## Did status write-back land correctly?

Yes.
Final board state: Button = `Done` (Result populated), Home = `Done` (Result populated), `Polish footer spacing` = `Backlog` (untouched).
Transitions exercised: `To do` -> `In Progress` (on pickup) -> `Done` (+ Result on merge).
The `Backlog` decoy was correctly excluded by the `Status = 'To do'` query and never touched.

## Did the yaml-block parse cleanly from the page body?

Yes.
`fetch` returned the body with the fenced ```yaml block intact; the `phases:` structure read exactly like the local YAML stub.
No format fragility observed. The B1 decision (one fenced yaml block) gives a clean, deterministic contract.

## Deviations from SKILL.md

None structural.
Two operational notes:
- The Notion SQL `query-data-sources` hit a 429 rate limit once (`retry_after: 30`). It did not affect correctness, but a real premier run should back off and retry on 429, and avoid querying in a tight loop. Worth a one-line rule in SKILL.md later.
- Per-task review was elided for these trivial single-file diffs (same spike shortcut as Plan 1); the review mechanism itself is already proven.

## Implication for Plan 3 (the `design` skill)

The Task-2 contract is sufficient: the `design` skill must write a Notion task as a row (Title, Status=`To do` when ready, `Depends on` for cross-task blockers) whose page body contains exactly one fenced ```yaml block with `phases:`.
premier consumes that with no extra hints.
Plan 3 can treat "emit this row + body" as its terminal output, and everything downstream (launch, execute, write-back) is now proven.
Add to the premier backlog: a 429 back-off rule for the Notion query.

# Live e2e findings (web-remarq)

Date: 2026-07-01
Run: full `design` -> `premier` cycle on a LIVE repo (`web-remarq`, board
`collection://e91e8fe3-...`), review-only mode (leave the integration branch, do
not touch the default branch).

## What ran

`design` (acting inline) took the idea "cloud-0.3.0 first slice" and, via the
`brainstorm` skill, scoped a whole roadmap milestone down to one shippable task:
the quality-gate data contract + a BYOK, text-only `preflightCheck` in
`@web-remarq/cloud`, no UI/modes/MCP/vision. It wrote one `To do` row to the board.

`premier` (acting inline) then ran that row unedited through the core loop:
- Phase A (`quality-type`): `QualityCheck` type + `Annotation.qualityCheck` in core. tsc clean. Reviews code-quality + requirements-checker -> CLEAN. Landed.
- Phase B (`preflight-fn`): `preflightCheck` + tests in cloud (npm install, vitest 30 pass). Reviews requirements + security -> CLEAN; code-quality flagged a [High] `res.ok` gap (provider/auth errors masked as "could not parse"). Auto-fix attempt 1: errors now surfaced distinctly + default-client tests added -> re-review CLEAN. Landed.

Result: 4 files, +406 lines on `premier/cloud-0-3-0-quality-gate-slice-1/_integration`. Default branch (`master`) untouched. Notion row set to `Done` with a Result noting it is on the branch, awaiting review.

**The auto-review + auto-fix loop worked on real code** - the whole reason the
system exists - not just on the throwaway seam demo.

## Findings the live repo surfaced (that the test board could not) - all FIXED

1. **Hardcoded `main`.** web-remarq's default branch is `master`. premier
   hardcoded `main` in setup/finish. FIX: detect `<base>` via
   `git symbolic-ref refs/remotes/origin/HEAD` (fallback to the checked-out
   branch); all merge/branch steps use `<base>`. (premier SKILL.md)
2. **`Depends on` column may be absent.** web-remarq's board has no `Depends on`
   relation; premier's `SELECT ... "Depends on"` would error. FIX: check the data
   source schema; omit the column when absent and treat tasks as standalone.
   (premier SKILL.md)
3. **"Run all To do" is dangerous on a shared board.** The board held two
   human-authored `To do` rows (no yaml spec) alongside the designed one; premier
   would have tried to run them. FIX: SKIP any `To do` row whose body has no
   fenced yaml `phases:` block - only premier-designed rows are runnable.
   (premier SKILL.md)
4. **Package-name assumption.** design assumed `@web-remarq/core`; the real name
   is `web-remarq` (core subpath `web-remarq/core`). FIX: design must read real
   `package.json` names / imports / layout before naming them in briefs.
   (design SKILL.md)
5. **Accept-criterion gap.** Phase A's accept said "exported from
   `types.ts`" - literally true, but the type was NOT in the package's public
   barrel, so `import { QualityCheck }` failed by name (the crewmate worked around
   it via `NonNullable<Annotation['qualityCheck']>`). FIX: design writes `accept`
   as an observable, usable outcome ("imports by name", "test passes"), not mere
   presence in a file. (design SKILL.md)
6. **Monorepo build order.** cloud typecheck needs core's `dist` built first
   (gitignored, absent in a fresh worktree). FIX: the crewmate brief tells it to
   build a needed sibling workspace package before running its checks.
   (premier SKILL.md)

## Still open (for the human review of the branch)

- Add `QualityCheck` to core's public barrel export (one line) so the cloud
  workaround can be dropped.
- `res.ok` product decision confirmed: pre-flight never breaks submit; provider
  errors surface in `issues` rather than propagating. Already implemented.

## Verdict

The intake->execution system runs on a real, active monorepo and its auto-review
+ auto-fix loop caught and fixed a real defect before landing. The six rough
edges above were exactly the value of running live; all are now closed in the
skills. premier is meaningfully closer to "reliable on an arbitrary live repo".

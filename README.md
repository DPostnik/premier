# premier

Design your tasks; hand off execution. Premier spawns background crewmates in
isolated git worktrees, reviews their work with subagents, and auto-merges -
so you stay in design, not in review.

> Status: Intake + execution proven. `design` (intake) writes tasks to a Notion
> board; `premier` (execution) runs them in worktrees with auto-review and
> auto-merge.
>
> Note: `design` invokes a general `brainstorm` skill expected at
> `~/.claude/skills/brainstorm/` (kept separate so it is reusable outside
> premier). Until it is packaged, that skill is a dependency, not bundled here.

## Try the skeleton

    ./scripts/setup-demo-target.sh /tmp/premier-demo-target
    # then, in a Claude Code session with this plugin loaded, tell premier:
    #   "run the skeleton on examples/demo-task.yaml against /tmp/premier-demo-target"
    ./scripts/assert-demo-result.sh /tmp/premier-demo-target   # expect: ASSERT PASS

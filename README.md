# premier

Design your tasks; hand off execution. Premier spawns background crewmates in
isolated git worktrees, reviews their work with subagents, and auto-merges -
so you stay in design, not in review.

> Status: SKELETON. Proving the core orchestration loop on a local task stub.
> Notion task storage and the `design` intake skill come next.

## Try the skeleton

    ./scripts/setup-demo-target.sh /tmp/premier-demo-target
    # then, in a Claude Code session with this plugin loaded, tell premier:
    #   "run the skeleton on examples/demo-task.yaml against /tmp/premier-demo-target"
    ./scripts/assert-demo-result.sh /tmp/premier-demo-target   # expect: ASSERT PASS

# premier

Enter orchestrator mode once and stay. Throw tasks at a persistent main thread;
for each one it decomposes the task with you, spawns background crewmates in
isolated git worktrees, reviews their work with subagents, and auto-merges - so
you stay in design, not in review, without ever leaving the chat.

> Status: Persistent orchestrator mode. One continuous session intakes tasks
> (decompose + write a Notion row), then runs each through background worktree
> crewmates with auto-review and auto-merge. Execution detail stays in subagents;
> task status lives in the Notion board and is rehydrated after compaction.
>
> Note: intake invokes a general `brainstorm` skill expected at
> `~/.claude/skills/brainstorm/` (kept separate so it is reusable outside
> premier). Until it is packaged, that skill is a dependency, not bundled here.

## Try the skeleton

    ./scripts/setup-demo-target.sh /tmp/premier-demo-target
    # then, in a Claude Code session with this plugin loaded, tell premier:
    #   "run the skeleton on examples/demo-task.yaml against /tmp/premier-demo-target"
    ./scripts/assert-demo-result.sh /tmp/premier-demo-target   # expect: ASSERT PASS

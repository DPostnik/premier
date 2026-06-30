# Notion task format

Each row in a repo's `Agent Tasks` board is one premier task.

- `Task` (title) = the task name.
- `Status` = lifecycle (premier reads `To do`, writes `In Progress`/`Done`/`Blocked`/`Failed`).
- `Depends on` (relation) = other tasks that must be `Done` before this one runs.
- `Result` (text) = premier writes the crewmate summary here on completion.
- Page body = the spec.

## Page body

The body may contain any human prose. premier reads exactly ONE thing from it:
the FIRST fenced ` ```yaml ` block, which must contain `phases:`. Schema:

```yaml
phases:
  - id: A                      # phase id, unique within the task
    subtasks:
      - id: button             # subtask id, unique within the task
        brief: "what the crewmate must do"
        accept: "done-when criterion"
        review: [code-quality]  # which review subagents run on the diff
  - id: B
    depends_on: [A]            # optional: phases within this task that must land first
    subtasks:
      - id: home
        brief: "..."
        accept: "..."
        review: [code-quality]
```

`task` and `project` are NOT in the block: `task` is the row title, `project` is
the repo this board maps to (config). Everything else matches the local YAML stub
schema, so premier runs Notion tasks through the same loop as YAML tasks.

# premier Orchestrator Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn premier from two one-shot skills (`design` then `premier`) into one persistent orchestrator mode: a long-lived L1 chat that intakes a stream of tasks, decomposes each with the human, dispatches headless background execution per task, reports, and rehydrates status from Notion.

**Architecture:** L1 is the premier skill reframed as a persistent loop (await task -> intake -> dispatch -> report -> await). Intake reuses the existing `design` flow inline. Execution reuses the existing Algorithm unchanged in mechanism (main session drives background crewmates, harness wakes on completion - the proven core). Context stays thin by discipline, not by nesting: review agents already read diffs in their own contexts, L1 keeps only compact summaries, and Notion is the durable ledger L1 rehydrates from after compaction.

**Tech Stack:** Claude Code plugin (markdown SKILL.md prompt files + bash seam scripts + Notion MCP). No compiled code, no unit-test runner. Verification = `grep` invariants on the prose contracts + the existing demo seam scripts + a live e2e capture.

## Global Constraints

- premier is a prompt-skill package: "implementation" means editing `skills/*/SKILL.md`, `.claude-plugin/*.json`, `README.md`, `docs/`. No source code, no pytest.
- Do NOT change pipeline internals: worktree naming, integration-branch model, review roster, auto-fix (2 attempts), merge policy, Notion status write-back, crewmate limit 5, 429 back-off. Only the session shape and context discipline change.
- Notion writes (row creation, status write-back) happen ONLY in the main session - subagents have no Notion MCP tools. L1 owns all Notion I/O.
- L2 realization is L2b (main session drives the loop). Do NOT introduce nested background agents or a background per-task coordinator - unproven (`docs/skeleton-findings.md:51`).
- L1 is the single interface to the human. Crewmates and review subagents never address the human; blockers return to L1, which relays.
- Keep existing prose voice: imperative, terse, no em dashes.
- Commit after each task.

---

### Task 1: Reframe premier/SKILL.md into the persistent orchestrator loop

**Files:**
- Modify: `skills/premier/SKILL.md` (frontmatter `description`; body lines 6-11 intro; rename `## Algorithm` heading)

**Interfaces:**
- Produces: the `## The loop` section (5-step L1 loop) and the `## Execute one task` heading (renamed from `## Algorithm`) that Tasks 2 and 3 reference by name.

- [ ] **Step 1: Write the failing check**

Run: `grep -q "## The loop" skills/premier/SKILL.md && grep -q "persistent orchestrator" skills/premier/SKILL.md && grep -q "## Execute one task" skills/premier/SKILL.md; echo $?`
Expected: prints `1` (invariants absent - fails).

- [ ] **Step 2: Update the frontmatter description**

Replace the `description:` line in the frontmatter (line 3) with:

```
description: Persistent orchestrator mode. Enter once and stay: intake a stream of tasks, decompose each with the human, dispatch headless background crewmates per task with auto-review and auto-merge, report, and rehydrate status from Notion. Reads/writes a Notion board (one per repo) or a local YAML stub.
```

- [ ] **Step 3: Replace the intro (current lines 6-11) with the identity + loop**

Replace this block:

```
# premier

You are the premier. You execute a phased task by driving crewmates, never by
doing the work yourself. The human designed the task; your job is dispatch,
review, merge, and phase advancement.
```

with:

```
# premier

You are the premier - a persistent orchestrator, not a one-shot run. You enter
this mode once and stay. The human throws tasks at you over time; for each one
you decompose it WITH the human, hand execution to background crewmates, review
and merge their work, and report back - all in one continuous chat. You never do
a task's work yourself.

This chat is your single interface to the human. Execution detail (diffs, git
output, review transcripts) lives and dies inside subagents; it never fills this
chat. Your durable memory of task status is the Notion board, not this
transcript - if this context is ever compacted you rehydrate status by re-reading
the board and lose nothing.

## The loop

You run ONE loop for the whole session:

1. **Await a task.** The human throws a task ("do X for <repo>") or a control
   word ("запускай", "launch", "go", "how's everything?"). Idle between tasks; do
   not busy-work or poll.
2. **Intake.** Decompose the new task WITH the human by following the `design`
   skill flow (resolve board -> brainstorm -> phases/subtasks/accept -> write ONE
   Notion row). Every clarifying question happens HERE, in this chat, before
   anything is dispatched. This is the ONLY place the human is asked anything.
3. **Dispatch execution.** Run the task through `## Execute one task` below.
   Crewmates run in the background; the moment a task is dispatched you are free
   for the next message.
4. **Report.** When a task finishes, state a one-line outcome (`X done: N files,
   merged` or `X: subtask Y blocked - reason`) and write status back to Notion.
5. **Status on demand.** "How's everything?" -> read the board (Notion
   `query-data-sources`); do not rely on memory.

Back to Await. Several tasks may be in flight at once (crewmate limit 5 across
all of them).
```

- [ ] **Step 4: Rename the execution algorithm heading**

Change the line `## Algorithm` to `## Execute one task`. Leave its steps 1-8 unchanged in this task (Task 3 edits step 5).

- [ ] **Step 5: Run the check to verify it passes**

Run: `grep -q "## The loop" skills/premier/SKILL.md && grep -q "persistent orchestrator" skills/premier/SKILL.md && grep -q "## Execute one task" skills/premier/SKILL.md; echo $?`
Expected: prints `0`.

- [ ] **Step 6: Verify no dangling references to the old heading**

Run: `grep -rn "core Algorithm\|the Algorithm\|## Algorithm" skills/premier/SKILL.md`
Expected: only prose references remain and read sensibly; if any line still points at a now-missing `## Algorithm` heading, update it to `## Execute one task`. (The Notion-mode section says "the SAME core Algorithm (steps 1-8)" - reword to "the SAME `## Execute one task` algorithm (steps 1-8)".)

- [ ] **Step 7: Commit**

```bash
git add skills/premier/SKILL.md
git commit -m "feat(premier): reframe skill as persistent orchestrator loop"
```

---

### Task 2: Add the L2b context-discipline rules

**Files:**
- Modify: `skills/premier/SKILL.md` (`## Rules` section)

**Interfaces:**
- Consumes: `## The loop` and `## Execute one task` headings from Task 1.
- Produces: three durable rules (single-interface, thin-chat, rehydrate) that Task 5's live e2e verifies behaviorally.

- [ ] **Step 1: Write the failing check**

Run: `grep -q "single interface" skills/premier/SKILL.md && grep -q "rehydrate" skills/premier/SKILL.md && grep -qi "never.*diff.*in this chat\|keep this chat thin" skills/premier/SKILL.md; echo $?`
Expected: prints `1`.

- [ ] **Step 2: Add the rules**

In the `## Rules` list, add these bullets after the existing "Never do a subtask's work yourself" bullet:

```
- Single interface: crewmates and review subagents never address the human. A
  blocked subtask returns `blocked: reason` to YOU; you relay it in this chat.
  The human answers YOU and you launch the continuation (dispatch a fresh
  crewmate into the same worktree with the added context). Never route the human
  into a subagent's session.
- Keep this chat thin. Never read a diff, run a review, or inspect git output in
  this context - review agents read diffs in THEIR own contexts and return only a
  verdict; crewmates report only files-changed plus pass/fail. Keep only those
  compact summaries here.
- Notion is your ledger. Do not trust this transcript for task status - it may be
  compacted away. On any status question, and after any compaction, rehydrate by
  querying the board. You must hold nothing durable that you cannot rebuild from
  Notion.
```

- [ ] **Step 3: Run the check to verify it passes**

Run: `grep -q "single interface" skills/premier/SKILL.md && grep -q "rehydrate" skills/premier/SKILL.md && grep -qi "Keep this chat thin" skills/premier/SKILL.md; echo $?`
Expected: prints `0`.

- [ ] **Step 4: Commit**

```bash
git add skills/premier/SKILL.md
git commit -m "feat(premier): add L2b context-discipline rules (single interface, thin chat, Notion ledger)"
```

---

### Task 3: Make review + merge keep L1 clean without new nesting

**Files:**
- Modify: `skills/premier/SKILL.md` (`## Execute one task` step 5)

**Interfaces:**
- Consumes: `## Execute one task` step 5 (current review/merge logic).
- Produces: step-5 wording that keeps diffs out of L1 while staying on proven mechanics (review agents dispatched by L1 read diffs in their own contexts; L1 keeps only verdicts; merge output is git's few lines).

**Note:** Do NOT wrap review+merge in a "land" subagent - that would nest agents (a subagent dispatching review agents), which is unproven. The existing pattern already isolates the heavy noise: review agents read the diff in their own context and return a verdict. This task only makes that isolation explicit in the prose so an implementer does not accidentally dump diffs into L1.

- [ ] **Step 1: Write the failing check**

Run: `grep -q "return only a verdict\|verdict, not the diff" skills/premier/SKILL.md; echo $?`
Expected: prints `1`.

- [ ] **Step 2: Edit step 5's Review bullet**

Find the `**Review.**` sub-bullet under step 5:

```
   - **Review.** For each agent in the subtask's `review` list, dispatch it
     (foreground `Agent`) on the worktree diff:
     `git -C <worktree> diff premier/<task>/_integration...HEAD`
     Ask it for a verdict: clean, or a list of concrete problems.
```

Replace it with:

```
   - **Review.** For each agent in the subtask's `review` list, dispatch it
     (foreground `Agent`) and have IT read the diff in its own context - do not
     read the diff here:
     "Review `git -C <worktree> diff premier/<task>/_integration...HEAD`. Return
     only a verdict: `clean`, or a bulleted list of concrete problems." You keep
     the verdict, not the diff.
```

- [ ] **Step 3: Run the check to verify it passes**

Run: `grep -q "return only a verdict\|Return\s*\n*.*only a verdict\|only a verdict, not the diff\|You keep\s*the verdict, not the diff" skills/premier/SKILL.md; echo $?`
Expected: prints `0`. (If your grep is line-based, this simpler check also works: `grep -q "You keep the verdict, not the diff" skills/premier/SKILL.md; echo $?` -> `0`.)

- [ ] **Step 4: Commit**

```bash
git add skills/premier/SKILL.md
git commit -m "feat(premier): keep diffs in review subagents, only verdicts in L1"
```

---

### Task 4: Fold `design` into intake (no separate door)

**Files:**
- Modify: `skills/design/SKILL.md` (frontmatter `description` + intro paragraph)

**Interfaces:**
- Consumes: premier `## The loop` step 2 which invokes the design flow.
- Produces: design reframed as the intake step of orchestrator mode while staying independently invocable (it still only designs, never executes).

- [ ] **Step 1: Write the failing check**

Run: `grep -qi "intake step of orchestrator mode\|orchestrator mode" skills/design/SKILL.md; echo $?`
Expected: prints `1`.

- [ ] **Step 2: Update the design description**

Replace the design frontmatter `description:` line with:

```
description: premier intake. The decomposition step of premier's orchestrator mode - also invocable standalone. Think a task through with the brainstorm skill, decompose it into premier's phase/subtask spec, and write it as one ready row to the repo's Notion board. Never executes; premier runs what it writes.
```

- [ ] **Step 3: Add a one-line note to the intro**

After the existing intro paragraph ("You are the intake half of premier..."), add:

```
This is the intake step of premier's orchestrator mode: when premier is running
as a persistent orchestrator it invokes this flow inline for each new task, so
the human no longer calls `design` and `premier` as two separate steps. Invoking
it standalone (design a task now, run it later) still works.
```

- [ ] **Step 4: Run the check to verify it passes**

Run: `grep -qi "intake step of premier's orchestrator mode" skills/design/SKILL.md; echo $?`
Expected: prints `0`.

- [ ] **Step 5: Commit**

```bash
git add skills/design/SKILL.md
git commit -m "docs(design): reframe as orchestrator-mode intake, still standalone"
```

---

### Task 5: Update package metadata and README to persistent-mode framing

**Files:**
- Modify: `.claude-plugin/plugin.json` (`description`)
- Modify: `.claude-plugin/marketplace.json` (`metadata.description` and the plugin entry `description`)
- Modify: `README.md` (opening paragraph + Status blockquote)

**Interfaces:**
- Consumes: nothing.
- Produces: user-facing copy consistent with orchestrator mode.

- [ ] **Step 1: Write the failing check**

Run: `grep -qi "persistent orchestrator" .claude-plugin/plugin.json && grep -qi "orchestrator mode" README.md; echo $?`
Expected: prints `1`.

- [ ] **Step 2: Update plugin.json description**

Set `.claude-plugin/plugin.json` `"description"` to:

```
Persistent orchestrator mode: enter once and stay - intake a stream of tasks, decompose each with the human, hand execution to background worktree crewmates with auto-review and auto-merge.
```

- [ ] **Step 3: Update marketplace.json descriptions**

Set BOTH `metadata.description` and the `plugins[0].description` in `.claude-plugin/marketplace.json` to the same string as Step 2.

- [ ] **Step 4: Update README opening + Status**

Replace the opening paragraph and Status blockquote in `README.md` with:

```
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
```

- [ ] **Step 5: Run the check to verify it passes**

Run: `grep -qi "persistent orchestrator" .claude-plugin/plugin.json && grep -qi "orchestrator mode" README.md && python3 -c "import json;json.load(open('.claude-plugin/plugin.json'));json.load(open('.claude-plugin/marketplace.json'))"; echo $?`
Expected: prints `0` (invariants present AND both JSON files still parse).

- [ ] **Step 6: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md
git commit -m "docs: reframe premier package copy as persistent orchestrator mode"
```

---

### Task 6: Regression seam + live e2e capture

**Files:**
- Create: `docs/orchestrator-mode-findings.md`
- Uses (no change): `scripts/setup-demo-target.sh`, `scripts/assert-demo-result.sh`, `examples/demo-task.yaml`

**Interfaces:**
- Consumes: the reframed skill from Tasks 1-3.
- Produces: evidence that execution still works through the renamed `## Execute one task` body, plus a documented live orchestrator-mode run.

- [ ] **Step 1: Set up a fresh demo target**

Run: `./scripts/setup-demo-target.sh /tmp/premier-orch-demo`
Expected: prints setup output, no error; `/tmp/premier-orch-demo` is a git repo on `main`.

- [ ] **Step 2: Drive execution through orchestrator mode (YAML path)**

In this session, acting as premier in orchestrator mode, run the Await->Dispatch->Report loop for the stub: "run the skeleton on `examples/demo-task.yaml` against `/tmp/premier-orch-demo`". This exercises `## Execute one task` (steps 1-8) via the loop. Do the work as the skill now prescribes: dispatch crewmate(s) in the background, on completion dispatch review agent(s) that return only verdicts, merge, report a one-line outcome.

Note: YAML mode has no Notion board, so intake/write-back are skipped - this task verifies the EXECUTION path is unbroken. Intake is verified separately by `scripts/assert-design-seam.sh` in a Notion-configured repo (out of scope for the demo target).

- [ ] **Step 3: Assert the execution outcome**

Run: `./scripts/assert-demo-result.sh /tmp/premier-orch-demo`
Expected: `ASSERT PASS` (task landed on the base branch, worktrees pruned).

- [ ] **Step 4: Write the findings**

Create `docs/orchestrator-mode-findings.md` capturing: (a) that `assert-demo-result` passed through the renamed execute body (execution unbroken); (b) observations from the live run about L1 context - what actually accumulated in the chat per subtask (crewmate report + review verdict + merge line), confirming diffs did NOT land in L1; (c) any friction found in the loop wording to fix later. Use the same terse style as `docs/skeleton-findings.md`.

- [ ] **Step 5: Commit**

```bash
git add docs/orchestrator-mode-findings.md
git commit -m "test(premier): orchestrator-mode execution seam passes + live e2e findings"
```

---

## Self-Review

**Spec coverage:**
- Three-level model -> Task 1 (loop = L1), Task 3 + Rules (L2 isolation via review subagents), Notion ledger (Task 2 rehydrate rule).
- Decomposition stays at L1 -> Task 1 step 2 (intake in the loop) + Task 4 (design as intake).
- L1 single interface / no session switching -> Task 2 single-interface rule.
- Unforeseeable ambiguity -> blocked-return + human-relays continuation -> Task 2 single-interface rule (continuation dispatched by L1).
- Task lifecycle 7 steps -> Task 1 loop.
- Parallelism + status from Notion -> Task 1 loop steps 4-5 + Task 2 rehydrate rule.
- "What changes in skill files" -> Tasks 1-5.
- "What does not change" -> Global Constraints + Task 3 note (no new nesting, pipeline internals untouched).
- L2b resolution -> Global Constraints + Task 3 note.
- Success criteria -> Task 6 (execution unbroken + L1 accumulation observed).

**Placeholder scan:** No TBD/TODO. Every edit shows the exact replacement prose. Grep checks give exact commands and expected output.

**Type consistency:** The heading `## Execute one task` (defined Task 1) is referenced by Tasks 3 and 6 under that exact name. The rule phrases grepped in Task 2 steps 1 and 3 match the prose inserted in step 2. `design` flow reference in Task 1 step 2 matches Task 4's reframing.

**Known soft spot:** Task 6 steps 2 and 4 are agent-judgment steps (drive a live session, observe context), not shell-deterministic - unavoidable for a prompt-skill package. The shell assert in step 3 is the hard gate; the observation in step 4 is the documented-evidence gate.

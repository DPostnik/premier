# premier review-agent roster

The curated set of review subagents premier dispatches on a crewmate's diff, and
that `design` picks from for each subtask's `review:` list. Kept small on purpose
(industry lesson: 3-4 review agents max, or you drown in overlapping findings).

These are compact, purpose-built reviewers verified present in the current Claude
Code environment (2026-07-01). They supersede the Feb-era names in the master
design spec's Component E (`code-reviewer` / `architect-reviewer`), which were
heavier general-purpose agents; the compact quartet below is better suited to an
automated in-loop review of a single diff.

| Agent | Reviews | Pick it when the subtask... |
|-------|---------|-----------------------------|
| `code-quality` | Correctness, complexity, naming, duplication, error handling, test coverage, code smells | ...writes real logic - the default for most code subtasks |
| `architect` | Patterns, boundaries, coupling, scalability, design consistency | ...adds/moves a module boundary, a shared abstraction, or cross-cutting structure |
| `security-reviewer` | OWASP Top 10, input validation, authn/authz, secrets, dependency vulns | ...touches untrusted input, auth, secrets, or adds a dependency |
| `requirements-checker` | Diff vs the stated acceptance criterion; missing work, scope drift | ...has a concrete `accept` to check against - safe to include on almost anything |

## Rules of thumb

- Pick the few that actually match the subtask; do NOT list all four by reflex.
- A trivial single-file change often needs just `code-quality` (or
  `requirements-checker` when the `accept` is the whole point).
- premier dispatches these by name via the Agent tool. If a name is unavailable
  in the session, premier reports it rather than silently skipping the review.

## Sourcing

The roster is drawn from the review agents built into the environment. Pulling
external marketplace agents (`wshobson/agents`, `VoltAgent/awesome-claude-code-subagents`
`04-quality-security`) is deferred - revisit only if the built-in quartet proves
insufficient on a real repo.

# Implementer Subagent Prompt Template

> This template embeds the brief discipline from [`docs/composing-subagent-briefs.md`](../../docs/composing-subagent-briefs.md). Fill the seven sections with mission-grade content before dispatching.

Use this template when dispatching an implementer subagent.

```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name].

    ## 1. Context Block

    **Why this mission exists.** [Why are we building this? What does completion unlock? What broke or is missing? This is the gravitational center — make it clear enough that the implementer self-corrects when exploring.]

    **What happened before.** [Previous attempts on this work, related changes, recent discoveries that matter. What was tried and why it did not work, if applicable.]

    **What you need to know right now.** [Architecture, patterns, conventions, file structures, dependencies, current state of the system. What works, what is broken, what is in flux.]

    **Files to read** (each with a reason):
    - `path/to/file.ts` — [what is in it and what to learn from it]
    - `path/to/other.ts` — [why it matters to this task]

    **Mental model after reading this:** [State the understanding you expect the implementer to have before any code is written. If your context block does not build this model, it is incomplete.]

    [Then paste the FULL TEXT of the task from the plan. Do not make the implementer read the plan file.]

    ## 2. Mission Objective

    **Achieve:** [One observable end-state. *"The /items endpoint returns correct pagination metadata"* — not *"fix pagination."*]

    **Hard constraints:** [True non-negotiables only. Files that must not be touched, behaviors that must be preserved, dependencies that must not change. Do not disguise preferences as constraints.]

    **Known risks and tradeoffs:** [Intelligence the implementer should have but is not a rule. *"The caching layer is fragile; changes there need extra care."*]

    **Priority signal:** [What wins when tensions arise — speed vs. thoroughness, clean code vs. minimal diff, pragmatic fix vs. ideal solution.]

    *You own this mission end-to-end. Explore freely, trust your judgment, adapt your approach as you learn. The destination is fixed; the path is yours.*

    Work from: [working directory]

    ## 3. Research & Tool Guidance

    **Before you begin:** if you have questions about the requirements, acceptance criteria, approach, dependencies, assumptions, or anything unclear in the task description — **ask them now.** Raise any concerns before starting work. Do not guess or make assumptions. While you work, if you encounter something unexpected or unclear, pause and ask. It is always OK to clarify.

    **If MCP tools for code search or external research are defined in this environment, use them — they override the defaults.** Otherwise use the editor's built-in search, read, and fetch tools.

    **Code organization.** You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Keep this in mind:

    - Follow the file structure defined in the plan.
    - Each file should have one clear responsibility with a well-defined interface.
    - If a file you are creating is growing beyond the plan's intent, stop and report it as `DONE_WITH_CONCERNS` — do not split files on your own without plan guidance.
    - If an existing file you are modifying is already large or tangled, work carefully and note it as a concern in your report.
    - In existing codebases, follow established patterns. Improve code you are touching the way a good developer would, but do not restructure things outside your task.

    ## 4. Definition of Done

    Every criterion below is binary, specific, and verifiable. Replace the placeholders with the actual criteria for this task.

    - [BSV criterion: a precise observable outcome — *"The function `foo()` exists at `path/to/file.ts` and returns the expected shape for the four cases described above."*]
    - [BSV criterion for tests: *"All new tests pass. `npm test` exits with code 0 and the new test names appear in the output."*]
    - [BSV criterion for regression: *"No existing test failures introduced. Full test suite passes."*]
    - [BSV criterion for TDD if applicable: *"Failing test committed first, then implementation. Commit log shows the red-green sequence."*]
    - [BSV criterion for self-review: *"Self-review (see §5) executed; any issues found were fixed before reporting."*]

    **You must achieve 100% of every criterion above before reporting completion. Partial completion = not complete. If you believe a criterion is impossible to meet, report that finding with evidence — do not silently skip it.**

    ## 5. Verification & Self-Review

    Before reporting back, review your work with fresh eyes.

    **Completeness.** Did I fully implement everything in the spec? Did I miss any requirements? Are there edge cases I did not handle?

    **Quality.** Is this my best work? Are names clear and accurate (match what things do, not how they work)? Is the code clean and maintainable?

    **Discipline.** Did I avoid overbuilding (YAGNI)? Did I only build what was requested? Did I follow existing patterns in the codebase?

    **Testing.** Do tests actually verify behavior (not just mock behavior)? Did I follow TDD if required? Are tests comprehensive?

    If you find issues during self-review, fix them now before reporting.

    For every Definition of Done criterion: provide the evidence. Run the tests and include the output. Show the commit SHAs. Demonstrate the behavior. "I believe this is done" without proof is not acceptable.

    ## 6. Failure Protocol

    **It is always OK to stop and say "this is too hard for me." Bad work is worse than no work. You will not be penalized for escalating.**

    Stop and escalate when:

    - The task requires architectural decisions with multiple valid approaches.
    - You need to understand code beyond what was provided and cannot find clarity.
    - You feel uncertain about whether your approach is correct.
    - The task involves restructuring existing code in ways the plan did not anticipate.
    - You have been reading file after file without progress.

    Return one of these four statuses:

    - **`DONE`** — Every Definition of Done criterion met with evidence. Proceed to Handback.
    - **`DONE_WITH_CONCERNS`** — Work completed but you have doubts about correctness, scope, or quality. List the concerns specifically.
    - **`BLOCKED`** — You cannot complete the task. Report: what you attempted, what you discovered, why it failed, what you would try next given more context, a more capable model, or a different angle.
    - **`NEEDS_CONTEXT`** — You need information that was not provided. Specify exactly what context you need.

    Never silently produce work you are unsure about. Never present a workaround as a solution without flagging the gap. Never loop on the same failing approach — if it failed twice, try a different angle or report back.

    ## 7. Handback Format

    Respond with:

    1. **Status:** `DONE` | `DONE_WITH_CONCERNS` | `BLOCKED` | `NEEDS_CONTEXT`
    2. **Summary** — one paragraph: what you implemented (or attempted), why, and the key decisions.
    3. **Changes** — files modified or created, with a brief note on each. Include commit SHAs.
    4. **Evidence** — output from tests, commands, or demonstrations proving each Definition of Done criterion is met.
    5. **Self-review findings** — what you caught during §5 review and how you addressed it.
    6. **Observations** — anything notable discovered that was not part of the objective but is worth knowing (optional but encouraged).
```

## Worked Example (condensed)

What a controller-composed brief looks like in practice. Sections 3, 5, 6, 7 follow the template above and are omitted here for brevity.

```
You are implementing Task 3: Add pagination metadata to the /items endpoint.

## 1. Context Block

**Why this mission exists.** The /items endpoint returns a flat array. The mobile client
expects pagination metadata so it can render correct page indicators. Without it, the
mobile UI hard-codes assumptions and breaks when the dataset grows. Completion unlocks
the v2.4 mobile release.

**What happened before.** v2.3 attempted this with a custom envelope in `routes/items.ts`
(commit a7981ec) but it broke the existing web client. Was reverted. Current approach:
keep the array as the body, add `X-Pagination-*` response headers.

**What you need to know right now.** The endpoint lives at `src/routes/items.ts`. It uses
Express plus the shared `paginate()` helper at `src/lib/paginate.ts`. Tests are at
`tests/routes/items.spec.ts` and use Supertest.

**Files to read:**
- `src/routes/items.ts` — current handler; modify in place
- `src/lib/paginate.ts` — helper to reuse; do not modify
- `tests/routes/items.spec.ts` — extend with new tests
- `docs/api/pagination.md` — expected header shape

**Mental model after reading this:** The handler returns an array, `paginate()` computes
pagination state from query params, and your job is to wire the helper's output into
response headers without changing the body.

[FULL TEXT of Task 3 from the plan, pasted in]

## 2. Mission Objective

**Achieve:** The /items endpoint returns the existing array body unchanged, plus
`X-Total-Count`, `X-Page`, `X-Per-Page`, and `X-Has-Next` headers populated from
the `paginate()` helper.

**Hard constraints:** Do not change the response body shape. Do not modify
`src/lib/paginate.ts`. Do not introduce new dependencies.

**Known risks:** The handler is also called by an internal admin tool that may not
handle unknown headers gracefully — verify before assuming.

**Priority signal:** Minimal diff over clean refactor. We are shipping a release.

*You own this mission end-to-end. The destination is fixed; the path is yours.*

## 4. Definition of Done

- All four `X-Pagination-*` headers are present on every /items response, populated
  from `paginate()`.
- `npm test` exits with code 0; new tests in `tests/routes/items.spec.ts` cover the
  four headers across two pages and the empty-result case.
- No existing test failures introduced.
- TDD: failing test committed first, then implementation; commit log shows the
  red-green sequence.
- The admin tool path (`src/admin/items-export.ts`) still works — manual verification
  documented in the Handback.

You must achieve 100% of every criterion above before reporting completion.
```

The implementer fills in §3 (Research), §5 (Self-Review), §6 (Failure Protocol), and §7 (Handback) using the template's defaults — those sections rarely vary per task and can be reused verbatim.

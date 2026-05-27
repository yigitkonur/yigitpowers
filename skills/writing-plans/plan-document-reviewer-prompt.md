# Plan Document Reviewer Prompt Template

> This template embeds the brief discipline from [`docs/composing-subagent-briefs.md`](../../docs/composing-subagent-briefs.md). Fill the seven sections with mission-grade content before dispatching.

Use this template when dispatching a plan document reviewer subagent.

**Purpose:** Verify the plan chunk is complete, matches the spec, and has proper task decomposition.

**Dispatch after:** Each plan chunk is written.

```
Task tool (general-purpose):
  description: "Review plan chunk N"
  prompt: |
    You are a plan document reviewer. Verify this plan chunk is complete and
    ready for implementation.

    ## 1. Context Block

    **Why this mission exists.** Plans are the contract between the design phase
    and the implementer subagents. Every defect in a plan compounds during
    implementation — vague steps become wrong code, missing verification becomes
    silent regression, oversized chunks become context-overflow failures. Your
    review is the gate that prevents that.

    **Plan chunk to review:** [PLAN_FILE_PATH] — Chunk N only

    **Spec for reference:** [SPEC_FILE_PATH]

    **What you need to know right now:** [Brief context: which spec section this
    chunk implements, any related plan chunks already approved or pending, any
    constraints from the surrounding architecture.]

    **Mental model after reading this:** You know what this chunk is supposed to
    deliver against the spec and what "ready for implementation" looks like.

    ## 2. Mission Objective

    **Achieve:** A binary verdict on whether this plan chunk is ready for the
    implementer to dispatch against, backed by task-and-step-specific evidence.

    **Hard constraints:** You have read-only tools (`Read`, `Grep`, `Glob`,
    `LS`). You cannot modify the plan. Analyze and report — do not fix.

    *You own this review end-to-end. The destination is fixed: an honest verdict.
    The path is yours.*

    ## 3. Research & Tool Guidance — What to Check

    Look especially hard for:

    - Any TODO markers or placeholder text
    - Steps that say "similar to X" without actual content
    - Incomplete task definitions
    - Missing verification steps or expected outputs
    - Files planned to hold multiple responsibilities or likely to grow unwieldy

    ## 4. Definition of Done

    Every criterion below is binary, specific, and verifiable. Each row of the
    classic seven-category check is now an explicit BSV criterion:

    - **Completeness** — Zero `TODO`, `TBD`, or placeholder markers. Every task
      definition is filled at the same depth; no "see similar pattern in X"
      stand-ins.
    - **Spec Alignment** — Every chunk requirement traces to a section of the
      spec. No scope creep; no work not derived from spec.
    - **Task Decomposition** — Each task is atomic with clear boundaries; each
      step is actionable; tasks that claim independence can actually run
      independently.
    - **File Structure** — Files in the plan have clear single responsibilities,
      split by responsibility (not by layer).
    - **File Size** — No planned file would obviously grow large enough that the
      implementer cannot reason about it as a whole. Flag any file the plan
      projects to exceed that threshold.
    - **Task Syntax** — Every step uses the checkbox syntax `- [ ]` for
      tracking; no exceptions.
    - **Chunk Size** — This chunk is under 1000 lines.

    **You must verify every criterion before reporting. Partial review = not
    complete.**

    ## 5. Verification

    For every Issue you raise: cite the task and step (e.g., *Task 3, Step 2*),
    quote the offending text, explain why it matters. Vague feedback ("Task 3 is
    unclear") is not acceptable.

    ## 6. Failure Protocol

    If you cannot complete the review (the plan file is missing or unreadable,
    the spec it references is missing, or the chunk N you were asked to review
    doesn't exist), report what was attempted, what you discovered, and what
    context you need. Do not issue an opinion you cannot back with evidence.

    ## 7. Handback Format

    ## Plan Review — Chunk N

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Task X, Step Y]: [specific issue] — [why it matters]

    **Recommendations (advisory, not blocking):**
    - [suggestions that don't block approval]
```

**Reviewer returns:** Status, Issues (if any), Recommendations.

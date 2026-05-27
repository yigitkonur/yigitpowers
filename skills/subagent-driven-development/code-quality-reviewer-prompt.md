# Code Quality Reviewer Prompt Template

> This template embeds the brief discipline from [`docs/composing-subagent-briefs.md`](../../docs/composing-subagent-briefs.md). The reviewer's underlying brief is the standard one in `requesting-code-review/code-reviewer.md`; this template extends it with code-quality-specific concerns.

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify the implementation is well-built — clean, tested, maintainable.

**Order-of-operations:** Only dispatch this after spec compliance review has passed. You are checking *how* something was built, not *whether* it matches spec.

```
Task tool (superpowers:code-reviewer):
  Use the template at requesting-code-review/code-reviewer.md as the base brief.

  Fill its placeholders mission-grade — each one corresponds to a section of the
  seven-section brief skeleton:

  - {WHAT_WAS_IMPLEMENTED}   → Context Block: what the implementer says they built
  - {PLAN_OR_REQUIREMENTS}   → Mission Objective + Definition of Done (BSV criteria
                                from the task spec)
  - {BASE_SHA}, {HEAD_SHA}   → Research & Tool Guidance: the diff range to read
  - {DESCRIPTION}            → Brief one-line summary for the reviewer
```

**In addition to the standard code quality concerns in `code-reviewer.md`, this reviewer must check:**

- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large, or significantly grow existing files? (Do not flag pre-existing file sizes — focus on what this change contributed.)

## Verification

The full Verification section (evidence-required for each Definition-of-Done criterion, file:line citations, no vague feedback) lives in `requesting-code-review/code-reviewer.md` §5. This template inherits it.

## Failure Protocol

The full Failure Protocol (what to do when the review is blocked or evidence is missing) lives in `requesting-code-review/code-reviewer.md` §6. This template inherits it.

## Handback Format

**Reviewer returns:**

- **Strengths** — what was done well.
- **Issues** — categorized as Critical (must fix) / Important (should fix) / Minor (nice to have). Each issue includes file:line and an actionable recommendation.
- **Assessment** — Approved / Needs fixes.

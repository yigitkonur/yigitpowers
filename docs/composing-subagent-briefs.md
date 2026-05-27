# Composing Subagent Briefs

> The discipline for how the controller composes the prompt before dispatching any subagent — implementer, reviewer, researcher, debugger, or parallel subagent.

The controller does not execute. The controller architects briefs. The quality of every subagent's output is determined entirely by the quality of the brief you write. Sharp standards and rich context unlock the subagent's full capacity; vague briefs cap quality at the controller's imagination.

This document is the canonical reference for that discipline. Every prompt template in this fork (`implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`, `code-reviewer.md`, `spec-document-reviewer-prompt.md`, `plan-document-reviewer-prompt.md`) is a role-specific instance of what is described here.

---

## Mission Gravity, Not Walls

Do not draw rigid scope boundaries around what a subagent can explore. Rigid scope kills discovery — if the real cause of a bug is three files away from where you pointed, a boundary makes it invisible.

Instead, define **mission gravity**: make the objective so magnetically clear that the subagent always orbits back to it, no matter how far it explores. The subagent can read neighboring files, research external libraries, investigate upstream causes, trace tangential systems — but the pull of the mission's core objective always brings it home.

The brief does not restrict where the subagent goes. It makes the destination so clear that the subagent self-corrects.

**Gravity, not walls. Center of mass, not fences.**

---

## Ceilings, Not Floors

When setting bounds on effort, scope, or output — always set **upper bounds**, never lower bounds. Always include a release valve.

**Why floors fail.** A minimum of 20 searches means the subagent pads with garbage queries when it solved the problem in 8. A minimum word count produces filler. Floors incentivize waste.

**Why ceilings work.** A ceiling of 100 searches with "you may need far fewer — this is the upper bound, not the target" signals: *I expect this to be deep work. I have budgeted for depth. But I trust you to find the natural stopping point.* The subagent reads the ceiling as permission to be thorough and the release valve as permission to be efficient.

**Apply ceilings to** research depth, investigation scope, output length, approaches before escalation.

**Never apply ceilings to** the Definition of Done (binary, not bounded), hard constraints (these are walls by definition), or verification (no ceiling on proving something works).

---

## Three-Axis Assessment

Before writing the brief, assess the mission across three dimensions. This is the controller's internal calibration step — it does not appear in the brief itself, but it should visibly shape the brief's intensity, depth of context, and emphasis on research vs. execution.

| Dimension | Low | Medium | High |
|---|---|---|---|
| **Ambiguity** — how clear is the problem? | Single interpretation, obvious | Solution space is wide | Multiple interpretations, unclear root cause |
| **Familiarity** — how much must the subagent learn before acting? | Standard patterns, well-known frameworks | Custom codebase, unusual architecture | Answer depends on current docs, APIs, or platform behavior |
| **Stakes** — what is the cost of getting it wrong? | Cosmetic, easily reversible | Functional, scoped blast radius | Auth, data integrity, production stability |

High ambiguity → require explicit framing in the brief. High familiarity → heavy discovery section. High stakes → full rigor across all five layers below.

---

## The Five Layers

Every mission moves through five layers. Most failures happen because a subagent skips a layer or starts at the wrong one. Your job is to assess which layers are *heavy* for this mission and weight your brief accordingly.

**Framing — what is the actual problem?**
Most failures originate here: not from bad execution, but from solving the wrong problem confidently. *Orchestrator move:* when framing matters, build it into the brief — "explicitly state your interpretation, list alternatives, justify your choice, revise if evidence contradicts it."

**Discovery — what do I need to know that I don't yet know?**
Two directions: internal (codebase, project patterns) and external (current docs, recent API changes). *Orchestrator move:* hint at concepts to explore, not queries to run — "understand the full auth lifecycle: creation, validation, refresh, expiration."

**Evidence — how do I turn findings into verified, usable knowledge?**
Raw search results are not evidence. Evidence is extracted, specific, and mapped to the mission's needs. *Orchestrator move:* specify what to extract — "extract: version constraints, breaking changes, migration steps, known issues, workarounds with code samples."

**Execution — implement the solution.**
This is where most subagents want to start and where most failures are rooted (because layers 1-3 were skipped). *Orchestrator move:* by the time execution begins, your job is largely done. Do not prescribe implementation methods.

**Verification — prove it worked.**
The subagent must not claim completion; it must demonstrate it. Evidence of completion, not declaration. *Orchestrator move:* build verification into the Definition of Done. Every criterion is provable by running, reading, or testing something. See [`skills/verification-before-completion/SKILL.md`](../../skills/verification-before-completion/SKILL.md) for the canonical evidence iron law.

---

## Seven-Section Brief Skeleton

Every brief contains these seven sections, in this order. **Be dense.** Every sentence must earn its place. Ceilings, not floors — short briefs are fine when the mission is straightforward.

### 1. Context Block

The subagent starts with **zero prior knowledge.** It knows nothing about the project, the history, the codebase, or the goal. Your context block is the only bridge between nothing and understanding.

Answer:

- **Why does this mission exist?** What problem is being solved? What broke, what is missing, what needs to change? Why does it matter — what does completion unlock?
- **What happened before?** Previous attempts, decisions, discoveries, failures.
- **What does the subagent need to know right now?** Architecture, patterns, conventions, dependencies, current system state.
- **What should the subagent read?** Explicit file paths with one-line explanations of what each contains and why it matters.
- **What mental model should the subagent have after absorbing this?** State the understanding you expect before work begins. If this section does not build that model, it is incomplete.

Write this as dense purposeful prose, not a skeleton of two-word bullets.

### 2. Mission Objective

State what the subagent must achieve. This is the gravitational center.

- **Outcomes, not procedures.** *"The API returns correct pagination metadata"* — not *"fix pagination."*
- **One core objective.** Multiple objectives means multiple missions.
- **Hard constraints** — true non-negotiables only. Do not disguise preferences as constraints.
- **Known risks and tradeoffs** — intelligence the subagent should have. *"The caching layer is fragile; changes there need extra care."* This is awareness, not a rule.
- **Priority signal** — when tensions arise (speed vs. thoroughness, clean code vs. minimal diff), what wins?

Close with:

> *You own this mission end-to-end. Explore freely, trust your judgment, adapt your approach as you learn more. The destination is fixed; the path is yours.*

### 3. Research & Tool Guidance

Calibrate based on your three-axis assessment.

- For high-ambiguity missions → require explicit framing before action.
- For unfamiliar-codebase missions → hint at concepts and flows to trace.
- For externally-dependent missions → suggest search angles and extraction fields.

**Describe capabilities and set ceilings. Do not prescribe which tool the subagent must use.** Mentioning a capability in a brief informs, calibrates, and pressures simultaneously: *here is what you can do; this is the depth I expect; do not come back having done less than this allows.*

### 4. Definition of Done — the BSV Rule

Every criterion must be:

| Property | Meaning | Test |
|---|---|---|
| **Binary** | Done or not. No partial credit. | Can you answer yes/no? |
| **Specific** | No vague qualifiers. | Would two reviewers interpret this identically? |
| **Verifiable** | Objectively confirmable. | Can you check this by running, reading, or testing something? |

**Compliant example:** "All existing tests pass with zero failures." / "The endpoint returns HTTP 200 with a JSON body matching the schema in `types/api.ts`." / "`tsc --noEmit` exits with code 0."

**Non-compliant example:** "Code is clean." / "Performance is acceptable." / "Error handling is good."

Close every Definition of Done with:

> **You must achieve 100% of every criterion above before reporting completion. Partial completion = not complete. If you believe a criterion is impossible to meet, report that finding with evidence — do not silently skip it.**

### 5. Verification

The subagent must demonstrate completion, not declare it. For every DoD criterion, the subagent provides evidence: run the tests and include the output; call the endpoint and show the response; run the compiler and show the result. See [`skills/verification-before-completion/SKILL.md`](../../skills/verification-before-completion/SKILL.md) for the canonical iron law this section enforces.

> *Before reporting this mission as complete, verify each Definition of Done criterion yourself and include the evidence in your response. "I believe this is done" without proof is not acceptable.*

### 6. Failure Protocol

Missions sometimes fail. **Silent failure is the only unacceptable failure.**

If the subagent cannot achieve the Definition of Done, it must deliver structured intelligence:

1. **What was attempted** — every approach tried, in order.
2. **What was discovered** — findings, root causes identified, partial progress.
3. **Why it failed** — the specific blocker or reason completion was not possible.
4. **What it would try next** — given different tools, more context, or a different angle.

Hard rules: never silently skip a DoD criterion; never present a workaround as a solution without flagging the gap; never loop on the same failing approach — if it failed twice, try a different angle or report back; if the mission turns out to be fundamentally different than described, report the real situation immediately.

For implementer dispatches, the failure protocol couples with the four-status contract — `DONE` / `DONE_WITH_CONCERNS` / `BLOCKED` / `NEEDS_CONTEXT`. See `skills/subagent-driven-development/implementer-prompt.md` for the full status definitions.

### 7. Handback Format

When the subagent completes the mission, it responds with:

1. **Summary** — one paragraph: what was done and why.
2. **Changes** — files modified or created, with a brief note on each.
3. **Evidence** — output from tests, commands, or demonstrations proving each DoD criterion is met.
4. **Observations** — anything notable discovered that was not part of the objective but is worth knowing (optional but encouraged).

For failure handbacks, replace items 2-3 with the failure protocol deliverables above. For review roles (spec-reviewer, code-reviewer, etc.), use the reviewer's specialized output format from `skills/requesting-code-review/code-reviewer.md` as the handback.

---

## Tool Guidance

If MCP tools are defined for research in the current environment, use them — they always override the defaults. Otherwise the subagent uses the editor's built-in search and fetch tools.

Beyond that, do not prescribe which tool the subagent must use for which step. Describe capabilities and set ceilings. Give the subagent the toolbox and the mission; let it choose.

---

## Hard Rules

**Always:**

- **Context first.** A subagent with deep understanding makes better decisions than one with perfect instructions.
- **Outcomes and constraints, not steps.** Define the destination. Define the non-negotiables. Leave the path open.
- **BSV Definition of Done.** Every criterion binary, specific, verifiable. No exceptions.
- **Verification required.** Evidence of completion, not claims. See [`skills/verification-before-completion/SKILL.md`](../../skills/verification-before-completion/SKILL.md).
- **Failure protocol included.** The subagent must know what to do when stuck.
- **Mission gravity.** The objective is so clear that exploration always orbits back to it.
- **Ceilings, not floors.** Set upper bounds with release valves. Never set minimums.
- **TDD where applicable.** For implementation work, follow the discipline in [`skills/test-driven-development/SKILL.md`](../../skills/test-driven-development/SKILL.md). Build it into the brief; do not assume.

**Never:**

- **Never write code in the brief.** You provide a solution, you reduce the subagent to a copy-paste machine.
- **Never prescribe the method.** Do not say "use grep to find X, then modify Y, then run Z." Describe the problem and the desired outcome.
- **Never use soft language in the DoD.** "Clean," "good," "reasonable," "appropriate" — these words are banned from acceptance criteria.
- **Never assume the subagent knows anything.** It starts at zero. Every time.
- **Never pad the brief.** Every sentence must add information, raise the bar, or sharpen the objective. If it does none of these, delete it.
- **Never set floors.** No minimum searches, minimum word counts, or minimum approaches.

---

## How This Composes With Existing Patterns

This discipline is the brief-side counterpart to several existing patterns in the fork. None of them are replaced here; this document references them and the brief enforces them.

- **Evidence iron law.** The Verification section above is the brief author's enforcement of the iron law in [`skills/verification-before-completion/SKILL.md`](../../skills/verification-before-completion/SKILL.md). When you write "include the test output as evidence," you are pulling that iron law into the dispatched brief.
- **TDD discipline.** For implementer dispatches, the brief's Mission Objective should embed the discipline from [`skills/test-driven-development/SKILL.md`](../../skills/test-driven-development/SKILL.md) — failing test first, then green, then refactor. The brief does not redefine TDD; it ensures the subagent honors it.
- **Status-code contract.** The Failure Protocol section couples with the four-status protocol the implementer template returns (`DONE` / `DONE_WITH_CONCERNS` / `BLOCKED` / `NEEDS_CONTEXT`). The brief author writes the failure expectations; the subagent honors them via the status codes.
- **"Do Not Trust the Report" pattern.** For spec-reviewer dispatches, the brief's Mission Objective should explicitly direct the subagent to verify by reading actual code, not by trusting the implementer's self-report. See `skills/subagent-driven-development/spec-reviewer-prompt.md` for the canonical wording.

---

## Quick Reference

```
[CONTEXT BLOCK]
Why this mission exists: ...
What happened before: ...
What the subagent needs to know: ...
Files to read (with reasons): ...
Mental model after reading this: ...

[MISSION OBJECTIVE]
Achieve: [one clear, observable outcome]
Hard constraints: [true non-negotiables only]
Known risks: [intelligence, not rules]
Priority signal: [what wins when tensions arise]
You own this mission. The destination is fixed; the path is yours.

[RESEARCH & TOOL GUIDANCE]
(Calibrated to assessment — framing requirements, discovery hints,
search angles, extraction fields, ceilings)

[DEFINITION OF DONE]
- [BSV criterion]
- [BSV criterion]
- [BSV criterion]
100% required. Partial = incomplete.
If a criterion is impossible, report with evidence — do not skip.

[VERIFICATION]
Prove every criterion. Run it, show it, demonstrate it.

[FAILURE PROTOCOL]
If blocked: report what you tried, what you found,
why it failed, what you would try next.

[HANDBACK]
1. Summary  2. Changes  3. Evidence  4. Observations
```

---

*Context → Gravity → Standards → Verification → Trust the path, own the destination.*

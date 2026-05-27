# yigitpowers

A personal fork of [obra/superpowers](https://github.com/obra/superpowers) — same skill-based workflow, trimmed down to what I actually use day-to-day.

Upstream is great. This fork strips out the parts I don't need and adds opinions I do. The sections below are a running changelog of what's different from upstream; everything not listed here behaves the same as the original. I'll tidy this into a proper README later.

This fork targets **Claude Code** and **Codex** only.

## Changelog

### 2026-05-27 — Integrated a mission-grade brief discipline

Long before I started touching this fork I'd been carrying a personal prompt I called *mission protocol* — a context-handoff template I pasted before dispatching any heavyweight subagent task. It forces seven dense sections (Context Block, Mission Objective, Research & Tool Guidance, Definition of Done, Verification, Failure Protocol, Handback), demands a **B**inary-**S**pecific-**V**erifiable definition of done, sets ceilings instead of floors, and treats the objective as gravity rather than as walls. When I gave the controller that template before dispatching, the subagent's output quality jumped noticeably and the iteration loop shortened.

A few things kept me using it for so long. Giving the discipline a name — *mission protocol* — and a small bit of made-up vocabulary (*mission gravity*, *ceilings not floors*, *BSV criteria*) seems to give the model an identity to inhabit. In my experience the model respects an invented-but-internally-consistent term more reliably than the generic equivalent ("write a good prompt"). And the prompt itself forces the *controller* to do the hard thinking up front — context, framing, definition of done — instead of pushing that work onto the subagent. The context handoff is where most of the quality is won or lost; that prompt forced me to win it every time.

This fork now embeds that discipline in three places without breaking the upstream pipeline (`subagent-driven-development` still runs implementer → spec-reviewer → code-quality-reviewer → final code-reviewer):

- New canonical reference at [`docs/composing-subagent-briefs.md`](docs/composing-subagent-briefs.md) — the merged discipline. Self-contained; doesn't reference any external file. Trimmed redundancy with upstream patterns (verification-before-completion, test-driven-development, the "Don't Trust the Report" stance from spec-reviewer).
- All seven existing prompt templates refreshed to the seven-section structure, with each role's original teeth preserved verbatim (status codes `DONE` / `DONE_WITH_CONCERNS` / `BLOCKED` / `NEEDS_CONTEXT` in the implementer template; "Do Not Trust the Report" in the spec-reviewer; Critical/Important/Minor categorization in the code-reviewer; the seven-row check tables in the spec-document and plan-document reviewers, now expressed as BSV criteria).
- The Example Workflow in `skills/subagent-driven-development/SKILL.md` rewritten to show the controller composing a seven-section brief before each dispatch and the implementer responding with the new Handback format.

What I deliberately *didn't* touch: no new skill, no skill-system surgery, no changes to worktree or parallelism semantics. The discipline lives in the templates that the controller already reads before every dispatch.

### 2026-05-27 — Stripped Factory Droid and Copilot infrastructure

This fork originally shipped as a Factory Droid plugin (it was branched from a `superpowers-droid` lineage) and carried some Copilot-adjacent crumbs. I removed all of that to keep the surface area honest: yigitpowers is for Claude Code and Codex, and only those.

Removed:

- `droids/` — the five role definitions (implementer, spec-reviewer, code-quality-reviewer, code-reviewer, plan-reviewer). Role behavior now lives entirely in the prompt templates the controller composes; there is no separate agent-definition file layer.
- `.factory-plugin/` — the Factory Droid plugin manifest directory.
- `docs/droid/01` through `docs/droid/06` — Droid-specific architecture, installation, and tool-mapping docs.
- `install.sh` and `scripts/install.mjs` — the curl|bash Droid installer and its Node implementation. Claude Code installs via the `.claude-plugin/` marketplace; no bespoke installer needed.
- `skills/using-superpowers/references/droid-tools.md` — the Claude-Code-to-Droid tool name mapping table.

Scrubbed everywhere else:

- `Factory Droid` → `Claude Code` in platform references (or rephrased to be platform-neutral where the original line was abstract).
- `Droid` / `droid` / `Droids` → `Subagent` / `subagent` / `Subagents` in role mentions.
- `DROID_PLUGIN_ROOT` → `CLAUDE_PLUGIN_ROOT` in the hook scripts; the dual-branch platform detection collapsed to one Claude branch plus a generic `additional_context` fallback for other platforms.
- `superpowers-droid` → `yigitpowers` in `package.json`, `.claude-plugin/marketplace.json`, and repo URLs.
- Droid-only tool references (`Create-PR`, `droid --worktree`, `/create-skill`) removed; `gh pr create` and standard `git worktree` instructions are now the only paths.

Why: I almost never invoke this fork from Droid. Carrying two install paths, two hook branches, a separate `droids/` role layer, and a tool-mapping doc was overhead with no payoff. Trimming it down also makes the workflow more legible — every dispatch goes through the same prompt-composition discipline regardless of platform.

### 2026-05-27 — Removed the visual companion

The `brainstorming` skill used to offer a browser-based visual companion: it would spin up a local Express server, open a URL in the user's browser, and serve HTML mockups, A/B options, and clickable diagrams during the design conversation. That entire feature is gone now.

Removed:

- The "Offer visual companion" step in the brainstorming checklist (was step 2) and the matching branch in its process-flow graph
- The "Visual Companion" section at the bottom of `skills/brainstorming/SKILL.md` — including the consent prompt that asked permission to open a local URL
- `skills/brainstorming/visual-companion.md` — the full guide for running and using the browser session
- `skills/brainstorming/scripts/` — the Express server, HTML frame template, client-side helper, `start-server.sh` / `stop-server.sh`, `package.json`, and the bundled `node_modules` tree
- The `!skills/brainstorming/scripts/node_modules/` whitelist line in `.gitignore` that existed only to ship that server

Why: for most of what I work on (backend, CLI, infra, agentic tooling) the visual companion is overhead. It pulls in a non-trivial Node dependency tree, asks the user to leave the terminal, and is rarely the right medium for the questions brainstorming actually has to answer — scope, tradeoffs, architecture, success criteria. When a project really is visual-first, purpose-built frontend tools beat a generic mockup server. Cutting it keeps the skill focused and shrinks the install footprint considerably.

Brainstorming now runs entirely in the terminal: one question at a time, text-based options, written design doc at the end.

---

## Credits

Built on [superpowers](https://github.com/obra/superpowers) by [@obra](https://github.com/obra) (Jesse Vincent). MIT license.

# yigitpowers

A personal fork of [obra/superpowers](https://github.com/obra/superpowers) — same skill-based workflow, trimmed down to what I actually use day-to-day.

Upstream is great. This fork strips out the parts I don't need and adds opinions I do. The sections below are a running changelog of what's different from upstream; everything not listed here behaves the same as the original. I'll tidy this into a proper README later.

## Changelog

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

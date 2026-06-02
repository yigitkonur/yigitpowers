#!/usr/bin/env bash
# Test: Brainstorm-to-plan handoff
#
# Verifies that after brainstorming, Claude invokes the writing-plans skill
# instead of using EnterPlanMode.
#
# The failure mode this catches:
#   User says "build it" after brainstorming -> Claude calls EnterPlanMode
#   (because the system prompt's planning guidance overpowers the brainstorming
#   skill's instructions, which were loaded many turns ago)
#
# PASS: Skill tool invoked with "writing-plans" AND EnterPlanMode NOT invoked
# FAIL: EnterPlanMode invoked OR writing-plans not invoked
#
# Usage:
#   ./test-brainstorm-handoff.sh                  # Normal test (expects PASS)
#   ./test-brainstorm-handoff.sh --without-fix    # Strip fix, reproduce failure
#   ./test-brainstorm-handoff.sh --verbose        # Show full output
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse flags
VERBOSE=false
WITHOUT_FIX=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v) VERBOSE=true; shift ;;
        --without-fix) WITHOUT_FIX=true; shift ;;
        *) echo "Unknown flag: $1"; exit 1 ;;
    esac
done

TIMESTAMP=$(date +%s)
OUTPUT_DIR="/tmp/superpowers-tests/${TIMESTAMP}/brainstorm-handoff"
mkdir -p "$OUTPUT_DIR"

echo "=== Brainstorm-to-Plan Handoff Test ==="
echo "Mode: $([ "$WITHOUT_FIX" = true ] && echo "WITHOUT FIX (expect failure)" || echo "WITH FIX (expect pass)")"
echo "Output: $OUTPUT_DIR"
echo ""

# --- Project Setup ---

PROJECT_DIR="$OUTPUT_DIR/project"
mkdir -p "$PROJECT_DIR/src"
mkdir -p "$PROJECT_DIR/docs/superpowers/specs"

cat > "$PROJECT_DIR/package.json" << 'PROJ_EOF'
{
  "name": "my-express-app",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "express": "^4.18.0",
    "better-sqlite3": "^9.0.0"
  }
}
PROJ_EOF

cat > "$PROJECT_DIR/src/index.js" << 'PROJ_EOF'
import express from 'express';
const app = express();
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Listening on ${PORT}`));
PROJ_EOF

# Pre-create a spec document (simulating completed brainstorming)
cat > "$PROJECT_DIR/docs/superpowers/specs/2025-01-15-url-shortener-design.md" << 'SPEC_EOF'
# URL Shortener Design Spec

## Overview
Add URL shortening capability to the existing Express.js API.

## Features
- POST /api/shorten accepts { url } and returns { shortCode, shortUrl }
- GET /:code redirects to the original URL (302)
- GET /api/stats/:code returns { clicks, createdAt, originalUrl }

## Technical Design

### Database
Single SQLite table via better-sqlite3:
```sql
CREATE TABLE urls (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  short_code TEXT UNIQUE NOT NULL,
  original_url TEXT NOT NULL,
  clicks INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX idx_short_code ON urls(short_code);
```

### File Structure
- `src/index.js` — modified to mount new routes
- `src/db.js` — database initialization and query functions
- `src/shorten.js` — route handlers for all three endpoints
- `src/code-generator.js` — random 6-char alphanumeric code generation

### Code Generation
Random 6-character alphanumeric codes using crypto.randomBytes.
Check for collisions and retry (astronomically unlikely with 36^6 space).

### Validation
- URL must be present and start with http:// or https://
- Return 400 with { error: "..." } for invalid input

### Error Handling
- 404 with { error: "Not found" } for unknown short codes
- 500 with { error: "Internal server error" } for database failures

## Decisions
- 302 redirects (not 301) so browsers don't cache and we always track clicks
- Database path configurable via DATABASE_PATH env var, defaults to ./data/urls.db
- No auth, no custom codes, no expiry — keeping it simple
SPEC_EOF

# Initialize git so brainstorming can inspect project state
cd "$PROJECT_DIR"
git init -q
git add -A
git commit -q -m "Initial commit with URL shortener spec"

# --- Plugin Setup ---

EFFECTIVE_PLUGIN_DIR="$PLUGIN_DIR"

if [ "$WITHOUT_FIX" = true ]; then
    echo "Creating plugin copy without the handoff fix..."
    EFFECTIVE_PLUGIN_DIR="$OUTPUT_DIR/plugin-without-fix"
    cp -R "$PLUGIN_DIR" "$EFFECTIVE_PLUGIN_DIR"

    # Strip fix from brainstorming SKILL.md: revert to old implementation section
    python3 << PYEOF
import pathlib
p = pathlib.Path('$EFFECTIVE_PLUGIN_DIR/skills/brainstorming/SKILL.md')
content = p.read_text()
content = content.replace(
    '**Implementation (if continuing):**\nWhen the user approves the design and wants to build:\n1. **Invoke \`superpowers:writing-plans\` using the Skill tool.** Not EnterPlanMode. Not plan mode. Not direct implementation. The Skill tool.\n2. After the plan is written, use superpowers:using-git-worktrees to create an isolated workspace for implementation.',
    '**Implementation (if continuing):**\n- Ask: "Ready to set up for implementation?"\n- Use superpowers:using-git-worktrees to create isolated workspace\n- **REQUIRED:** Use superpowers:writing-plans to create detailed implementation plan'
)
p.write_text(content)
PYEOF

    # Strip fix from using-superpowers: remove EnterPlanMode red flag
    python3 << PYEOF
import pathlib
p = pathlib.Path('$EFFECTIVE_PLUGIN_DIR/skills/using-superpowers/SKILL.md')
lines = p.read_text().splitlines(keepends=True)
lines = [l for l in lines if 'I should use EnterPlanMode' not in l]
p.write_text(''.join(lines))
PYEOF

    # Strip fix from writing-plans: revert description and context
    python3 << PYEOF
import pathlib
p = pathlib.Path('$EFFECTIVE_PLUGIN_DIR/skills/writing-plans/SKILL.md')
content = p.read_text()
content = content.replace(
    'description: Use when you have a spec or requirements for a multi-step task, before touching code. After brainstorming, ALWAYS use this — not EnterPlanMode or plan mode.',
    'description: Use when you have a spec or requirements for a multi-step task, before touching code'
)
content = content.replace(
    '**Context:** This runs in the main workspace after brainstorming, while context is fresh. The worktree is created afterward for implementation.',
    '**Context:** This should be run in a dedicated worktree (created by brainstorming skill).'
)
p.write_text(content)
PYEOF
    echo "Plugin copy created at $EFFECTIVE_PLUGIN_DIR"
    echo ""
fi

# --- Run Conversation ---

cd "$PROJECT_DIR"

# Turn 1: Load brainstorming and establish that we finished the design
# The key is that brainstorming gets loaded into context, and we're at the handoff point
echo ">>> Turn 1: Loading brainstorming skill and establishing context..."
TURN1_LOG="$OUTPUT_DIR/turn1.json"

TURN1_PROMPT='I want to add URL shortening to this Express app. I already have the full design worked out and written to docs/superpowers/specs/2025-01-15-url-shortener-design.md. Please read the spec.'

timeout 300 claude -p "$TURN1_PROMPT" \
    --plugin-dir "$EFFECTIVE_PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --max-turns 5 \
    --output-format stream-json \
    > "$TURN1_LOG" 2>&1 || true

echo "Turn 1 complete."
if [ "$VERBOSE" = true ]; then
    echo "---"
    grep '"type":"assistant"' "$TURN1_LOG" | tail -1 | jq -r '.message.content[0].text // empty' 2>/dev/null | head -c 800 || true
    echo ""
    echo "---"
fi
echo ""

# Turn 2: Approve and ask to build - this is the critical handoff moment
echo ">>> Turn 2: 'The spec is done. Build it.' (critical handoff)..."
TURN2_LOG="$OUTPUT_DIR/turn2.json"

TURN2_PROMPT='The spec is complete and I am happy with the design. Build it.'

timeout 300 claude -p "$TURN2_PROMPT" \
    --continue \
    --plugin-dir "$EFFECTIVE_PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --max-turns 5 \
    --output-format stream-json \
    > "$TURN2_LOG" 2>&1 || true

echo "Turn 2 complete."
if [ "$VERBOSE" = true ]; then
    echo "---"
    grep '"type":"assistant"' "$TURN2_LOG" | tail -1 | jq -r '.message.content[0].text // empty' 2>/dev/null | head -c 800 || true
    echo ""
    echo "---"
fi
echo ""

# --- Assertions ---

echo "=== Results ==="
echo ""

# Combine all turn logs for analysis
ALL_LOGS="$OUTPUT_DIR/all-turns.json"
cat "$TURN1_LOG" "$TURN2_LOG" > "$ALL_LOGS"

# Detection: writing-plans skill invoked?
HAS_WRITING_PLANS=false
if grep -q '"name":"Skill"' "$ALL_LOGS" 2>/dev/null && grep -q 'writing-plans' "$ALL_LOGS" 2>/dev/null; then
    HAS_WRITING_PLANS=true
fi

# Detection: EnterPlanMode invoked?
HAS_ENTER_PLAN_MODE=false
if grep -q '"name":"EnterPlanMode"' "$ALL_LOGS" 2>/dev/null; then
    HAS_ENTER_PLAN_MODE=true
fi

# Report what skills were invoked
echo "Skills invoked:"
grep -o '"skill":"[^"]*"' "$ALL_LOGS" 2>/dev/null | sort -u || echo "  (none)"
echo ""

echo "Notable tools invoked:"
grep -o '"name":"[A-Z][^"]*"' "$ALL_LOGS" 2>/dev/null | sort | uniq -c | sort -rn | head -10 || echo "  (none)"
echo ""

# Determine result
PASSED=false
if [ "$WITHOUT_FIX" = true ]; then
    # In without-fix mode, we EXPECT the failure (EnterPlanMode)
    echo "--- Without-Fix Mode (reproducing failure) ---"
    if [ "$HAS_ENTER_PLAN_MODE" = true ]; then
        echo "REPRODUCED: Claude used EnterPlanMode (the bug we're fixing)"
        PASSED=true
    elif [ "$HAS_WRITING_PLANS" = true ]; then
        echo "NOT REPRODUCED: Claude used writing-plans even without the fix"
        echo "(The model may have followed the old guidance anyway)"
        PASSED=false
    else
        echo "INCONCLUSIVE: Claude used neither writing-plans nor EnterPlanMode"
        echo "The brainstorming flow may not have reached the handoff point."
        PASSED=false
    fi
else
    # Normal mode: expect writing-plans, not EnterPlanMode
    echo "--- With-Fix Mode (verifying fix) ---"
    if [ "$HAS_WRITING_PLANS" = true ] && [ "$HAS_ENTER_PLAN_MODE" = false ]; then
        echo "PASS: Claude used writing-plans skill (correct handoff)"
        PASSED=true
    elif [ "$HAS_ENTER_PLAN_MODE" = true ]; then
        echo "FAIL: Claude used EnterPlanMode instead of writing-plans"
        PASSED=false
    elif [ "$HAS_WRITING_PLANS" = true ] && [ "$HAS_ENTER_PLAN_MODE" = true ]; then
        echo "FAIL: Claude used BOTH writing-plans AND EnterPlanMode"
        PASSED=false
    else
        echo "INCONCLUSIVE: Claude used neither writing-plans nor EnterPlanMode"
        echo "The brainstorming flow may not have reached the handoff point."
        echo "Check logs - brainstorming may still be asking questions."
        PASSED=false
    fi
fi

echo ""

# Show the critical turn 2 response
echo "Turn 2 response (first 500 chars):"
grep '"type":"assistant"' "$TURN2_LOG" 2>/dev/null | tail -1 | \
    jq -r '.message.content[0].text // .message.content' 2>/dev/null | \
    head -c 500 || echo "  (could not extract)"
echo ""

echo ""
echo "Logs:"
echo "  Turn 1: $TURN1_LOG"
echo "  Turn 2: $TURN2_LOG"
echo "  Combined: $ALL_LOGS"
echo ""

if [ "$PASSED" = true ]; then
    exit 0
else
    exit 1
fi

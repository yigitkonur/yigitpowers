#!/usr/bin/env bash
# Test: Brainstorm-to-plan handoff (end-to-end)
#
# Full brainstorming flow that builds enough context distance to reproduce
# the EnterPlanMode failure. Simulates a real brainstorming session with
# multiple turns of Q&A before the "build it" moment.
#
# This test takes 5-10 minutes to run.
#
# PASS: Skill tool invoked with "writing-plans" AND EnterPlanMode NOT invoked
# FAIL: EnterPlanMode invoked OR writing-plans not invoked
#
# Usage:
#   ./test-brainstorm-handoff-e2e.sh                  # With fix (expects PASS)
#   ./test-brainstorm-handoff-e2e.sh --without-fix    # Strip fix, reproduce failure
#   ./test-brainstorm-handoff-e2e.sh --verbose        # Show full output
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
OUTPUT_DIR="/tmp/superpowers-tests/${TIMESTAMP}/brainstorm-handoff-e2e"
mkdir -p "$OUTPUT_DIR"

echo "=== Brainstorm-to-Plan Handoff E2E Test ==="
echo "Mode: $([ "$WITHOUT_FIX" = true ] && echo "WITHOUT FIX (expect failure)" || echo "WITH FIX (expect pass)")"
echo "Output: $OUTPUT_DIR"
echo "This test takes 5-10 minutes."
echo ""

# --- Project Setup ---

PROJECT_DIR="$OUTPUT_DIR/project"
mkdir -p "$PROJECT_DIR/src" "$PROJECT_DIR/test"

cat > "$PROJECT_DIR/package.json" << 'PROJ_EOF'
{
  "name": "my-express-app",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "test": "vitest run"
  },
  "dependencies": {
    "express": "^4.18.0",
    "better-sqlite3": "^9.0.0"
  },
  "devDependencies": {
    "vitest": "^1.0.0",
    "supertest": "^6.0.0"
  }
}
PROJ_EOF

cat > "$PROJECT_DIR/src/index.js" << 'PROJ_EOF'
import express from 'express';
const app = express();
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => console.log(`Listening on ${PORT}`));
}

export default app;
PROJ_EOF

cd "$PROJECT_DIR"
git init -q
git add -A
git commit -q -m "Initial commit"

# --- Plugin Setup ---

EFFECTIVE_PLUGIN_DIR="$PLUGIN_DIR"

if [ "$WITHOUT_FIX" = true ]; then
    echo "Creating plugin copy without the handoff fix..."
    EFFECTIVE_PLUGIN_DIR="$OUTPUT_DIR/plugin-without-fix"
    cp -R "$PLUGIN_DIR" "$EFFECTIVE_PLUGIN_DIR"

    python3 << PYEOF
import pathlib

# Strip fix from brainstorming SKILL.md
p = pathlib.Path('$EFFECTIVE_PLUGIN_DIR/skills/brainstorming/SKILL.md')
content = p.read_text()
content = content.replace(
    '**Implementation (if continuing):**\nWhen the user approves the design and wants to build:\n1. **Invoke \`superpowers:writing-plans\` using the Skill tool.** Not EnterPlanMode. Not plan mode. Not direct implementation. The Skill tool.\n2. After the plan is written, use superpowers:using-git-worktrees to create an isolated workspace for implementation.',
    '**Implementation (if continuing):**\n- Ask: "Ready to set up for implementation?"\n- Use superpowers:using-git-worktrees to create isolated workspace\n- **REQUIRED:** Use superpowers:writing-plans to create detailed implementation plan'
)
p.write_text(content)

# Strip fix from using-superpowers
p = pathlib.Path('$EFFECTIVE_PLUGIN_DIR/skills/using-superpowers/SKILL.md')
lines = p.read_text().splitlines(keepends=True)
lines = [l for l in lines if 'I should use EnterPlanMode' not in l]
p.write_text(''.join(lines))

# Strip fix from writing-plans
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
    echo "Plugin copy created."
    echo ""
fi

# --- Helper ---

run_turn() {
    local turn_num="$1"
    local prompt="$2"
    local max_turns="$3"
    local label="$4"
    local continue_flag="${5:-}"

    local log_file="$OUTPUT_DIR/turn${turn_num}.json"
    echo ">>> Turn $turn_num: $label"

    local cmd="timeout 300 claude -p \"$prompt\""
    cmd="$cmd --plugin-dir \"$EFFECTIVE_PLUGIN_DIR\""
    cmd="$cmd --dangerously-skip-permissions"
    cmd="$cmd --max-turns $max_turns"
    cmd="$cmd --output-format stream-json"
    if [ -n "$continue_flag" ]; then
        cmd="$cmd --continue"
    fi

    eval "$cmd" > "$log_file" 2>&1 || true

    echo "    Done."
    if [ "$VERBOSE" = true ]; then
        echo "    ---"
        grep '"type":"assistant"' "$log_file" 2>/dev/null | tail -1 | \
            jq -r '.message.content[0].text // empty' 2>/dev/null | \
            head -c 600 || true
        echo ""
        echo "    ---"
    fi

    echo "$log_file"
}

# --- Run Full Brainstorming Flow ---

cd "$PROJECT_DIR"

# Turn 1: Start brainstorming - this loads the skill and begins Q&A
T1=$(run_turn 1 \
    "I want to add URL shortening to this Express app. Help me think through the design." \
    5 "Starting brainstorming")

# Turn 2: Answer first question (whatever it is) generically
T2=$(run_turn 2 \
    "Good question. Here is what I want: POST /api/shorten that takes a URL and returns a short code. GET /:code that redirects. GET /api/stats/:code for click tracking. Random 6-char alphanumeric codes. SQLite storage using better-sqlite3 which is already in package.json. No auth needed." \
    5 "Answering first question" --continue)

# Turn 3: Agree with recommendations
T3=$(run_turn 3 \
    "Yes, that sounds right. Go with your recommendation." \
    5 "Agreeing with recommendation" --continue)

# Turn 4: Continue agreeing
T4=$(run_turn 4 \
    "Looks good. I agree with that approach." \
    5 "Continuing to agree" --continue)

# Turn 5: Push toward completion
T5=$(run_turn 5 \
    "Perfect. I am happy with all of that. Please wrap up the design and write the spec." \
    8 "Requesting spec write-up" --continue)

# Turn 6: Approve the spec
T6=$(run_turn 6 \
    "The spec looks great. I approve it." \
    5 "Approving spec" --continue)

# Turn 7: THE CRITICAL MOMENT - "build it"
T7=$(run_turn 7 \
    "Yes, build it." \
    5 "Critical handoff: build it" --continue)

# Turn 8: Safety net in case turn 7 asked a follow-up
T8=$(run_turn 8 \
    "Yes. Go ahead and build it now." \
    5 "Safety net: build it" --continue)

echo ""

# --- Assertions ---

echo "=== Results ==="
echo ""

# Combine all logs
ALL_LOGS="$OUTPUT_DIR/all-turns.json"
cat "$OUTPUT_DIR"/turn*.json > "$ALL_LOGS" 2>/dev/null

# Check handoff turns (6-8, where approval + "build it" happens)
HANDOFF_LOGS="$OUTPUT_DIR/handoff-turns.json"
cat "$OUTPUT_DIR/turn6.json" "$OUTPUT_DIR/turn7.json" "$OUTPUT_DIR/turn8.json" > "$HANDOFF_LOGS" 2>/dev/null

# Detection: writing-plans skill invoked in handoff turns?
HAS_WRITING_PLANS=false
if grep -q '"name":"Skill"' "$HANDOFF_LOGS" 2>/dev/null && grep -q 'writing-plans' "$HANDOFF_LOGS" 2>/dev/null; then
    HAS_WRITING_PLANS=true
fi

# Detection: EnterPlanMode invoked in handoff turns?
HAS_ENTER_PLAN_MODE=false
if grep -q '"name":"EnterPlanMode"' "$HANDOFF_LOGS" 2>/dev/null; then
    HAS_ENTER_PLAN_MODE=true
fi

# Also check across ALL turns (might happen earlier)
HAS_ENTER_PLAN_MODE_ANYWHERE=false
if grep -q '"name":"EnterPlanMode"' "$ALL_LOGS" 2>/dev/null; then
    HAS_ENTER_PLAN_MODE_ANYWHERE=true
fi

# Report
echo "Skills invoked (all turns):"
grep -o '"skill":"[^"]*"' "$ALL_LOGS" 2>/dev/null | sort -u || echo "  (none)"
echo ""

echo "Skills invoked (handoff turns 6-8):"
grep -o '"skill":"[^"]*"' "$HANDOFF_LOGS" 2>/dev/null | sort -u || echo "  (none)"
echo ""

echo "Tools invoked in handoff turns (6-8):"
grep -o '"name":"[A-Z][^"]*"' "$HANDOFF_LOGS" 2>/dev/null | sort | uniq -c | sort -rn | head -10 || echo "  (none)"
echo ""

if [ "$HAS_ENTER_PLAN_MODE_ANYWHERE" = true ]; then
    echo "WARNING: EnterPlanMode was invoked somewhere in the conversation."
    echo "Turns containing EnterPlanMode:"
    for f in "$OUTPUT_DIR"/turn*.json; do
        if grep -q '"name":"EnterPlanMode"' "$f" 2>/dev/null; then
            echo "  $(basename "$f")"
        fi
    done
    echo ""
fi

# Determine result
PASSED=false
if [ "$WITHOUT_FIX" = true ]; then
    echo "--- Without-Fix Mode (reproducing failure) ---"
    if [ "$HAS_ENTER_PLAN_MODE" = true ] || [ "$HAS_ENTER_PLAN_MODE_ANYWHERE" = true ]; then
        echo "REPRODUCED: Claude used EnterPlanMode (the bug we're fixing)"
        PASSED=true
    elif [ "$HAS_WRITING_PLANS" = true ]; then
        echo "NOT REPRODUCED: Claude used writing-plans even without the fix"
        echo "(The old guidance was sufficient in this run)"
        PASSED=false
    else
        echo "INCONCLUSIVE: Claude used neither writing-plans nor EnterPlanMode"
        echo "The brainstorming flow may not have reached the handoff point."
        PASSED=false
    fi
else
    echo "--- With-Fix Mode (verifying fix) ---"
    if [ "$HAS_WRITING_PLANS" = true ] && [ "$HAS_ENTER_PLAN_MODE_ANYWHERE" = false ]; then
        echo "PASS: Claude used writing-plans skill (correct handoff)"
        PASSED=true
    elif [ "$HAS_ENTER_PLAN_MODE_ANYWHERE" = true ]; then
        echo "FAIL: Claude used EnterPlanMode instead of writing-plans"
        PASSED=false
    elif [ "$HAS_WRITING_PLANS" = true ] && [ "$HAS_ENTER_PLAN_MODE_ANYWHERE" = true ]; then
        echo "FAIL: Claude used BOTH writing-plans AND EnterPlanMode"
        PASSED=false
    else
        echo "INCONCLUSIVE: Claude used neither writing-plans nor EnterPlanMode"
        echo "The brainstorming flow may not have reached the handoff."
        echo "Check logs to see where the conversation stopped."
        PASSED=false
    fi
fi

echo ""

# Show what happened in each turn
echo "Turn-by-turn summary:"
for i in 1 2 3 4 5 6 7 8; do
    local_log="$OUTPUT_DIR/turn${i}.json"
    if [ -f "$local_log" ]; then
        local_skills=$(grep -o '"skill":"[^"]*"' "$local_log" 2>/dev/null | tr '\n' ' ' || true)
        local_tools=$(grep -o '"name":"EnterPlanMode\|"name":"Skill"' "$local_log" 2>/dev/null | tr '\n' ' ' || true)
        local_size=$(wc -c < "$local_log" | tr -d ' ')
        printf "  Turn %d: %s bytes" "$i" "$local_size"
        [ -n "$local_skills" ] && printf " | skills: %s" "$local_skills"
        [ -n "$local_tools" ] && printf " | tools: %s" "$local_tools"
        echo ""
    fi
done

echo ""
echo "Logs: $OUTPUT_DIR"
echo ""

if [ "$PASSED" = true ]; then
    exit 0
else
    exit 1
fi

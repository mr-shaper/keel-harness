#!/usr/bin/env bash
# test-context-aware-handoff.sh — e2e test for alpha.4 context-aware handoff
#
# Coverage:
#   Test 1-5: stop-handoff PCT gate (skip / above-gate / cold-start fallback / force-flag / env-override)
#   Test 6-7: post-tool model-aware WINDOW (Haiku=200k vs Opus=1M)
#
# Usage:
#   bash tests/test-context-aware-handoff.sh                 # all 7 tests
#   bash tests/test-context-aware-handoff.sh --post-tool-only # Test 6+7 only

set -uo pipefail

DUMMY_BASE=/tmp/test-ctx-aware-handoff-$$
mkdir -p "$DUMMY_BASE"
trap "rm -rf $DUMMY_BASE" EXIT

PASS=0
FAIL=0

POST_TOOL_ONLY=0
if [[ "${1:-}" == "--post-tool-only" ]]; then
  POST_TOOL_ONLY=1
fi

# Default to dev repo's flat hooks/ layout; allow env override for testing
# against an installed runtime path.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_POST_TOOL="${HOOK_POST_TOOL:-$REPO_ROOT/hooks/post-tool-context-monitor.sh}"
HOOK_STOP_HANDOFF="${HOOK_STOP_HANDOFF:-$REPO_ROOT/hooks/stop-handoff-writer.sh}"

echo "=== test-context-aware-handoff.sh e2e (alpha.4) ==="
echo "    HOOK_POST_TOOL=$HOOK_POST_TOOL"
echo "    HOOK_STOP_HANDOFF=$HOOK_STOP_HANDOFF"
echo ""

pass_test() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail_test() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

# --------------------------------------------------------------------------
# Test 1: ctx<70% (30%) → SKIP trace written, no handoff.md
# --------------------------------------------------------------------------
run_test1() {
  DUMMY1="$DUMMY_BASE/test1"
  mkdir -p "$DUMMY1/.harness"
  printf '[2026-05-05T00:00:00+0000] ctx-monitor: total=300000 window=1000000 pct=30%%\n' \
    >> "$DUMMY1/.harness/hook-trace.log"
  echo '{"type":"assistant","message":{"model":"claude-opus-4-7","usage":{"input_tokens":300000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"output_tokens":200}}}' \
    > "$DUMMY1/transcript.jsonl"

  INPUT1=$(printf '{"transcript_path":"%s/transcript.jsonl","cwd":"%s","session_id":"test1"}' "$DUMMY1" "$DUMMY1")
  echo "$INPUT1" | bash "$HOOK_STOP_HANDOFF" 2>/dev/null || true

  if grep -q "stop-handoff: SKIP ctx=30" "$DUMMY1/.harness/hook-trace.log" 2>/dev/null; then
    pass_test "Test 1: ctx=30% < 70% → SKIP trace written"
  else
    fail_test "Test 1: ctx=30% should skip; expected 'SKIP ctx=30' in hook-trace.log, got: $(cat "$DUMMY1/.harness/hook-trace.log" 2>/dev/null)"
  fi
}

# --------------------------------------------------------------------------
# Test 2: ctx=75% above gate → handoff.md written
# --------------------------------------------------------------------------
run_test2() {
  DUMMY2="$DUMMY_BASE/test2"
  mkdir -p "$DUMMY2/.harness"
  printf '[2026-05-05T00:00:00+0000] ctx-monitor: total=750000 window=1000000 pct=75%%\n' \
    >> "$DUMMY2/.harness/hook-trace.log"
  echo '{"type":"assistant","message":{"model":"claude-opus-4-7","usage":{"input_tokens":750000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"output_tokens":200}}}' \
    > "$DUMMY2/transcript.jsonl"

  INPUT2=$(printf '{"transcript_path":"%s/transcript.jsonl","cwd":"%s","session_id":"test2"}' "$DUMMY2" "$DUMMY2")
  echo "$INPUT2" | bash "$HOOK_STOP_HANDOFF" 2>/dev/null || true

  if [ -f "$DUMMY2/.harness/handoff.md" ]; then
    pass_test "Test 2: ctx=75% above gate → handoff.md written"
  else
    fail_test "Test 2: ctx=75% should write handoff, none found"
  fi
}

# --------------------------------------------------------------------------
# Test 3: hook-trace absent (cold start) → fallback path writes handoff
# --------------------------------------------------------------------------
run_test3() {
  DUMMY3="$DUMMY_BASE/test3"
  mkdir -p "$DUMMY3/.harness"
  echo '{"type":"assistant","message":{"model":"claude-opus-4-7","usage":{"input_tokens":100000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"output_tokens":200}}}' \
    > "$DUMMY3/transcript.jsonl"

  INPUT3=$(printf '{"transcript_path":"%s/transcript.jsonl","cwd":"%s","session_id":"test3"}' "$DUMMY3" "$DUMMY3")
  echo "$INPUT3" | bash "$HOOK_STOP_HANDOFF" 2>/dev/null || true

  if [ -f "$DUMMY3/.harness/handoff.md" ]; then
    pass_test "Test 3: cold start (no trace) → fallback handoff written (safe side)"
  else
    fail_test "Test 3: cold start should fallback-write, none found"
  fi
}

# --------------------------------------------------------------------------
# Test 4: force flag → bypass gate, handoff written, flag auto-cleared
# --------------------------------------------------------------------------
run_test4() {
  DUMMY4="$DUMMY_BASE/test4"
  mkdir -p "$DUMMY4/.harness"
  printf '[2026-05-05T00:00:00+0000] ctx-monitor: total=300000 window=1000000 pct=30%%\n' \
    >> "$DUMMY4/.harness/hook-trace.log"
  touch "$DUMMY4/.harness/handoff-force.flag"
  echo '{"type":"assistant","message":{"model":"claude-opus-4-7","usage":{"input_tokens":300000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"output_tokens":200}}}' \
    > "$DUMMY4/transcript.jsonl"

  INPUT4=$(printf '{"transcript_path":"%s/transcript.jsonl","cwd":"%s","session_id":"test4"}' "$DUMMY4" "$DUMMY4")
  echo "$INPUT4" | bash "$HOOK_STOP_HANDOFF" 2>/dev/null || true

  HANDOFF_OK=0; FLAG_GONE=0
  [ -f "$DUMMY4/.harness/handoff.md" ] && HANDOFF_OK=1
  [ ! -f "$DUMMY4/.harness/handoff-force.flag" ] && FLAG_GONE=1

  if [ "$HANDOFF_OK" -eq 1 ] && [ "$FLAG_GONE" -eq 1 ]; then
    pass_test "Test 4: force flag → handoff written + flag auto-cleared"
  else
    fail_test "Test 4: force flag failed (handoff=$HANDOFF_OK flag_gone=$FLAG_GONE)"
  fi
}

# --------------------------------------------------------------------------
# Test 5: env HARNESS_HANDOFF_PCT_THRESHOLD=50, ctx=60% → handoff written
# --------------------------------------------------------------------------
run_test5() {
  DUMMY5="$DUMMY_BASE/test5"
  mkdir -p "$DUMMY5/.harness"
  printf '[2026-05-05T00:00:00+0000] ctx-monitor: total=600000 window=1000000 pct=60%%\n' \
    >> "$DUMMY5/.harness/hook-trace.log"
  echo '{"type":"assistant","message":{"model":"claude-opus-4-7","usage":{"input_tokens":600000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"output_tokens":200}}}' \
    > "$DUMMY5/transcript.jsonl"

  INPUT5=$(printf '{"transcript_path":"%s/transcript.jsonl","cwd":"%s","session_id":"test5"}' "$DUMMY5" "$DUMMY5")
  echo "$INPUT5" | env HARNESS_HANDOFF_PCT_THRESHOLD=50 bash "$HOOK_STOP_HANDOFF" 2>/dev/null || true

  if [ -f "$DUMMY5/.harness/handoff.md" ]; then
    pass_test "Test 5: env threshold=50, ctx=60% → handoff written"
  else
    fail_test "Test 5: env threshold=50, ctx=60% should write handoff, none found"
  fi
}

# --------------------------------------------------------------------------
# Test 6: post-tool model-aware — Haiku transcript → window=200000
# --------------------------------------------------------------------------
run_test6() {
  DUMMY6="$DUMMY_BASE/test6"
  mkdir -p "$DUMMY6/.harness"
  TRANSCRIPT6="$DUMMY6/transcript.jsonl"
  printf '{"type":"assistant","message":{"model":"claude-haiku-4-5-20251001","usage":{"input_tokens":100,"cache_read_input_tokens":10000,"cache_creation_input_tokens":5000,"output_tokens":200}}}\n' \
    > "$TRANSCRIPT6"
  INPUT6=$(printf '{"transcript_path":"%s","cwd":"%s","session_id":"test6"}' "$TRANSCRIPT6" "$DUMMY6")

  echo "$INPUT6" | bash "$HOOK_POST_TOOL" 2>&1 | head -5 || true

  if grep -q "window=200000" "$DUMMY6/.harness/hook-trace.log" 2>/dev/null; then
    pass_test "Test 6: Haiku transcript → window=200000"
  else
    fail_test "Test 6: Haiku transcript — expected window=200000, got: $(cat "$DUMMY6/.harness/hook-trace.log" 2>/dev/null || echo '<empty>')"
  fi
}

# --------------------------------------------------------------------------
# Test 7: post-tool model-aware — Opus transcript → window=1000000
# --------------------------------------------------------------------------
run_test7() {
  DUMMY7="$DUMMY_BASE/test7"
  mkdir -p "$DUMMY7/.harness"
  TRANSCRIPT7="$DUMMY7/transcript.jsonl"
  printf '{"type":"assistant","message":{"model":"claude-opus-4-7","usage":{"input_tokens":100,"cache_read_input_tokens":10000,"cache_creation_input_tokens":5000,"output_tokens":200}}}\n' \
    > "$TRANSCRIPT7"
  INPUT7=$(printf '{"transcript_path":"%s","cwd":"%s","session_id":"test7"}' "$TRANSCRIPT7" "$DUMMY7")

  echo "$INPUT7" | bash "$HOOK_POST_TOOL" 2>&1 | head -5 || true

  if grep -q "window=1000000" "$DUMMY7/.harness/hook-trace.log" 2>/dev/null; then
    pass_test "Test 7: Opus transcript → window=1000000"
  else
    fail_test "Test 7: Opus transcript — expected window=1000000"
  fi
}

# --------------------------------------------------------------------------
# Run
# --------------------------------------------------------------------------
if [ "$POST_TOOL_ONLY" -eq 1 ]; then
  echo "--- [--post-tool-only mode: running Test 6+7 only] ---"
  run_test6
  run_test7
else
  if [ -f "$HOOK_STOP_HANDOFF" ]; then
    echo "--- Running Test 1-5 (stop-handoff PCT gate) ---"
    run_test1
    run_test2
    run_test3
    run_test4
    run_test5
  else
    echo "--- [SKIP Test 1-5: stop-handoff hook not found at $HOOK_STOP_HANDOFF] ---"
  fi
  echo ""
  echo "--- Running Test 6-7 (post-tool model-aware WINDOW) ---"
  run_test6
  run_test7
fi

echo ""
echo "=== SUMMARY: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

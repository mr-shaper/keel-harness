#!/usr/bin/env bash
# post-tool-context-monitor.sh — PostToolUse hook (alpha.4 NEW)
#
# Computes context% from the transcript's last assistant message usage on every
# tool call. Persists total/window/pct to .harness/hook-trace.log. Emits stderr
# alerts at 60% and 70%. The 70% line is a HARD STOP nudge to start a fresh
# session. The 60% line writes .harness/handoff-required.flag and emits a soft
# warning.
#
# Algorithm (matches upstream claude-hud src/stdin.ts:134-141 getTotalTokens):
#   total  = cache_read + cache_creation + input        (output_tokens excluded)
#   window = 200000 if model id matches *haiku*, else 1000000
#            (HARNESS_CTX_WINDOW env override applies to non-Haiku branch)
#   pct    = total * 100 / window
#
# Exit: always 0 (best-effort, never block tool execution)

set -uo pipefail

INPUT="$(cat || true)"
[ -n "$INPUT" ] || exit 0

PROJECT_DIR="$(jq -r '.cwd // empty' <<<"$INPUT" 2>/dev/null || true)"
[ -n "$PROJECT_DIR" ] || PROJECT_DIR="$PWD"

# Zero-intrusion: non-harness project (no .harness/) → silent exit
[ -d "$PROJECT_DIR/.harness" ] || exit 0

# Heartbeat update (independent of transcript parsing — Bash/Read tools without
# usage info still need to update last_heartbeat)
STATE="$PROJECT_DIR/.harness/state"
if [ -f "$STATE" ] && [ -w "$STATE" ]; then
  NOW_TS="$(date '+%Y-%m-%dT%H:%M:%S%z')"
  TMP_STATE="$STATE.tmp.$$"
  if grep -q '^last_heartbeat=' "$STATE" 2>/dev/null; then
    sed "s|^last_heartbeat=.*$|last_heartbeat=$NOW_TS|" "$STATE" > "$TMP_STATE" && mv "$TMP_STATE" "$STATE"
  else
    { cat "$STATE"; echo "last_heartbeat=$NOW_TS"; } > "$TMP_STATE" && mv "$TMP_STATE" "$STATE"
  fi
fi

TRANSCRIPT="$(jq -r '.transcript_path // empty' <<<"$INPUT" 2>/dev/null || true)"
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || exit 0

# Last assistant message usage (50-line tail is enough to capture the most recent assistant turn)
LAST_USAGE="$(tail -n 50 "$TRANSCRIPT" 2>/dev/null \
  | jq -sc '[.[] | select(.type=="assistant" and (.message.usage // empty))] | last | .message.usage // empty' 2>/dev/null || true)"
[ -n "$LAST_USAGE" ] && [ "$LAST_USAGE" != "null" ] || exit 0

CR=$(jq -r '.cache_read_input_tokens // 0' <<<"$LAST_USAGE" 2>/dev/null || echo 0)
CC=$(jq -r '.cache_creation_input_tokens // 0' <<<"$LAST_USAGE" 2>/dev/null || echo 0)
IN=$(jq -r '.input_tokens // 0' <<<"$LAST_USAGE" 2>/dev/null || echo 0)
# output_tokens intentionally excluded — alignment with claude-hud getTotalTokens

TOTAL=$(( CR + CC + IN ))

# Model-aware WINDOW: detect from transcript's last assistant.message.model
LAST_MSG_MODEL=$(tail -n 50 "$TRANSCRIPT" 2>/dev/null \
  | jq -sc '[.[] | select(.type=="assistant" and .message.model)] | last | .message.model // empty' 2>/dev/null \
  | tr -d '"' || echo "")
case "$LAST_MSG_MODEL" in
  *haiku*) WINDOW=200000 ;;
  *)       WINDOW=${HARNESS_CTX_WINDOW:-1000000} ;;
esac

[ "$TOTAL" -gt 0 ] && [ "$WINDOW" -gt 0 ] || exit 0

PCT=$(( TOTAL * 100 / WINDOW ))

# Persist trace
TRACE="$PROJECT_DIR/.harness/hook-trace.log"
mkdir -p "$(dirname "$TRACE")"
printf '[%s] ctx-monitor: total=%d window=%d pct=%d%%\n' \
  "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$TOTAL" "$WINDOW" "$PCT" >> "$TRACE" 2>/dev/null || true

# Threshold alerts (stderr only, non-blocking)
if [ "$PCT" -ge 70 ]; then
  echo "⚠️  [harness] context ${PCT}% / 70% HARD STOP — start a fresh session (handoff will be written by the Stop hook)" >&2
elif [ "$PCT" -ge 60 ]; then
  printf 'HANDOFF_REQUIRED:ctx%dpct:%s:soft\n' \
    "$PCT" "$(date '+%Y-%m-%dT%H:%M:%S%z')" \
    >> "$PROJECT_DIR/.harness/handoff-required.flag" 2>/dev/null || true
  echo "🟡 [harness] context ${PCT}% / 60% — wrap up: are core decisions locked? Is the next step clear? (soft warn)" >&2
fi

exit 0

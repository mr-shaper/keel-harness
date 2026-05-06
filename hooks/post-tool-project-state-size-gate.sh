#!/usr/bin/env bash
# post-tool-project-state-size-gate.sh — PostToolUse hook (alpha.7 NEW)
#
# Enforces a size contract on PROJECT_STATE.md (the harness backbone file).
# When PROJECT_STATE.md crosses the alert threshold, emit a [SIZE-GATE-ALERT]
# stderr line and append to .harness/alert.log + hook-trace.log so the user
# notices and can collapse the file into .harness/sprint-history/ partitions.
#
# Algorithm:
#   1. Read stdin tool_input.file_path
#   2. If file_path does NOT contain "PROJECT_STATE.md" → exit 0 (silent skip)
#   3. If file does not yet exist → exit 0 (race / pre-creation)
#   4. wc -l file → LOC
#   5. If LOC > THRESHOLD (180): stderr alert + append alert.log + hook-trace.log
#   6. exit 0 ALWAYS — the gate is alert-only, never blocks Write/Edit (L43)
#
# L43 strictly:
#   - matcher MUST be a literal whitelist `Write|Edit|MultiEdit` in
#     settings.json — never `*` (a `*` matcher would let this hook fire on
#     every tool call and risk self-locking; whitelist preserves L43).
#   - exit code is always 0 even on alert — the user is notified, not blocked.
#
# Spec reference: docs/r15-and-l44-candidate.md (R15 three-piece pattern,
# L44 candidate forcing-function hook law).

set -euo pipefail

THRESHOLD=180
HARD_CAP=200

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

# Only fire if file_path mentions PROJECT_STATE.md
[[ "$FILE_PATH" == *"PROJECT_STATE.md"* ]] || exit 0

# File may not exist yet (pre-creation race) — silent skip
[[ -f "$FILE_PATH" ]] || exit 0

LOC=$(wc -l < "$FILE_PATH" | tr -d ' ')

if [[ "$LOC" -gt "$THRESHOLD" ]]; then
  MSG="[SIZE-GATE-ALERT] PROJECT_STATE.md = $LOC LOC > $THRESHOLD threshold ($HARD_CAP hard cap)"
  echo "$MSG" >&2

  # Resolve .harness dir relative to PROJECT_STATE.md location
  HARNESS_DIR=$(dirname "$FILE_PATH")
  TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S%z')
  echo "[$TIMESTAMP] $MSG" >> "$HARNESS_DIR/alert.log"            2>/dev/null || true
  echo "[$TIMESTAMP] [SIZE-GATE] PROJECT_STATE.md=$LOC LOC file=$FILE_PATH" >> "$HARNESS_DIR/hook-trace.log" 2>/dev/null || true
fi

exit 0

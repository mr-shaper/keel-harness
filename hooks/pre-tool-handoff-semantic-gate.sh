#!/usr/bin/env bash
# pre-tool-handoff-semantic-gate.sh — PreToolUse Write hook
# Job: BLOCK writing wrong-session handoff file (wrong S-number).
# Parse target file path from JSON .tool_input.file_path
# Exit 0 = pass-through, Exit 2 = BLOCK

set -uo pipefail
trap 'exit 0' ERR

# ── Read stdin (JSON payload) ─────────────────────────────────────────────────
PAYLOAD=""
if [ -t 0 ]; then
  PAYLOAD="{}"
else
  PAYLOAD="$(cat 2>/dev/null || echo "{}")"
fi
[[ -z "${PAYLOAD}" ]] && PAYLOAD="{}"

# ── Extract target file path ──────────────────────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  TARGET_FILE="$(echo "${PAYLOAD}" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")"
else
  TARGET_FILE="$(python3 -c "
import json, sys
try:
    d = json.loads(sys.argv[1])
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" "${PAYLOAD}" 2>/dev/null || echo "")"
fi

# ── Only check handoff-S<N>-to-S<M>.md patterns ──────────────────────────────
BASENAME="$(basename "${TARGET_FILE}" 2>/dev/null || echo "")"
if ! echo "${BASENAME}" | grep -qE '^handoff-S[0-9]+-to-S[0-9]+\.md$'; then
  exit 0
fi

# ── Extract S-numbers from target filename ────────────────────────────────────
FROM_N="$(echo "${BASENAME}" | grep -oE 'S[0-9]+' | head -1 | tr -d 'S')"
TO_N="$(echo "${BASENAME}" | grep -oE 'S[0-9]+' | tail -1 | tr -d 'S')"

# ── Resolve repo root ─────────────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HARNESS_DIR="${REPO_ROOT}/.harness"

# ── Compute expected next session N ──────────────────────────────────────────
EXISTING_COUNT="$(ls "${HARNESS_DIR}"/handoff-S*-to-S*.md 2>/dev/null | wc -l | tr -d ' ')"
EXPECTED_TO="$(( EXISTING_COUNT + 1 ))"
EXPECTED_FROM="${EXISTING_COUNT}"

# ── Validate ──────────────────────────────────────────────────────────────────
if [[ "${FROM_N}" != "${EXPECTED_FROM}" || "${TO_N}" != "${EXPECTED_TO}" ]]; then
  echo "[handoff-semantic-gate] BLOCKED: Wrong handoff filename." >&2
  echo "[handoff-semantic-gate]   Expected: handoff-S${EXPECTED_FROM}-to-S${EXPECTED_TO}.md" >&2
  echo "[handoff-semantic-gate]   Got:      ${BASENAME}" >&2
  exit 2
fi

exit 0

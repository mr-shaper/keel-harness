#!/usr/bin/env bash
# pre-tool-handoff-read-gate.sh — PreToolUse Write|Edit|Bash hook
# Job: Block writes/edits when latest handoff hasn't been Read yet.
# Acknowledgement sentinel: .harness/must-ack-done.flag
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

# ── resolve_harness_root: three-path fallback ─────────────────────────────────
# Returns 0 and sets HARNESS_DIR when a valid .harness/ dir is found.
# Returns 1 when no valid root is found (caller should exit 0 silently).
resolve_harness_root() {
  local candidate

  # Priority 1: git repo root (current behaviour)
  candidate="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "${candidate}" && -d "${candidate}/.harness" ]]; then
    HARNESS_DIR="${candidate}/.harness"
    return 0
  fi

  # Priority 2: HARNESS_ROOT env var
  if [[ -n "${HARNESS_ROOT:-}" && -d "${HARNESS_ROOT}/.harness" ]]; then
    HARNESS_DIR="${HARNESS_ROOT}/.harness"
    return 0
  fi

  # Priority 3: silent OK — not a harness project
  return 1
}

# ── Resolve harness dir ───────────────────────────────────────────────────────
HARNESS_DIR=""
if ! resolve_harness_root; then
  exit 0
fi

# ── Skip if no handoff files exist (no prior session to ack) ─────────────────
HANDOFF_COUNT="$(ls "${HARNESS_DIR}"/handoff*.md 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${HANDOFF_COUNT}" -eq 0 ]]; then
  exit 0
fi

# ── Check sentinel ────────────────────────────────────────────────────────────
ACK_FLAG="${HARNESS_DIR}/must-ack-done.flag"
if [[ -f "${ACK_FLAG}" ]]; then
  exit 0
fi

# ── BLOCK: sentinel absent, handoff not yet acknowledged ─────────────────────
echo "[handoff-read-gate] BLOCKED: Read latest .harness/handoff*.md first, then:" >&2
echo "[handoff-read-gate]   touch .harness/must-ack-done.flag" >&2
echo "[handoff-read-gate] before any Write/Edit/Bash in this session." >&2
exit 2

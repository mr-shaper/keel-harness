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

# ── Resolve repo root ─────────────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HARNESS_DIR="${REPO_ROOT}/.harness"

# ── Skip if not a harness project ────────────────────────────────────────────
if [[ ! -d "${HARNESS_DIR}" ]]; then
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

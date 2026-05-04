#!/usr/bin/env bash
# post-tool-chmod-ci-gate.sh — PostToolUse Write|Edit hook
# Job: Ensure executable bit on .sh files written/edited.
# Exit: always 0 (informational)

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

# ── Only act on .sh files ─────────────────────────────────────────────────────
if [[ "${TARGET_FILE}" != *.sh ]]; then
  exit 0
fi

# ── File must exist ───────────────────────────────────────────────────────────
if [[ ! -f "${TARGET_FILE}" ]]; then
  exit 0
fi

# ── Set executable bit ────────────────────────────────────────────────────────
chmod +x "${TARGET_FILE}" 2>/dev/null || true
echo "[chmod-ci-gate] +x ${TARGET_FILE}" >&2

exit 0

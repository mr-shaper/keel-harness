#!/usr/bin/env bash
# user-prompt-l42-workflow-trigger-gate.sh — UserPromptSubmit hook
# Job: Detect L42 trigger words in user prompt; touch flag files.
# Exit: always 0 (informational only, no BLOCK)

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

# ── Extract user prompt text ──────────────────────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  PROMPT_TEXT="$(echo "${PAYLOAD}" | jq -r '.prompt // ""' 2>/dev/null || echo "")"
else
  PROMPT_TEXT="$(python3 -c "
import json, sys
try:
    d = json.loads(sys.argv[1])
    print(d.get('prompt', ''))
except Exception:
    print('')
" "${PAYLOAD}" 2>/dev/null || echo "")"
fi

# ── Resolve harness dir ───────────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HARNESS_DIR="${REPO_ROOT}/.harness"

# ── L42 trigger words (case-insensitive) ─────────────────────────────────────
declare -a TRIGGER_WORDS=(
  "harness"
  "oodc"
  "pua"
  "superpower"
  "nested parallel"
  "嵌套并行"
  "p10-9-8-7"
  "4-layer nested"
)

# ── Scan and touch flags ──────────────────────────────────────────────────────
HITS=()
PROMPT_LOWER="$(echo "${PROMPT_TEXT}" | tr '[:upper:]' '[:lower:]' 2>/dev/null || echo "${PROMPT_TEXT}")"

for word in "${TRIGGER_WORDS[@]}"; do
  word_lower="$(echo "${word}" | tr '[:upper:]' '[:lower:]' 2>/dev/null || echo "${word}")"
  if echo "${PROMPT_LOWER}" | grep -qF "${word_lower}" 2>/dev/null; then
    HITS+=("${word}")
    # Touch flag only if harness dir exists
    if [[ -d "${HARNESS_DIR}" ]]; then
      SAFE_WORD="$(echo "${word}" | tr ' ' '-' | tr -cd 'a-zA-Z0-9_-')"
      touch "${HARNESS_DIR}/l42-trigger-${SAFE_WORD}.flag" 2>/dev/null || true
    fi
  fi
done

# ── Output informational message if hits ─────────────────────────────────────
if [[ ${#HITS[@]} -gt 0 ]]; then
  HIT_LIST="$(IFS=', '; echo "${HITS[*]}")"
  echo "[L42] Detected trigger words: ${HIT_LIST}" >&2
fi

exit 0

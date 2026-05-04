#!/usr/bin/env bash
# pre-tool-plan-quality-gate.sh — PreToolUse Write hook
# Job: Plan files must include Romeo 6-dim self-audit >= 0.99.
# Trigger: target matches **/plans/**/*.md OR path contains 'plan' AND ends .md
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

# ── Extract target file path and content ─────────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  TARGET_FILE="$(echo "${PAYLOAD}" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")"
  CONTENT="$(echo "${PAYLOAD}" | jq -r '.tool_input.content // ""' 2>/dev/null || echo "")"
else
  TARGET_FILE="$(python3 -c "
import json, sys
try:
    d = json.loads(sys.argv[1])
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" "${PAYLOAD}" 2>/dev/null || echo "")"
  CONTENT="$(python3 -c "
import json, sys
try:
    d = json.loads(sys.argv[1])
    print(d.get('tool_input', {}).get('content', ''))
except Exception:
    print('')
" "${PAYLOAD}" 2>/dev/null || echo "")"
fi

# ── Check if this is a plan file ──────────────────────────────────────────────
is_plan_file() {
  local fpath="$1"
  # Must end in .md
  [[ "${fpath}" != *.md ]] && return 1
  # Either in plans/ directory OR path contains 'plan' (case-insensitive)
  if echo "${fpath}" | grep -qiE '(^|/)plans?/' 2>/dev/null; then
    return 0
  fi
  if echo "${fpath}" | grep -qi 'plan' 2>/dev/null; then
    return 0
  fi
  return 1
}

if ! is_plan_file "${TARGET_FILE}"; then
  exit 0
fi

# ── Check content is non-empty ────────────────────────────────────────────────
if [[ -z "${CONTENT}" ]]; then
  # No content to check — pass through
  exit 0
fi

# ── Romeo 6 dimensions (case-insensitive check) ───────────────────────────────
DIMS=("Honesty" "Ownership" "TechDepth\|Tech Depth" "Pattern Replay\|PatternReplay" "Density" "Candidates")
DIM_NAMES=("Honesty" "Ownership" "TechDepth" "PatternReplay" "Density" "Candidates")

MISSING=()
for i in "${!DIMS[@]}"; do
  pattern="${DIMS[$i]}"
  name="${DIM_NAMES[$i]}"
  if ! echo "${CONTENT}" | grep -qiE "${pattern}" 2>/dev/null; then
    MISSING+=("${name}")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  MISSING_LIST="$(IFS='/'; echo "${MISSING[*]}")"
  echo "[plan-quality-gate] BLOCKED: Plan missing Romeo 6-dim audit." >&2
  echo "[plan-quality-gate] Missing dimensions: ${MISSING_LIST}" >&2
  echo "[plan-quality-gate] Required: Honesty/Ownership/TechDepth/PatternReplay/Density/Candidates" >&2
  exit 2
fi

# ── Attempt score extraction: look for decimal scores near each dim ───────────
SCORES=()
parse_scores() {
  python3 - "${CONTENT}" <<'PYEOF' 2>/dev/null || true
import sys, re

content = sys.argv[1] if len(sys.argv) > 1 else ""
dims = ["Honesty", "Ownership", "Tech.?Depth", "Pattern.?Replay", "Density", "Candidates"]
scores = []
for dim in dims:
    # Find dim heading, then look for a score in the next ~200 chars
    m = re.search(dim, content, re.IGNORECASE)
    if m:
        window = content[m.start():m.start()+300]
        score_m = re.search(r'\b(0\.\d{2})\b', window)
        if score_m:
            scores.append(float(score_m.group(1)))
if scores:
    avg = sum(scores) / len(scores)
    print(f"{avg:.4f}:{len(scores)}")
else:
    print("unparseable")
PYEOF
}

SCORE_RESULT="$(parse_scores)"

if [[ "${SCORE_RESULT}" == "unparseable" || -z "${SCORE_RESULT}" ]]; then
  # All 6 dims present but scores unparseable — WARN and pass through
  echo "[plan-quality-gate] WARN: All 6 Romeo dims present but scores unparseable. Verify manually." >&2
  exit 0
fi

AVG_SCORE="$(echo "${SCORE_RESULT}" | cut -d: -f1)"
SCORE_COUNT="$(echo "${SCORE_RESULT}" | cut -d: -f2)"

# Compare avg to 0.99 using python3 (bash can't do float comparison)
BELOW_THRESHOLD="$(python3 -c "
import sys
try:
    avg = float('${AVG_SCORE}')
    print('yes' if avg < 0.99 else 'no')
except Exception:
    print('unparseable')
" 2>/dev/null || echo "unparseable")"

if [[ "${BELOW_THRESHOLD}" == "yes" ]]; then
  echo "[plan-quality-gate] BLOCKED: Plan Romeo 6-dim avg ${AVG_SCORE} < 0.99 hardcore threshold." >&2
  echo "[plan-quality-gate] Scores parsed from ${SCORE_COUNT} dimensions. Raise all dims to >= 0.99." >&2
  exit 2
elif [[ "${BELOW_THRESHOLD}" == "unparseable" ]]; then
  echo "[plan-quality-gate] WARN: Score comparison failed (${AVG_SCORE}). Verify manually." >&2
  exit 0
fi

# All 6 dims present, avg >= 0.99
echo "[plan-quality-gate] Romeo 6-dim audit OK (avg=${AVG_SCORE}, n=${SCORE_COUNT})" >&2
exit 0

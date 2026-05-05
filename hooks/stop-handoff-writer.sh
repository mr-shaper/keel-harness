#!/usr/bin/env bash
# stop-handoff-writer.sh — Stop event hook (Layer 0 element b)
# Job: Mechanically extract 7-field handoff and write .harness/handoff.md
# ZERO AI summary — jq + git only.
# Exit: always 0 (best-effort, never block session end)

set -uo pipefail
# Note: removed `trap 'exit 0' ERR` (alpha.3) — on macOS bash 3.2, ERR trap fires
# under pipefail even without `set -e`, which prematurely exited the script when
# benign no-match globs (e.g. `ls handoff-S*-to-S*.md` in a fresh project)
# returned non-zero. We now guard the specific risky commands with `|| true` /
# `2>/dev/null` rather than blanket-suppressing every error. Best-effort intent
# preserved: every individual write is best-effort and the final `exit 0`
# guarantees the hook never blocks session end.

# ── Graceful JSON parse with jq or python3 fallback ──────────────────────────
parse_session_id() {
  local payload="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "${payload}" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown"
  else
    python3 -c "
import json, sys
try:
    d = json.loads(sys.argv[1])
    print(d.get('session_id', 'unknown'))
except Exception:
    print('unknown')
" "${payload}" 2>/dev/null || echo "unknown"
  fi
}

# ── Read stdin ────────────────────────────────────────────────────────────────
PAYLOAD=""
if [ -t 0 ]; then
  PAYLOAD="{}"
else
  PAYLOAD="$(cat 2>/dev/null || echo "{}")"
fi
[[ -z "${PAYLOAD}" ]] && PAYLOAD="{}"

# ── Resolve project dir (JSON cwd > git toplevel > pwd) ──────────────────────
# Claude Code's hook contract provides cwd in the stdin payload; honor it first
# so test fixtures and IDE-launched sessions land on the right .harness/ dir.
# Fall back to git toplevel (covers OSS users who bash-launch outside Claude
# Code), then pwd as a last resort.
PROJECT_DIR=""
if command -v jq >/dev/null 2>&1; then
  PROJECT_DIR="$(jq -r '.cwd // empty' <<<"${PAYLOAD}" 2>/dev/null || true)"
fi
if [[ -z "${PROJECT_DIR}" || ! -d "${PROJECT_DIR}" ]]; then
  PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
REPO_ROOT="${PROJECT_DIR}"
HARNESS_DIR="${PROJECT_DIR}/.harness"
if [[ ! -d "${HARNESS_DIR}" ]]; then
  exit 0
fi

# ── Context-aware gate (alpha.4) ─────────────────────────────────────────────
# Skip handoff when context% < threshold (default 70). Reads latest pct from
# .harness/hook-trace.log (post-tool-context-monitor writes it). Empty / missing
# trace → fallback to original write path (safe side, never lose a handoff).
HARNESS_HANDOFF_PCT_THRESHOLD="${HARNESS_HANDOFF_PCT_THRESHOLD:-70}"
HARNESS_FORCE_FLAG="${HARNESS_DIR}/handoff-force.flag"
HOOK_TRACE="${HARNESS_DIR}/hook-trace.log"
NOW_TS="$(date '+%Y-%m-%dT%H:%M:%S%z')"

if [[ -f "${HARNESS_FORCE_FLAG}" ]]; then
  # Force-flag escape: write handoff once, clear flag.
  if ! rm -f "${HARNESS_FORCE_FLAG}" 2>/dev/null; then
    printf '[%s] stop-handoff: FORCE_FLAG_RM_FAILED path=%s manual-clean-required\n' \
      "${NOW_TS}" "${HARNESS_FORCE_FLAG}" >> "${HOOK_TRACE}" 2>/dev/null || true
  fi
  # (continue to write — force mode bypasses gate)
else
  CTX_PCT_RAW="$( { tail -100 "${HOOK_TRACE}" 2>/dev/null \
    | grep -E 'ctx-monitor:.*pct=[0-9]+%' \
    | tail -1 \
    | sed -E 's|.*pct=([0-9]+)%.*|\1|' \
    | tr -d '[:space:]'; } || true )"
  CTX_PCT=""
  if [[ -n "${CTX_PCT_RAW}" ]] && printf '%s' "${CTX_PCT_RAW}" | grep -qE '^[0-9]+$'; then
    CTX_PCT="${CTX_PCT_RAW}"
  fi
  if [[ -n "${CTX_PCT}" ]] && [[ "${CTX_PCT}" -lt "${HARNESS_HANDOFF_PCT_THRESHOLD}" ]]; then
    printf '[%s] stop-handoff: SKIP ctx=%s%% < threshold=%s%%\n' \
      "${NOW_TS}" "${CTX_PCT}" "${HARNESS_HANDOFF_PCT_THRESHOLD}" \
      >> "${HOOK_TRACE}" 2>/dev/null || true
    exit 0
  fi
  # CTX_PCT empty (cold start / race / non-numeric) → fallback to original write path
fi

# ── Collect fields ────────────────────────────────────────────────────────────
SESSION_ID="$(parse_session_id "${PAYLOAD}")"
TRIGGER="stop"
ENDED="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)"
COMMIT_HASH="$(git -C "${REPO_ROOT}" rev-parse --short HEAD 2>/dev/null || echo "none")"
BRANCH="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
MODIFIED_FILES="$(git -C "${REPO_ROOT}" status --porcelain 2>/dev/null || echo "(none)")"

# ── last_user_prompt: tail transcript JSONL ──────────────────────────────────
LAST_USER_PROMPT="(unavailable)"
TRANSCRIPT_DIR="${HOME}/.claude/projects"
if [[ -n "${SESSION_ID}" && "${SESSION_ID}" != "unknown" ]]; then
  # Claude Code stores transcripts as ~/.claude/projects/-<path>/<session_id>.jsonl
  TRANSCRIPT_FILE="$(find "${TRANSCRIPT_DIR}" -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)"
  if [[ -f "${TRANSCRIPT_FILE}" ]]; then
    LAST_USER_PROMPT="$(grep '"role":"user"' "${TRANSCRIPT_FILE}" 2>/dev/null | tail -1 | \
      python3 -c "
import sys, json
try:
    line = sys.stdin.read().strip()
    d = json.loads(line)
    content = d.get('content', '')
    if isinstance(content, list):
        parts = [p.get('text','') for p in content if isinstance(p, dict) and p.get('type')=='text']
        content = ' '.join(parts)
    print(str(content)[:500])
except Exception:
    print('(parse-error)')
" 2>/dev/null || echo "(parse-error)")"
  fi
fi

# ── Smart next_action: pull from latest handoff-SN-to-SN+1.md if P9 already wrote one ──
# Iron rule: Stop hook does ZERO AI summary. But if P9/CEO inline-wrote a handoff
# with a real next_action, defer to that authoritative source instead of TBD placeholder.
NEXT_ACTION="TBD-next-action-absent"
NEXT_ACTION_SOURCE=""
# `find` succeeds with empty output on no-match (unlike `ls` which exits 1 and
# trips pipefail). Sort by mtime descending to mimic `ls -1t`.
LATEST_AUTHORITATIVE="$(find "${HARNESS_DIR}" -maxdepth 1 -name 'handoff-S*-to-S*.md' -type f -print0 2>/dev/null \
  | xargs -0 ls -1t 2>/dev/null \
  | head -1 || true)"
if [[ -n "${LATEST_AUTHORITATIVE}" ]] && [[ -f "${LATEST_AUTHORITATIVE}" ]]; then
  EXTRACTED="$(awk '/^next_action:/{flag=1} flag{print; if(/"$/) exit}' "${LATEST_AUTHORITATIVE}" 2>/dev/null \
    | sed 's/^next_action: *//;s/^"//;s/"$//' | head -c 2000)"
  if [[ -n "${EXTRACTED}" ]] && [[ "${EXTRACTED}" != "TBD-"* ]]; then
    NEXT_ACTION="${EXTRACTED}"
    NEXT_ACTION_SOURCE="${LATEST_AUTHORITATIVE##*/}"
  fi
fi

# ── Write handoff.md ─────────────────────────────────────────────────────────
HANDOFF_FILE="${HARNESS_DIR}/handoff.md"

cat > "${HANDOFF_FILE}" <<HANDOFF_EOF
# Harness Handoff (auto-generated by stop-handoff-writer.sh)

## §fields

| Field | Value |
|-------|-------|
| session_id | ${SESSION_ID} |
| trigger | ${TRIGGER} |
| ended | ${ENDED} |
| commit_hash | ${COMMIT_HASH} |
| branch | ${BRANCH} |

## §modified_files

\`\`\`
${MODIFIED_FILES}
\`\`\`

## §last_user_prompt

\`\`\`
${LAST_USER_PROMPT}
\`\`\`

## §next_action

${NEXT_ACTION}

${NEXT_ACTION_SOURCE:+_(source: ${NEXT_ACTION_SOURCE} authoritative; this Stop hook deferred to it)_}

## §verification-checklist

- [ ] Read this handoff file before any Write/Edit/Bash in next session
- [ ] Run \`touch .harness/must-ack-done.flag\` after reading
- [ ] Verify commit_hash matches expected work
- [ ] Confirm branch is correct

## §transcript-tail

session_id: ${SESSION_ID}
ended: ${ENDED}
HANDOFF_EOF

echo "[stop-handoff-writer] handoff written → ${HANDOFF_FILE} (session=${SESSION_ID})" >&2
exit 0

#!/usr/bin/env bash
# session-start-layer0-health.sh — SessionStart hook
# Job: Verify Layer 0 5 elements at session start. Informational only.
# STRICT: any unexpected error → exit 0. Never block session startup.
# Exit: always 0

set -uo pipefail
trap 'exit 0' ERR

# ── Read stdin (JSON payload — ignored for SessionStart, read to drain) ───────
if [ ! -t 0 ]; then
  cat >/dev/null 2>/dev/null || true
fi

# ── Layer 0 health check ──────────────────────────────────────────────────────
WARN_COUNT=0

warn() {
  echo "[layer0-health] WARN: $1" >&2
  WARN_COUNT=$(( WARN_COUNT + 1 ))
}

ok() {
  echo "[layer0-health] OK:   $1" >&2
}

# (a) HARNESS_HOME exists: ~/.claude/plugins/keel-harness-mp
HARNESS_HOME="${HOME}/.claude/plugins/keel-harness-mp"
if [[ -d "${HARNESS_HOME}" ]]; then
  ok "(a) HARNESS_HOME exists: ${HARNESS_HOME}"
else
  warn "(a) HARNESS_HOME missing: ${HARNESS_HOME}"
fi

# (b) At least 1 hook file present in HARNESS_HOME/hooks/
HOOK_COUNT=0
if [[ -d "${HARNESS_HOME}/hooks" ]]; then
  HOOK_COUNT="$(ls "${HARNESS_HOME}/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')"
fi
if [[ "${HOOK_COUNT}" -gt 0 ]]; then
  ok "(b) Hook files present: ${HOOK_COUNT} found"
else
  warn "(b) No hook .sh files found in ${HARNESS_HOME}/hooks/"
fi

# (c) ~/.claude/settings.json contains "harness" string
SETTINGS_FILE="${HOME}/.claude/settings.json"
if [[ -f "${SETTINGS_FILE}" ]]; then
  if grep -q "harness" "${SETTINGS_FILE}" 2>/dev/null; then
    ok "(c) settings.json contains 'harness' string"
  else
    warn "(c) settings.json exists but missing 'harness' registration"
  fi
else
  warn "(c) settings.json not found: ${SETTINGS_FILE}"
fi

# (d) ~/.claude/CLAUDE.md exists
GLOBAL_CLAUDE="${HOME}/.claude/CLAUDE.md"
if [[ -f "${GLOBAL_CLAUDE}" ]]; then
  ok "(d) ~/.claude/CLAUDE.md exists"
else
  warn "(d) ~/.claude/CLAUDE.md missing"
fi

# (e) CLAUDE.md contains "§harness mode" string
if [[ -f "${GLOBAL_CLAUDE}" ]]; then
  if grep -q "harness mode" "${GLOBAL_CLAUDE}" 2>/dev/null; then
    ok "(e) CLAUDE.md contains 'harness mode' section"
  else
    warn "(e) CLAUDE.md missing '§harness mode' section"
  fi
else
  warn "(e) Cannot check CLAUDE.md for 'harness mode' (file absent)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
if [[ "${WARN_COUNT}" -eq 0 ]]; then
  echo "[layer0-health] Layer 0 health: 5/5 OK" >&2
else
  echo "[layer0-health] Layer 0 health: $((5 - WARN_COUNT))/5 OK — ${WARN_COUNT} WARN(s)" >&2
  echo "[layer0-health] Run install.sh to repair. See docs/layer-0-spec.md for details." >&2
fi

exit 0

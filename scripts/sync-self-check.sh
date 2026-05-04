#!/usr/bin/env bash
# sync-self-check.sh — OSS 5-dimension evidence dump for maintainer evaluation
# Does NOT modify any files. Exit 0 always (evidence dump, not a gate).
# Usage: bash sync-self-check.sh

set -uo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
header() {
  echo ""
  echo "============================================================"
  echo "  $1"
  echo "============================================================"
}

kv() {
  printf "  %-28s %s\n" "$1:" "$2"
}

# ---------------------------------------------------------------------------
# Mode
# ---------------------------------------------------------------------------
# This script is read-only by design: it dumps evidence and exits 0.
# It never writes, modifies, or deletes any file. No flags are needed —
# the script's contract is "evidence in, no side effects."

# ---------------------------------------------------------------------------
# Path resolution
# ---------------------------------------------------------------------------
HOST="$(hostname)"
HARNESS_ROOT="${HARNESS_ROOT:-$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || pwd)}"

echo "sync-self-check.sh — OSS evidence dump"
kv "host"        "${HOST}"
kv "harness_root" "${HARNESS_ROOT}"
kv "mode"        "read-only"
kv "date"        "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# ---------------------------------------------------------------------------
# Layer A — Entity: directory structure + file counts
# ---------------------------------------------------------------------------
header "Layer A: Entity (dirs + file counts)"

for d in hooks plugins .harness templates docs; do
  target="${HARNESS_ROOT}/${d}"
  if [[ -d "${target}" ]]; then
    count="$(find "${target}" -maxdepth 2 -type f 2>/dev/null | wc -l | tr -d ' ')"
    kv "${d}/" "${count} files"
  else
    kv "${d}/" "[MISSING]"
  fi
done

echo ""
echo "  -- hooks/ listing --"
if [[ -d "${HARNESS_ROOT}/hooks" ]]; then
  ls "${HARNESS_ROOT}/hooks" 2>/dev/null | sed 's/^/    /'
else
  echo "    [hooks/ not found]"
fi

echo ""
echo "  -- .harness/ listing --"
if [[ -d "${HARNESS_ROOT}/.harness" ]]; then
  ls "${HARNESS_ROOT}/.harness" 2>/dev/null | sed 's/^/    /'
else
  echo "    [.harness/ not found]"
fi

# ---------------------------------------------------------------------------
# Layer B — Content: wc -l, md5, git file count
# ---------------------------------------------------------------------------
header "Layer B: Content (wc -l / md5 / git ls-files)"

KEY_FILES=(
  "HARNESS_BIBLE.md"
  "CLAUDE.md"
  "templates/settings.json.template"
  ".harness/state"
  ".harness/handoff.md"
)

for rel in "${KEY_FILES[@]}"; do
  full="${HARNESS_ROOT}/${rel}"
  if [[ -f "${full}" ]]; then
    lines="$(wc -l < "${full}" 2>/dev/null | tr -d ' ')"
    if command -v md5sum >/dev/null 2>&1; then
      md5="$(md5sum "${full}" 2>/dev/null | awk '{print $1}')"
    elif command -v md5 >/dev/null 2>&1; then
      md5="$(md5 -q "${full}" 2>/dev/null)"
    else
      md5="(md5 unavailable)"
    fi
    printf "  %-34s %5s lines  md5=%s\n" "${rel}" "${lines}" "${md5}"
  else
    kv "${rel}" "[MISSING]"
  fi
done

echo ""
git_count="$(git -C "${HARNESS_ROOT}" ls-files 2>/dev/null | wc -l | tr -d ' ')"
kv "git ls-files count" "${git_count}"

# ---------------------------------------------------------------------------
# Layer C — GATE: settings.json.template hook count + command paths
# ---------------------------------------------------------------------------
header "Layer C: GATE (settings.json.template hooks)"

SETTINGS_TPL="${HARNESS_ROOT}/templates/settings.json.template"
if [[ -f "${SETTINGS_TPL}" ]]; then
  if command -v jq >/dev/null 2>&1; then
    hook_events="$(jq '.hooks | keys | length' "${SETTINGS_TPL}" 2>/dev/null || echo 'jq-error')"
    kv "hook event types" "${hook_events}"
    jq -r '.hooks | to_entries[] | "\(.key): \(.value | length) entries"' "${SETTINGS_TPL}" 2>/dev/null \
      | sed 's/^/    /'
  else
    kv "jq" "[not installed — skipping hook parse]"
  fi

  echo ""
  echo "  -- command path existence check --"
  if command -v jq >/dev/null 2>&1; then
    jq -r '.. | objects | .command? // empty' "${SETTINGS_TPL}" 2>/dev/null \
      | sort -u \
      | while IFS= read -r cmd; do
          first_word="${cmd%% *}"
          if [[ -f "${first_word}" ]] || command -v "${first_word}" >/dev/null 2>&1; then
            printf "    [OK]     %s\n" "${cmd}"
          else
            printf "    [MISS]   %s\n" "${cmd}"
          fi
        done
  fi
else
  kv "settings.json.template" "[MISSING]"
fi

# ---------------------------------------------------------------------------
# Layer D — Config: env vars + git remote + git branch
# ---------------------------------------------------------------------------
header "Layer D: Config (env vars + git meta)"

kv "HARNESS_ROOT"  "${HARNESS_ROOT}"
kv "HARNESS_HOME"  "${HARNESS_HOME:-[unset]}"
kv "HOME"          "${HOME:-[unset]}"
kv "SHELL"         "${SHELL:-[unset]}"

echo ""
echo "  -- git remote -v --"
git -C "${HARNESS_ROOT}" remote -v 2>/dev/null | sed 's/^/    /' || echo "    [no remotes]"

echo ""
echo "  -- git branch --"
git -C "${HARNESS_ROOT}" branch --show-current 2>/dev/null | sed 's/^/    current: /'
git -C "${HARNESS_ROOT}" log --oneline -5 2>/dev/null | sed 's/^/    /'

# ---------------------------------------------------------------------------
# Layer E — Behavior fire: hook-trace.log tail + grep counts
# ---------------------------------------------------------------------------
header "Layer E: Behavior fire (hook-trace.log)"

TRACE_LOG="${HARNESS_ROOT}/.harness/hook-trace.log"
if [[ -f "${TRACE_LOG}" ]]; then
  total_lines="$(wc -l < "${TRACE_LOG}" 2>/dev/null | tr -d ' ')"
  compound_count="$(grep -c 'COMPOUND-CHECK' "${TRACE_LOG}" 2>/dev/null || echo 0)"
  l42_count="$(grep -c 'L42' "${TRACE_LOG}" 2>/dev/null || echo 0)"

  kv "trace log lines" "${total_lines}"
  kv "COMPOUND-CHECK hits" "${compound_count}"
  kv "L42 hits"           "${l42_count}"

  echo ""
  echo "  -- tail -n 30 --"
  tail -n 30 "${TRACE_LOG}" 2>/dev/null | sed 's/^/    /'
else
  kv "hook-trace.log" "[MISSING — hooks may not have fired yet]"
fi

# ---------------------------------------------------------------------------
# Footer
# ---------------------------------------------------------------------------
header "Summary"
kv "mode"     "read-only"
kv "modified" "0 files (evidence dump only)"
echo ""
echo "  Maintainer: review Layers A-E above, then self-evaluate sprint outcome."
echo "  Exit 0."

exit 0

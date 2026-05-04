#!/usr/bin/env bash
# tests/test-manifest-completeness.sh — TDD: every file in manifest.json kernel_files exists on disk
# Run: bash tests/test-manifest-completeness.sh
# Requires: jq

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${REPO_ROOT}/manifest.json"

# ── Test framework ────────────────────────────────────────────────────────────
PASS=0; FAIL=0

pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1"; echo "       $2"; (( FAIL++ )) || true; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  harness-engineering manifest completeness TDD"
echo "═══════════════════════════════════════════════════════"
echo ""

# ── Pre-flight: manifest.json and jq must exist ───────────────────────────────
echo "[0] pre-flight: manifest.json present + jq available"
if [[ ! -f "${MANIFEST}" ]]; then
  fail "manifest-present" "manifest.json not found at ${MANIFEST}"
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Results: 0/1 PASS, 1 MISSING (pre-flight failed)"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  fail "jq-available" "jq not found in PATH; install with: brew install jq / apt-get install jq"
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Results: 0/1 PASS, 1 MISSING (pre-flight failed)"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  exit 1
fi
pass "manifest.json present + jq available"
echo ""

# ── Case: iterate kernel_files and verify each file exists ───────────────────
echo "[1] test_kernel_files_present: all manifest.json kernel_files exist on disk"

MISSING=()
PRESENT=0
TOTAL=0

while IFS= read -r entry; do
  [[ -z "${entry}" ]] && continue
  TOTAL=$(( TOTAL + 1 ))
  if [[ -f "${REPO_ROOT}/${entry}" ]]; then
    PRESENT=$(( PRESENT + 1 ))
  else
    MISSING+=( "${entry}" )
  fi
done < <(jq -r '.kernel_files[]' "${MANIFEST}")

if [[ ${#MISSING[@]} -eq 0 ]]; then
  pass "test_kernel_files_present: ${PRESENT}/${TOTAL} kernel files PRESENT"
  echo ""
  echo "  Results: ${PRESENT}/${TOTAL} kernel files PRESENT"
else
  echo "  FAIL: test_kernel_files_present"
  for f in "${MISSING[@]}"; do
    echo "    MISSING: ${f}"
    (( FAIL++ )) || true
  done
  echo ""
  echo "  Results: ${PRESENT}/${TOTAL} PASS, ${#MISSING[@]} MISSING"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
TOTAL_TESTS=$(( PASS + FAIL ))
echo "  Results: ${PASS} PASS / ${FAIL} FAIL (total ${TOTAL_TESTS})"
echo "═══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] && exit 0 || exit 1

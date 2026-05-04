#!/usr/bin/env bash
# tests/test-pre-commit.sh — TDD 7-case suite for .git/hooks/pre-commit
# Run from any directory; each case uses an isolated temp git repo.

set -uo pipefail

PASS=0
FAIL=0
REAL_REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_SRC="${REAL_REPO}/.git/hooks/pre-commit"
MANIFEST_SRC="${REAL_REPO}/manifest.json"

# ── helpers ──────────────────────────────────────────────────────────────────
TMPDIR_BASE="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_BASE}"' EXIT

make_repo() {
  local dir="${TMPDIR_BASE}/repo_$1"
  mkdir -p "${dir}"
  git -C "${dir}" init -q
  git -C "${dir}" config user.name "Test"
  git -C "${dir}" config user.email "mrshaper@users.noreply.github.com"
  cp "${MANIFEST_SRC}" "${dir}/manifest.json"
  cp "${HOOK_SRC}" "${dir}/.git/hooks/pre-commit"
  chmod +x "${dir}/.git/hooks/pre-commit"
  echo "${dir}"
}

# Run hook with CWD = repo dir so git commands resolve to the temp repo
# Returns exit code; all hook output (stdout+stderr) suppressed.
run_hook() {
  local repo="$1"
  local rc=0
  (cd "${repo}" && .git/hooks/pre-commit) >/dev/null 2>&1 || rc=$?
  echo "${rc}"
}

# Run hook capturing combined stdout+stderr to a temp file.
# Usage: run_hook_capturing <repo> <outfile>
# Returns exit code via echo.
run_hook_capturing() {
  local repo="$1"
  local outfile="$2"
  local rc=0
  (cd "${repo}" && .git/hooks/pre-commit) >"${outfile}" 2>&1 || rc=$?
  echo "${rc}"
}

run_test() {
  local name="$1"
  local result="$2"   # actual exit code
  local expected="$3" # 0=expect pass, 1=expect abort
  if [[ "${result}" -eq "${expected}" ]]; then
    echo "  PASS: ${name}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${name} (got exit=${result}, expected=${expected})"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== pre-commit TDD 7-case suite ==="
echo ""

# ── Case 1: blacklist keyword blocks commit ───────────────────────────────────
echo "[1/7] test_blacklist_block: stage file containing 'mrshaper'"
REPO1="$(make_repo 1)"
echo "username: mrshaper" > "${REPO1}/dirty.txt"
git -C "${REPO1}" add dirty.txt manifest.json 2>/dev/null
RESULT="$(run_hook "${REPO1}" 2>/dev/null)"
run_test "test_blacklist_block" "${RESULT}" 1

# ── Case 2: clean file passes ─────────────────────────────────────────────────
echo "[2/7] test_clean_pass: stage a generic clean file"
REPO2="$(make_repo 2)"
echo "This is a generic readme file with no PII" > "${REPO2}/readme.txt"
git -C "${REPO2}" add readme.txt manifest.json 2>/dev/null
RESULT="$(run_hook "${REPO2}" 2>/dev/null)"
run_test "test_clean_pass" "${RESULT}" 0

# ── Case 3: wrong author email blocks commit ──────────────────────────────────
echo "[3/7] test_author_email_check: wrong email -> abort, then revert"
REPO3="$(make_repo 3)"
git -C "${REPO3}" config user.email "oss-test-author@example.test"
echo "clean content only" > "${REPO3}/file.txt"
git -C "${REPO3}" add file.txt manifest.json 2>/dev/null
RESULT="$(run_hook "${REPO3}" 2>/dev/null)"
run_test "test_author_email_check" "${RESULT}" 1
# Cleanup: revert email (repo is temp so it's disposable anyway)
git -C "${REPO3}" config user.email "mrshaper@users.noreply.github.com"

# ── Case 4: sk-ant pattern (regex) blocks commit ─────────────────────────────
echo "[4/7] test_sk_ant_block: stage file with 'sk-ant-abc123XYZ_456'"
REPO4="$(make_repo 4)"
echo "ANTHROPIC_KEY=sk-ant-abc123XYZ_456" > "${REPO4}/secrets.txt"
git -C "${REPO4}" add secrets.txt manifest.json 2>/dev/null
RESULT="$(run_hook "${REPO4}" 2>/dev/null)"
run_test "test_sk_ant_block" "${RESULT}" 1

# ── Case 5: manifest.json staged → SKIP, not BLOCK ───────────────────────────
echo "[5/7] test_manifest_skip: stage manifest.json (contains keyword literals) -> SKIP not BLOCK"
REPO5="$(make_repo 5)"
# manifest.json is already copied; re-stage it alone (no other files)
# It contains 'mrshaper', 'maintainer', etc. as keyword definitions
git -C "${REPO5}" add manifest.json 2>/dev/null
HOOK_OUT5="${TMPDIR_BASE}/hook_out5.txt"
RESULT="$(run_hook_capturing "${REPO5}" "${HOOK_OUT5}")"
HOOK_CONTENT5="$(cat "${HOOK_OUT5}" 2>/dev/null || true)"
# Expect exit 0 (SKIP), AND output should contain "SKIP manifest.json"
SKIP_MSG_FOUND=0
if echo "${HOOK_CONTENT5}" | grep -q "SKIP manifest.json"; then
  SKIP_MSG_FOUND=1
fi
if [[ "${RESULT}" -eq 0 && "${SKIP_MSG_FOUND}" -eq 1 ]]; then
  echo "  PASS: test_manifest_skip (exit=0, SKIP log found)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: test_manifest_skip (exit=${RESULT}, SKIP_MSG_FOUND=${SKIP_MSG_FOUND})"
  echo "  hook output: ${HOOK_CONTENT5}"
  FAIL=$((FAIL + 1))
fi

# ── Case 6: README with github.com/mrshaper URL → context filter exempts → PASS ──
echo "[6/7] test_github_url_context_filter: README.md with 'github.com/mrshaper/foo' -> PASS"
REPO6="$(make_repo 6)"
cat > "${REPO6}/README.md" <<'READMEEOF'
# harness-engineering

See the repo at https://github.com/mr-shaper/keel-harness for details.
Install: git clone https://github.com/mr-shaper/keel-harness.git

## Overview

This is a clean OSS project with no private data.
READMEEOF
git -C "${REPO6}" add README.md manifest.json 2>/dev/null
RESULT="$(run_hook "${REPO6}")"
run_test "test_github_url_context_filter" "${RESULT}" 0

# ── Case 7: BLOCK message includes hit keyword name ──────────────────────────
echo "[7/7] test_diagnostic_output: BLOCK message shows which keyword matched"
REPO7="$(make_repo 7)"
echo "config: oss-test-user@example.com" > "${REPO7}/leaky.txt"
git -C "${REPO7}" add leaky.txt manifest.json 2>/dev/null
HOOK_OUT7="${TMPDIR_BASE}/hook_out7.txt"
RESULT="$(run_hook_capturing "${REPO7}" "${HOOK_OUT7}")"
HOOK_CONTENT7="$(cat "${HOOK_OUT7}" 2>/dev/null || true)"
# Expect exit 1 (BLOCK) AND output must contain "hit keywords:" or "ABORT"
HIT_KEYWORD_FOUND=0
if echo "${HOOK_CONTENT7}" | grep -qE "(hit keywords:|ABORT.*leaky\.txt)"; then
  HIT_KEYWORD_FOUND=1
fi
if [[ "${RESULT}" -eq 1 && "${HIT_KEYWORD_FOUND}" -eq 1 ]]; then
  echo "  PASS: test_diagnostic_output (exit=1, hit keyword info found)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: test_diagnostic_output (exit=${RESULT}, HIT_KEYWORD_FOUND=${HIT_KEYWORD_FOUND})"
  echo "  hook output: ${HOOK_CONTENT7}"
  FAIL=$((FAIL + 1))
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
TOTAL=$((PASS + FAIL))
echo "${PASS}/${TOTAL} PASS"
if [[ "${FAIL}" -gt 0 ]]; then
  exit 1
fi
exit 0

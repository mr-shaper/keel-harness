#!/usr/bin/env bash
# tests/test-red-team.sh — Red-team 8-case suite for 5-layer PII protection
# Simulates attacker perspective: fresh isolated repo, grep + hook + gitleaks.
# Run: bash tests/test-red-team.sh
# No external deps required except jq + python3 (both required by sync.sh/hook anyway).

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC="${REPO_ROOT}/sync.sh"
HOOK_SRC="${REPO_ROOT}/hooks/pre-commit"
MANIFEST_SRC="${REPO_ROOT}/manifest.json"
FIXTURE_DIR="${REPO_ROOT}/tests/red-team"

PASS=0
FAIL=0

TMPDIR_BASE="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_BASE}"' EXIT

# ── Helpers ───────────────────────────────────────────────────────────────────

pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1"; echo "       $2"; (( FAIL++ )) || true; }

# Create an isolated git repo with manifest + pre-commit hook installed
make_repo() {
  local repo="${TMPDIR_BASE}/repo_$1"
  mkdir -p "${repo}"
  git -C "${repo}" init -q
  git -C "${repo}" config user.name "Test User"
  git -C "${repo}" config user.email "mrshaper@users.noreply.github.com"
  cp "${MANIFEST_SRC}" "${repo}/manifest.json"
  cp "${HOOK_SRC}" "${repo}/.git/hooks/pre-commit"
  chmod +x "${repo}/.git/hooks/pre-commit"
  echo "${repo}"
}

# Run pre-commit hook in a repo, return exit code
run_hook() {
  local repo="$1"
  local rc=0
  (cd "${repo}" && .git/hooks/pre-commit) >/dev/null 2>&1 || rc=$?
  echo "${rc}"
}


echo "=== Red-Team 8-case suite: 5-layer PII protection ==="
echo "    REPO_ROOT: ${REPO_ROOT}"
echo "    FIXTURE:   ${FIXTURE_DIR}"
echo ""

# ── Helper: build isolated sync sub-repo with patched manifest + copied sync.sh
# sync.sh derives REPO_ROOT from dirname of BASH_SOURCE[0], so we must copy
# sync.sh into the temp repo so REPO_ROOT resolves there (not the real repo).
make_sync_repo() {
  local label="$1"
  local fixture_rel="$2"  # relative path under CLAUDE_HOME (e.g. tests/red-team/fake-PII.md)
  local fixture_src="$3"  # absolute path to source fixture file
  local sr="${TMPDIR_BASE}/syncrepo_${label}"
  mkdir -p "${sr}"
  # Copy sync.sh so REPO_ROOT = sr
  cp "${SYNC}" "${sr}/sync.sh"
  # Build manifest pointing only to the fixture file
  python3 - <<PYEOF
import json
with open("${MANIFEST_SRC}") as f:
    m = json.load(f)
m["kernel_files"] = ["${fixture_rel}"]
m["manual_sync_files"] = []
with open("${sr}/manifest.json", "w") as f:
    json.dump(m, f, indent=2)
PYEOF
  # Build fake CLAUDE_HOME with the fixture file
  local fake_claude="${TMPDIR_BASE}/claude_${label}"
  mkdir -p "${fake_claude}/$(dirname "${fixture_rel}")"
  cp "${fixture_src}" "${fake_claude}/${fixture_rel}"
  echo "${sr}|${fake_claude}"
}

# ── Case 1: sync.sh export → fake-PII.md should be BLOCKED (Layer 2/3) ──────
echo "[1/8] test_sync_blocks_pii: sync.sh export with fake-PII.md as source"
SINFO1="$(make_sync_repo pii "tests/red-team/fake-PII.md" "${FIXTURE_DIR}/fake-PII.md")"
SR1="${SINFO1%%|*}"; CLAUDE1="${SINFO1##*|}"
STAGE1="${TMPDIR_BASE}/stage1"; mkdir -p "${STAGE1}"
RC1=0
HARNESS_TEST_MODE=1 \
  CLAUDE_HOME="${CLAUDE1}" \
  HARNESS_STAGING_DIR="${STAGE1}" \
  bash "${SR1}/sync.sh" export 2>/dev/null || RC1=$?
if [[ "${RC1}" -ne 0 ]]; then
  pass "test_sync_blocks_pii (sync.sh export blocked on fake-PII.md)"
else
  fail "test_sync_blocks_pii" "expected non-zero exit from sync.sh export; got 0"
fi

# ── Case 2: sync.sh export → fake-secrets.md should be BLOCKED ──────────────
echo "[2/8] test_sync_blocks_secrets: sync.sh export with fake-secrets.md as source"
SINFO2="$(make_sync_repo secrets "tests/red-team/fake-secrets.md" "${FIXTURE_DIR}/fake-secrets.md")"
SR2="${SINFO2%%|*}"; CLAUDE2="${SINFO2##*|}"
STAGE2="${TMPDIR_BASE}/stage2"; mkdir -p "${STAGE2}"
RC2=0
HARNESS_TEST_MODE=1 \
  CLAUDE_HOME="${CLAUDE2}" \
  HARNESS_STAGING_DIR="${STAGE2}" \
  bash "${SR2}/sync.sh" export 2>/dev/null || RC2=$?
if [[ "${RC2}" -ne 0 ]]; then
  pass "test_sync_blocks_secrets (sync.sh export blocked on fake-secrets.md)"
else
  fail "test_sync_blocks_secrets" "expected non-zero exit from sync.sh export; got 0"
fi

# ── Case 3: sync.sh export → clean.md should PASS ────────────────────────────
echo "[3/8] test_sync_passes_clean: sync.sh export with clean.md as source"
SINFO3="$(make_sync_repo clean "tests/red-team/clean.md" "${FIXTURE_DIR}/clean.md")"
SR3="${SINFO3%%|*}"; CLAUDE3="${SINFO3##*|}"
STAGE3="${TMPDIR_BASE}/stage3"; mkdir -p "${STAGE3}"
RC3=0
HARNESS_TEST_MODE=1 \
  CLAUDE_HOME="${CLAUDE3}" \
  HARNESS_STAGING_DIR="${STAGE3}" \
  bash "${SR3}/sync.sh" export 2>/dev/null || RC3=$?
if [[ "${RC3}" -eq 0 ]]; then
  pass "test_sync_passes_clean (sync.sh export allowed clean.md)"
else
  fail "test_sync_passes_clean" "expected exit 0 from sync.sh export; got ${RC3}"
fi

# ── Case 4: git pre-commit hook on staged fake-PII.md → BLOCK ────────────────
echo "[4/8] test_hook_blocks_pii: pre-commit hook blocks staged fake-PII.md"
REPO4="$(make_repo 4)"
cp "${FIXTURE_DIR}/fake-PII.md" "${REPO4}/attack-pii.md"
git -C "${REPO4}" add attack-pii.md manifest.json 2>/dev/null
RC4="$(run_hook "${REPO4}" 2>/dev/null)"
if [[ "${RC4}" -eq 1 ]]; then
  pass "test_hook_blocks_pii (pre-commit BLOCKED fake-PII.md)"
else
  fail "test_hook_blocks_pii" "expected exit 1 from pre-commit; got ${RC4}"
fi

# ── Case 5: git pre-commit hook on staged fake-secrets.md → BLOCK ────────────
echo "[5/8] test_hook_blocks_secrets: pre-commit hook blocks staged fake-secrets.md"
REPO5="$(make_repo 5)"
cp "${FIXTURE_DIR}/fake-secrets.md" "${REPO5}/attack-secrets.md"
git -C "${REPO5}" add attack-secrets.md manifest.json 2>/dev/null
RC5="$(run_hook "${REPO5}" 2>/dev/null)"
if [[ "${RC5}" -eq 1 ]]; then
  pass "test_hook_blocks_secrets (pre-commit BLOCKED fake-secrets.md)"
else
  fail "test_hook_blocks_secrets" "expected exit 1 from pre-commit; got ${RC5}"
fi

# ── Case 6: git pre-commit hook on staged clean.md → PASS ────────────────────
echo "[6/8] test_hook_passes_clean: pre-commit hook allows staged clean.md"
REPO6="$(make_repo 6)"
cp "${FIXTURE_DIR}/clean.md" "${REPO6}/baseline-clean.md"
git -C "${REPO6}" add baseline-clean.md manifest.json 2>/dev/null
RC6="$(run_hook "${REPO6}" 2>/dev/null)"
if [[ "${RC6}" -eq 0 ]]; then
  pass "test_hook_passes_clean (pre-commit allowed clean.md)"
else
  fail "test_hook_passes_clean" "expected exit 0 from pre-commit; got ${RC6}"
fi

# ── Case 7: gitleaks detect fake-secrets.md / fallback grep sk- regex ────────
echo "[7/8] test_gitleaks_detect_secrets: gitleaks (or fallback grep) detects secrets"
if command -v gitleaks > /dev/null 2>&1; then
  # gitleaks installed — run it against the fixture file
  GITLEAKS_RC=0
  gitleaks detect --no-git --source "${FIXTURE_DIR}/fake-secrets.md" >/dev/null 2>&1 || GITLEAKS_RC=$?
  if [[ "${GITLEAKS_RC}" -ne 0 ]]; then
    pass "test_gitleaks_detect_secrets (gitleaks detected secrets in fake-secrets.md)"
  else
    fail "test_gitleaks_detect_secrets" "gitleaks returned 0 (no hit) on fake-secrets.md — unexpected"
  fi
else
  # Fallback: grep regex sk-[a-zA-Z0-9_-]{20,} — must hit
  GREP_HIT=0
  grep -qE 'sk-[a-zA-Z0-9_-]{20,}' "${FIXTURE_DIR}/fake-secrets.md" && GREP_HIT=1 || true
  if [[ "${GREP_HIT}" -eq 1 ]]; then
    pass "test_gitleaks_detect_secrets (fallback grep sk-regex hit in fake-secrets.md)"
  else
    fail "test_gitleaks_detect_secrets" "fallback grep found no sk- pattern in fake-secrets.md"
  fi
fi

# ── Case 8: git log author email in main repo → only noreply email (B1) ──────
echo "[8/8] test_git_author_email: all commits in main repo use noreply email"
EMAILS="$(git -C "${REPO_ROOT}" log --format='%ae' 2>/dev/null | sort -u)"
BAD_EMAILS=0
FOUND_EMAILS=""
while IFS= read -r email; do
  [[ -z "${email}" ]] && continue
  FOUND_EMAILS="${FOUND_EMAILS} [${email}]"
  if [[ "${email}" != "mrshaper@users.noreply.github.com" ]]; then
    BAD_EMAILS=$(( BAD_EMAILS + 1 ))
  fi
done <<< "${EMAILS}"
if [[ "${BAD_EMAILS}" -eq 0 ]]; then
  pass "test_git_author_email (all commits use mrshaper@users.noreply.github.com)"
  echo "    found emails:${FOUND_EMAILS}"
else
  fail "test_git_author_email" "found non-noreply email(s) in git history:${FOUND_EMAILS}"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
TOTAL=$(( PASS + FAIL ))
echo "${PASS}/${TOTAL} PASS"
if [[ "${FAIL}" -gt 0 ]]; then
  exit 1
fi
exit 0

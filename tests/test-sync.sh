#!/usr/bin/env bash
# tests/test-sync.sh — TDD test suite for sync.sh (6 cases)
# Each case validates one sync.sh command behavior.
# Run: bash tests/test-sync.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC="${REPO_ROOT}/sync.sh"

# ── Test framework ────────────────────────────────────────────────────────────
PASS=0; FAIL=0

pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1"; echo "       $2"; (( FAIL++ )) || true; }

# Create isolated temp workspace for each test
new_workspace() {
  local ws
  ws="$(mktemp -d)"
  echo "$ws"
}

cleanup() { rm -rf "$1"; }

# ── Case 1: test_init ─────────────────────────────────────────────────────────
test_init() {
  echo "[1] test_init: manifest.json template created when absent"
  local ws; ws="$(new_workspace)"

  # No manifest.json exists in this workspace
  local result
  # Override MANIFEST path by symlinking sync.sh environment
  CLAUDE_HOME="${ws}/claude" \
  HARNESS_TEST_MODE=1 \
    bash "$SYNC" init 2>&1 | tail -1

  # init writes manifest.json to CWD — we need to run from ws
  pushd "$ws" > /dev/null
  cp "$SYNC" ./sync_local.sh
  # Patch: sync.sh uses REPO_ROOT which is dirname of sync.sh — simulate
  CLAUDE_HOME="${ws}/claude" \
  HARNESS_TEST_MODE=1 \
    bash "$SYNC" init > /dev/null 2>&1
  popd > /dev/null

  # Since REPO_ROOT in sync.sh = dirname of BASH_SOURCE[0] = $REPO_ROOT,
  # init writes to $REPO_ROOT/manifest.json. Test via a copy in ws.
  # Better approach: run init in a fresh sub-repo copy
  local sub; sub="$(new_workspace)"
  cp "$SYNC" "${sub}/sync.sh"
  pushd "$sub" > /dev/null
  bash "${sub}/sync.sh" init > /dev/null 2>&1
  popd > /dev/null

  if [[ -f "${sub}/manifest.json" ]]; then
    # Validate it's valid JSON with kernel_files array
    if jq -e '.kernel_files | type == "array"' "${sub}/manifest.json" > /dev/null 2>&1; then
      pass "manifest.json created with kernel_files array"
    else
      fail "manifest.json invalid JSON or missing kernel_files" "$(cat "${sub}/manifest.json")"
    fi
  else
    fail "manifest.json not created" "file missing at ${sub}/manifest.json"
  fi

  # Second run must NOT overwrite existing
  local mtime1; mtime1="$(stat -f '%m' "${sub}/manifest.json" 2>/dev/null || stat -c '%Y' "${sub}/manifest.json")"
  bash "${sub}/sync.sh" init > /dev/null 2>&1
  local mtime2; mtime2="$(stat -f '%m' "${sub}/manifest.json" 2>/dev/null || stat -c '%Y' "${sub}/manifest.json")"
  if [[ "$mtime1" == "$mtime2" ]]; then
    pass "manifest.json NOT overwritten on second init"
  else
    fail "manifest.json was overwritten on second init" ""
  fi

  cleanup "$sub"
  cleanup "$ws"
}

# ── Case 2: test_export_blacklist_block ───────────────────────────────────────
test_export_blacklist_block() {
  echo "[2] test_export_blacklist_block: export aborts on true-leak (API key sed cannot sanitize)"
  local ws; ws="$(new_workspace)"
  local fake_claude="${ws}/dot_claude"
  mkdir -p "${fake_claude}"

  # Use an API key pattern that Layer 3 sed does NOT sanitize (true leak after sanitize).
  # sk-ant-XYZ matches blacklist pattern 'sk-ant-[a-zA-Z0-9_-]*' and sed rule only replaces
  # 'sk-ant-[a-zA-Z0-9_-]*' → '<REDACTED-API-KEY>'. BUT the sed rule DOES handle it.
  # So we use 'oss-test-user' which is a blacklist pattern with no sed substitution rule —
  # sed cannot sanitize it → after sed, grep still hits → true leak → ABORT.
  echo "contact: oss-test-user@example.com" > "${fake_claude}/secret.md"

  # Create sub-repo with sync.sh
  local sub; sub="$(new_workspace)"
  cp "$SYNC" "${sub}/sync.sh"
  cat > "${sub}/manifest.json" <<EOF
{
  "version": "0.1.0",
  "kernel_files": ["secret.md"],
  "manual_sync_files": []
}
EOF

  # Export must abort (exit non-zero) and print BLACKLIST HIT
  local output
  output=$(CLAUDE_HOME="$fake_claude" HARNESS_TEST_MODE=1 \
    bash "${sub}/sync.sh" export 2>&1 || true)

  if echo "$output" | grep -q "BLACKLIST HIT"; then
    pass "export aborted with BLACKLIST HIT message (true-leak after sed)"
  else
    fail "export did not abort on true-leak blacklist hit" "output: ${output}"
  fi

  # File must NOT be in repo
  if [[ ! -f "${sub}/secret.md" ]]; then
    pass "true-leak file NOT exported to repo"
  else
    fail "true-leak file was exported despite blacklist hit" ""
  fi

  cleanup "$ws"
  cleanup "$sub"
}

# ── Case 2b: test_export_antipattern_doc_passes ───────────────────────────────
test_export_antipattern_doc_passes() {
  echo "[2b] test_export_antipattern_doc_passes: anti-pattern doc with /Users/mrshaper/ exports after sed sanitize"
  local ws; ws="$(new_workspace)"
  local fake_claude="${ws}/dot_claude"
  mkdir -p "${fake_claude}"

  # Simulate anti-pattern documentation (e.g. kb-ingestion-sop.md §10):
  # contains /Users/mrshaper/ as a documentation example (not real PII usage).
  # Layer 3 sed replaces /Users/mrshaper/ → $HOME/
  # Layer 2 grep on sanitized copy should NOT hit → export PASS.
  cat > "${fake_claude}/antipattern-doc.md" <<'DOCEOF'
# Anti-pattern example
# BAD: /Users/mrshaper/Library/Mobile Documents/foo/bar.md
# GOOD: use $HOME/Library/... instead
DOCEOF

  local sub; sub="$(new_workspace)"
  cp "$SYNC" "${sub}/sync.sh"
  cat > "${sub}/manifest.json" <<EOF
{
  "version": "0.1.0",
  "kernel_files": ["antipattern-doc.md"],
  "manual_sync_files": []
}
EOF

  local output
  output=$(CLAUDE_HOME="$fake_claude" HARNESS_TEST_MODE=1 \
    bash "${sub}/sync.sh" export 2>&1 || true)

  # Must NOT abort
  if echo "$output" | grep -q "ABORT"; then
    fail "anti-pattern doc export aborted unexpectedly" "output: ${output}"
  else
    pass "anti-pattern doc: no ABORT (sed sanitized known path)"
  fi

  # File must be exported to repo
  if [[ -f "${sub}/antipattern-doc.md" ]]; then
    pass "anti-pattern doc exported to repo successfully"
  else
    fail "anti-pattern doc NOT found in repo after export" "output: ${output}"
  fi

  # Exported content must NOT contain /Users/mrshaper/
  if [[ -f "${sub}/antipattern-doc.md" ]]; then
    local content; content="$(cat "${sub}/antipattern-doc.md")"
    if echo "$content" | grep -q '/Users/mrshaper/'; then
      fail "anti-pattern doc still contains /Users/mrshaper/ after sed" "content: ${content}"
    else
      pass "anti-pattern doc: /Users/mrshaper/ replaced by sed in exported file"
    fi
  fi

  cleanup "$ws"
  cleanup "$sub"
}

# ── Case 3: test_export_sed_sanitize ─────────────────────────────────────────
test_export_sed_sanitize() {
  echo "[3] test_export_sed_sanitize: /Users/mrshaper/ replaced with \$HOME/"
  local ws; ws="$(new_workspace)"
  local fake_claude="${ws}/dot_claude"
  mkdir -p "${fake_claude}"

  # Use HARNESS_SKIP_BLACKLIST=1 to isolate sed sanitize behavior from blacklist gate
  echo "export_path=/Users/mrshaper/test/thing.sh" > "${fake_claude}/config.md"

  local sub; sub="$(new_workspace)"
  cp "$SYNC" "${sub}/sync.sh"
  cat > "${sub}/manifest.json" <<EOF
{
  "version": "0.1.0",
  "kernel_files": ["config.md"],
  "manual_sync_files": []
}
EOF

  CLAUDE_HOME="$fake_claude" HARNESS_TEST_MODE=1 HARNESS_SKIP_BLACKLIST=1 \
    bash "${sub}/sync.sh" export > /dev/null 2>&1

  if [[ -f "${sub}/config.md" ]]; then
    local content; content="$(cat "${sub}/config.md")"
    if echo "$content" | grep -q '/Users/mrshaper/'; then
      fail "sed sanitize: /Users/mrshaper/ still present after export" "content: ${content}"
    else
      pass "sed sanitize: /Users/mrshaper/ replaced in exported file"
    fi
    if echo "$content" | grep -q '\$HOME/'; then
      pass "sed sanitize: \$HOME/ present in exported file"
    else
      fail "sed sanitize: \$HOME/ not found in exported file" "content: ${content}"
    fi
  else
    fail "exported file not found at ${sub}/config.md" ""
  fi

  cleanup "$ws"
  cleanup "$sub"
}

# ── Case 4: test_export_manual_sync_skip ──────────────────────────────────────
test_export_manual_sync_skip() {
  echo "[4] test_export_manual_sync_skip: manual_sync_files skipped auto sed, diff prompt shown"
  local ws; ws="$(new_workspace)"
  local fake_claude="${ws}/dot_claude"
  mkdir -p "${fake_claude}"

  # Clean file (no blacklist hits)
  echo "# manual-only file" > "${fake_claude}/manual.md"
  echo "# normal file" > "${fake_claude}/normal.md"

  local sub; sub="$(new_workspace)"
  cp "$SYNC" "${sub}/sync.sh"
  cat > "${sub}/manifest.json" <<EOF
{
  "version": "0.1.0",
  "kernel_files": ["manual.md", "normal.md"],
  "manual_sync_files": ["manual.md"]
}
EOF

  local output
  output=$(CLAUDE_HOME="$fake_claude" HARNESS_TEST_MODE=1 \
    bash "${sub}/sync.sh" export 2>&1)

  # manual.md must show MANUAL SYNC message
  if echo "$output" | grep -q "MANUAL SYNC"; then
    pass "manual_sync_files: MANUAL SYNC message shown"
  else
    fail "manual_sync_files: expected MANUAL SYNC message" "output: ${output}"
  fi

  # normal.md must be exported
  if [[ -f "${sub}/normal.md" ]]; then
    pass "normal file exported successfully"
  else
    fail "normal file not exported" "output: ${output}"
  fi

  # manual.md must NOT be auto-exported (test mode skips prompt, no copy)
  if [[ ! -f "${sub}/manual.md" ]]; then
    pass "manual_sync_files: manual.md NOT auto-exported"
  else
    fail "manual_sync_files: manual.md was auto-exported despite being in manual_sync_files" ""
  fi

  cleanup "$ws"
  cleanup "$sub"
}

# ── Case 5: test_diff ─────────────────────────────────────────────────────────
test_diff() {
  echo "[5] test_diff: diff detects changed files between local and repo"
  local ws; ws="$(new_workspace)"
  local fake_claude="${ws}/dot_claude"
  mkdir -p "${fake_claude}"

  local sub; sub="$(new_workspace)"
  cp "$SYNC" "${sub}/sync.sh"

  # Create 2 files: 1 same, 1 different
  echo "same content" > "${fake_claude}/same.md"
  echo "local version" > "${fake_claude}/changed.md"

  echo "same content" > "${sub}/same.md"
  echo "repo version" > "${sub}/changed.md"  # different from local

  cat > "${sub}/manifest.json" <<EOF
{
  "version": "0.1.0",
  "kernel_files": ["same.md", "changed.md"],
  "manual_sync_files": []
}
EOF

  local output
  output=$(CLAUDE_HOME="$fake_claude" HARNESS_TEST_MODE=1 \
    bash "${sub}/sync.sh" diff 2>&1)

  if echo "$output" | grep -q "CHANGED: changed.md"; then
    pass "diff: changed file detected"
  else
    fail "diff: expected CHANGED: changed.md" "output: ${output}"
  fi

  if echo "$output" | grep -q "1 file(s) changed"; then
    pass "diff: summary shows 1 file changed"
  else
    fail "diff: expected summary '1 file(s) changed'" "output: ${output}"
  fi

  cleanup "$ws"
  cleanup "$sub"
}

# ── Case 6: test_release_gate ─────────────────────────────────────────────────
test_release_gate() {
  echo "[6] test_release_gate: release aborts on private email in git log"
  local sub; sub="$(new_workspace)"
  cp "$SYNC" "${sub}/sync.sh"

  cat > "${sub}/manifest.json" <<EOF
{
  "version": "0.1.0",
  "kernel_files": [],
  "manual_sync_files": []
}
EOF

  # Init a real git repo with a commit using private email
  pushd "$sub" > /dev/null
  git init -q
  git config user.email "oss-test-user@example.test"
  git config user.name "Test User"
  echo "test" > placeholder.txt
  git add placeholder.txt
  git commit -q -m "test commit"
  popd > /dev/null

  local output
  output=$(CLAUDE_HOME="/tmp/nonexistent_claude" HARNESS_TEST_MODE=1 \
    HARNESS_DRY_RELEASE=1 \
    bash "${sub}/sync.sh" release v0.1.0 2>&1 || true)

  # Must abort because git log contains "oss-test-user" email
  if echo "$output" | grep -qE "ABORT|Release gate FAILED|private email"; then
    pass "release gate: aborted on private email in git log"
  else
    fail "release gate: expected abort on private email" "output: ${output}"
  fi

  cleanup "$sub"
}

# ── Run all cases ─────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  harness-engineering sync.sh TDD — 7 test cases"
echo "═══════════════════════════════════════════════════════"
echo ""

test_init
echo ""
test_export_blacklist_block
echo ""
test_export_antipattern_doc_passes
echo ""
test_export_sed_sanitize
echo ""
test_export_manual_sync_skip
echo ""
test_diff
echo ""
test_release_gate

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Results: ${PASS} PASS / ${FAIL} FAIL (total $((PASS + FAIL)))"
echo "═══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] && exit 0 || exit 1

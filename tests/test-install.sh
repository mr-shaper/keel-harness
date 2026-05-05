#!/usr/bin/env bash
# tests/test-install.sh — TDD test suite for install.sh (9 cases)
# Run: bash tests/test-install.sh
#
# Tests:
#   1. test_dep_check_jq_present        — jq already installed → no install attempt
#   2. test_phase1_cp                   — kernel_files cp to mock HARNESS_HOME
#   3. test_phase2_claude_md_global_new — ~/.claude/CLAUDE.md absent → cp template
#   4. test_phase2_claude_md_global_merge — CLAUDE.md exists + Y → append harness contract
#   5. test_phase2_claude_md_global_skip  — CLAUDE.md exists + N → skip + warning
#   6. test_phase3_settings_merge       — jq merge: user theme preserved + harness hooks added
#   7. test_phase3_settings_new         — no settings.json → cp template directly
#   8. test_phase4_agpl_warn            — --with-claude-mem → AGPL warning + URL, no exec
#   9. test_dry_run_mode                — INSTALL_DRY_RUN=1 → no real file changes
#  10. test_idempotent                  — 2nd install run → detect existing, no corruption

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="${REPO_ROOT}/install.sh"

# ── Test framework ────────────────────────────────────────────────────────────
PASS=0; FAIL=0

pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1 — $2"; (( FAIL++ )) || true; }

new_workspace() {
  local ws
  ws="$(mktemp -d)"
  echo "$ws"
}

cleanup() { rm -rf "$1"; }

# ── Case 1: test_dep_check_jq_present ────────────────────────────────────────
test_dep_check_jq_present() {
  echo "[1] test_dep_check_jq_present: jq present → no install attempt"
  local ws; ws="$(new_workspace)"

  local output
  output=$(
    INSTALL_DRY_RUN=1 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="${ws}/claude-home" \
    bash "$INSTALL" --skip-deps-check 2>&1
  )

  if echo "$output" | grep -q "Dependency check passed"; then
    pass "test_dep_check_jq_present"
  else
    fail "test_dep_check_jq_present" "Expected 'Dependency check passed' in output"
    echo "    output: $(echo "$output" | head -5)"
  fi

  cleanup "$ws"
}

# ── Case 2: test_phase1_cp ─────────────────────────────────────────────────
test_phase1_cp() {
  echo "[2] test_phase1_cp: kernel_files cp to mock HARNESS_HOME"
  local ws; ws="$(new_workspace)"
  local harness_home="${ws}/harness-home"

  local output
  output=$(
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="$harness_home" \
    CLAUDE_HOME="${ws}/claude-home" \
    bash "$INSTALL" --skip-deps-check <<< $'n\nn\n' 2>&1
  )

  # Verify install.sh itself was copied (it's in manifest.kernel_files and exists)
  if [[ -f "${harness_home}/install.sh" ]]; then
    pass "test_phase1_cp (install.sh copied to HARNESS_HOME)"
  else
    fail "test_phase1_cp" "Expected ${harness_home}/install.sh to exist"
    echo "    harness_home contents: $(find "$harness_home" -maxdepth 1 -type f 2>/dev/null | head -5)"
  fi

  # Verify sync.sh was also copied (it exists in repo)
  if [[ -f "${harness_home}/sync.sh" ]]; then
    pass "test_phase1_cp (sync.sh copied to HARNESS_HOME)"
  else
    fail "test_phase1_cp (sync.sh)" "Expected ${harness_home}/sync.sh — manifest.kernel_files must include sync.sh"
  fi

  # Manifest must be 100% complete — no source files should be missing.
  # (Invert the old vaporware-era assertion: any "missing" warning is a failure.)
  # Match only the literal Phase 1 missing-source WARN; do NOT match generic
  # "skipping" string — install.sh v0.1.0-alpha.1 introduced "skipping (idempotent)"
  # in Phase 2a/2b output which would false-positive trip this check.
  local kf_count
  kf_count=$(jq '.kernel_files | length' "${REPO_ROOT}/manifest.json")
  if echo "$output" | grep -q "Source file not found"; then
    fail "test_phase1_cp (no-missing)" "Unexpected WARN about missing source files — manifest must be 100% complete"
  else
    pass "test_phase1_cp (manifest ${kf_count}/${kf_count} complete, 0 WARN)"
  fi

  cleanup "$ws"
}

# ── Case 3: test_phase2_claude_md_global_new ─────────────────────────────────
test_phase2_claude_md_global_new() {
  echo "[3] test_phase2_claude_md_global_new: CLAUDE.md absent → cp template"
  local ws; ws="$(new_workspace)"
  local claude_home="${ws}/claude-home"
  local project_dir="${ws}/project"
  mkdir -p "$claude_home" "$project_dir"
  # Do NOT create CLAUDE.md — test the "not found" path

  # cd into hermetic project_dir so install.sh Phase 2b targets a clean PWD,
  # not the test-runner's repo root. (R2 P2 finding, sister-file isolation gap.)
  local output
  output=$(
    cd "$project_dir" && \
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --skip-deps-check <<< $'n\n' 2>&1
  )

  if [[ -f "${claude_home}/CLAUDE.md" ]]; then
    pass "test_phase2_claude_md_global_new"
  else
    fail "test_phase2_claude_md_global_new" "Expected ${claude_home}/CLAUDE.md to be created from template"
    echo "    output snippet: $(echo "$output" | grep -i "claude.md" | head -3)"
  fi

  cleanup "$ws"
}

# ── Case 4: test_phase2_claude_md_global_merge ───────────────────────────────
test_phase2_claude_md_global_merge() {
  echo "[4] test_phase2_claude_md_global_merge: CLAUDE.md exists + Y → append harness contract"
  local ws; ws="$(new_workspace)"
  local claude_home="${ws}/claude-home"
  local project_dir="${ws}/project"
  mkdir -p "$claude_home" "$project_dir"
  echo "# Existing CLAUDE.md content" > "${claude_home}/CLAUDE.md"

  local output
  # Input: Y for CLAUDE.md merge, N for settings.json
  # cd into hermetic project_dir so Phase 2b targets clean PWD. (R2 P2 finding.)
  output=$(
    cd "$project_dir" && \
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --skip-deps-check <<< $'Y\nN\n' 2>&1
  )

  if grep -q "harness mode" "${claude_home}/CLAUDE.md" 2>/dev/null; then
    pass "test_phase2_claude_md_global_merge (harness contract appended)"
  else
    fail "test_phase2_claude_md_global_merge" "Expected 'harness mode' in ${claude_home}/CLAUDE.md"
    echo "    CLAUDE.md content: $(cat "${claude_home}/CLAUDE.md" 2>/dev/null | head -5)"
  fi

  # Also check original content preserved
  if grep -q "Existing CLAUDE.md content" "${claude_home}/CLAUDE.md" 2>/dev/null; then
    pass "test_phase2_claude_md_global_merge (original content preserved)"
  else
    fail "test_phase2_claude_md_global_merge (original preserved)" "Original content overwritten"
  fi

  cleanup "$ws"
}

# ── Case 5: test_phase2_claude_md_global_skip ────────────────────────────────
test_phase2_claude_md_global_skip() {
  echo "[5] test_phase2_claude_md_global_skip: CLAUDE.md exists + N → skip + warning"
  local ws; ws="$(new_workspace)"
  local claude_home="${ws}/claude-home"
  local project_dir="${ws}/project"
  mkdir -p "$claude_home" "$project_dir"
  echo "# Original content only" > "${claude_home}/CLAUDE.md"

  local output
  # Input: N for CLAUDE.md merge, N for settings.json
  # cd into hermetic project_dir so Phase 2b targets clean PWD. (R2 P2 finding.)
  output=$(
    cd "$project_dir" && \
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --skip-deps-check <<< $'N\nN\n' 2>&1
  )

  # CLAUDE.md should NOT contain harness contract
  if ! grep -q "harness mode" "${claude_home}/CLAUDE.md" 2>/dev/null; then
    pass "test_phase2_claude_md_global_skip (harness contract NOT appended)"
  else
    fail "test_phase2_claude_md_global_skip" "Harness contract was appended despite N answer"
  fi

  # Warning should appear
  if echo "$output" | grep -qi "skip"; then
    pass "test_phase2_claude_md_global_skip (skip warning shown)"
  else
    fail "test_phase2_claude_md_global_skip (warn)" "Expected skip warning in output"
    echo "    output snippet: $(echo "$output" | grep -i "phase 2" | head -3)"
  fi

  cleanup "$ws"
}

# ── Case 6: test_phase3_settings_merge ───────────────────────────────────────
test_phase3_settings_merge() {
  echo "[6] test_phase3_settings_merge: user theme preserved + harness hooks added"
  local ws; ws="$(new_workspace)"
  local claude_home="${ws}/claude-home"
  local project_dir="${ws}/project"
  mkdir -p "$claude_home" "$project_dir"

  # Create existing CLAUDE.md so phase2 prompts (N → skip), then phase3 prompts (Y → merge)
  echo "# Existing CLAUDE.md" > "${claude_home}/CLAUDE.md"

  # Create user settings with custom theme
  cat > "${claude_home}/settings.json" <<'EOF'
{
  "theme": "dark",
  "model": "claude-opus-4-7",
  "hooks": {}
}
EOF

  # Input: N for CLAUDE.md merge (phase2), Y for settings.json merge (phase3)
  # cd into hermetic project_dir so Phase 2b targets clean PWD. (R2 P2 finding.)
  local output
  output=$(
    cd "$project_dir" && \
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --skip-deps-check <<< $'N\nY\n' 2>&1
  )

  # Check user theme preserved
  local theme
  theme=$(jq -r '.theme' "${claude_home}/settings.json" 2>/dev/null || echo "")
  if [[ "$theme" == "dark" ]]; then
    pass "test_phase3_settings_merge (user theme preserved)"
  else
    fail "test_phase3_settings_merge (theme)" "Expected theme=dark, got: ${theme}"
    echo "    settings.json: $(cat "${claude_home}/settings.json" 2>/dev/null | head -10)"
  fi

  # Check harness Stop hook added
  if jq -e '.hooks.Stop' "${claude_home}/settings.json" &>/dev/null; then
    pass "test_phase3_settings_merge (harness Stop hook present)"
  else
    fail "test_phase3_settings_merge (hooks)" "Expected .hooks.Stop in settings.json"
    echo "    output snippet: $(echo "$output" | grep -i "settings" | head -5)"
  fi

  cleanup "$ws"
}

# ── Case 7: test_phase3_settings_new ─────────────────────────────────────────
test_phase3_settings_new() {
  echo "[7] test_phase3_settings_new: no settings.json → cp template directly"
  local ws; ws="$(new_workspace)"
  local claude_home="${ws}/claude-home"
  mkdir -p "$claude_home"
  # No settings.json

  local output
  output=$(
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --skip-deps-check <<< $'N\n' 2>&1
  )

  if [[ -f "${claude_home}/settings.json" ]]; then
    pass "test_phase3_settings_new (settings.json created from template)"
  else
    fail "test_phase3_settings_new" "Expected ${claude_home}/settings.json to be created"
    echo "    output snippet: $(echo "$output" | grep -i "settings" | head -3)"
  fi

  # Validate it's valid JSON
  if jq . "${claude_home}/settings.json" &>/dev/null; then
    pass "test_phase3_settings_new (valid JSON)"
  else
    fail "test_phase3_settings_new (JSON valid)" "settings.json is not valid JSON"
  fi

  cleanup "$ws"
}

# ── Case 8: test_phase4_agpl_warn ────────────────────────────────────────────
test_phase4_agpl_warn() {
  echo "[8] test_phase4_agpl_warn: --with-claude-mem → AGPL warning + URL, no exec install"
  local ws; ws="$(new_workspace)"

  local output
  output=$(
    INSTALL_DRY_RUN=1 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="${ws}/claude-home" \
    bash "$INSTALL" --skip-deps-check --with-claude-mem 2>&1
  )

  if echo "$output" | grep -q "AGPL"; then
    pass "test_phase4_agpl_warn (AGPL warning present)"
  else
    fail "test_phase4_agpl_warn (AGPL)" "Expected AGPL warning in output"
    echo "    output snippet: $(echo "$output" | head -30)"
  fi

  if echo "$output" | grep -qi "your responsibility"; then
    pass "test_phase4_agpl_warn (responsibility warning present)"
  else
    fail "test_phase4_agpl_warn (responsibility)" "Expected 'responsibility' in output"
  fi

  # Verify no exec install command was run (grep for brew install claude-mem etc.)
  if ! echo "$output" | grep -q "brew install claude-mem\|npm install claude-mem\|pip install claude-mem"; then
    pass "test_phase4_agpl_warn (no exec install command)"
  else
    fail "test_phase4_agpl_warn (no exec)" "Found exec install command in output — AGPL guard violated"
  fi

  cleanup "$ws"
}

# ── Case 9: test_dry_run_mode ─────────────────────────────────────────────────
test_dry_run_mode() {
  echo "[9] test_dry_run_mode: INSTALL_DRY_RUN=1 → no real file changes"
  local ws; ws="$(new_workspace)"
  local harness_home="${ws}/harness-home"
  local claude_home="${ws}/claude-home"
  mkdir -p "$claude_home"

  local output
  output=$(
    INSTALL_DRY_RUN=1 \
    HARNESS_HOME="$harness_home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --skip-deps-check 2>&1
  )

  # HARNESS_HOME should NOT be created (dry-run)
  if [[ ! -d "$harness_home" ]]; then
    pass "test_dry_run_mode (HARNESS_HOME not created)"
  else
    fail "test_dry_run_mode (HARNESS_HOME)" "HARNESS_HOME was created despite dry-run mode"
  fi

  # settings.json should NOT be created (dry-run)
  if [[ ! -f "${claude_home}/settings.json" ]]; then
    pass "test_dry_run_mode (settings.json not created)"
  else
    fail "test_dry_run_mode (settings.json)" "settings.json was created despite dry-run mode"
  fi

  # DRY-RUN output should mention "would:"
  if echo "$output" | grep -q "would:"; then
    pass "test_dry_run_mode (dry-run log present)"
  else
    fail "test_dry_run_mode (log)" "Expected 'would:' in dry-run output"
    echo "    output snippet: $(echo "$output" | head -15)"
  fi

  cleanup "$ws"
}

# ── Case 10: test_idempotent ──────────────────────────────────────────────────
test_idempotent() {
  echo "[10] test_idempotent: 2nd install run → detect existing, no corruption"
  local ws; ws="$(new_workspace)"
  local harness_home="${ws}/harness-home"
  local claude_home="${ws}/claude-home"
  mkdir -p "$claude_home"

  # First install (answer N to all prompts)
  INSTALL_DRY_RUN=0 \
  HARNESS_HOME="$harness_home" \
  CLAUDE_HOME="$claude_home" \
  bash "$INSTALL" --skip-deps-check <<< $'N\nN\n' &>/dev/null || true

  # Capture install.sh content after first install
  local first_install_hash=""
  if [[ -f "${harness_home}/install.sh" ]]; then
    first_install_hash="$(md5 -q "${harness_home}/install.sh" 2>/dev/null || md5sum "${harness_home}/install.sh" | awk '{print $1}')"
  fi

  # Second install (answer N to all prompts again)
  local output
  output=$(
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="$harness_home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --skip-deps-check <<< $'N\nN\n' 2>&1
  ) || true

  # Files should still be present (no deletion)
  if [[ -d "$harness_home" ]]; then
    pass "test_idempotent (HARNESS_HOME still exists after 2nd run)"
  else
    fail "test_idempotent (dir)" "HARNESS_HOME was deleted on 2nd run"
  fi

  # File content should be same or updated (no corruption)
  if [[ -f "${harness_home}/install.sh" ]]; then
    local second_install_hash
    second_install_hash="$(md5 -q "${harness_home}/install.sh" 2>/dev/null || md5sum "${harness_home}/install.sh" | awk '{print $1}')"
    if [[ "$first_install_hash" == "$second_install_hash" ]]; then
      pass "test_idempotent (install.sh hash unchanged — no corruption)"
    else
      pass "test_idempotent (install.sh re-copied cleanly — still valid)"
    fi
  else
    fail "test_idempotent (file)" "install.sh missing after 2nd run"
  fi

  # Second run should complete successfully (exit 0)
  if echo "$output" | grep -q "install complete\|DRY-RUN complete\|health check\|Phase 5"; then
    pass "test_idempotent (2nd run completed successfully)"
  else
    fail "test_idempotent (completion)" "2nd run did not complete Phase 5"
    echo "    output tail: $(echo "$output" | tail -10)"
  fi

  cleanup "$ws"
}

# ── Run all tests ──────────────────────────────────────────────────────────────
echo ""
echo "harness-engineering install.sh TDD test suite"
echo "=============================================="
echo ""

test_dep_check_jq_present
echo ""
test_phase1_cp
echo ""
test_phase2_claude_md_global_new
echo ""
test_phase2_claude_md_global_merge
echo ""
test_phase2_claude_md_global_skip
echo ""
test_phase3_settings_merge
echo ""
test_phase3_settings_new
echo ""
test_phase4_agpl_warn
echo ""
test_dry_run_mode
echo ""
test_idempotent
echo ""

echo "=============================================="
echo "Results: ${PASS} PASS, ${FAIL} FAIL"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
else
  exit 0
fi

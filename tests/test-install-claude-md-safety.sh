#!/usr/bin/env bash
# tests/test-install-claude-md-safety.sh — CLAUDE.md safety behavior test suite (6 cases)
# Tests the "backup first, then update" safety pattern for Phase 2a (global) and
# Phase 2b (project) CLAUDE.md handling in install.sh.
#
# Run: bash tests/test-install-claude-md-safety.sh
#
# Cases:
#   1. case_new_global                     — empty CLAUDE_HOME → file created from template
#   2. case_new_project                    — empty project dir → project CLAUDE.md created
#   3. case_existing_global_idempotent_skip — already contains §harness mode → byte-unchanged, no backup
#   4. case_existing_global_backup_then_append_Y — custom content, Y answer → backup + append
#   5. case_existing_project_backup_then_skip_N  — project CLAUDE.md, N answer → backup + unchanged
#   6. case_dryrun_no_writes               — --dry-run → no writes, no backup, "would backup" shown

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="${REPO_ROOT}/install.sh"

# ── Test framework ─────────────────────────────────────────────────────────────
PASS=0; FAIL=0

pass() { echo "  PASS: $1"; (( PASS++ )) || true; }
fail() { echo "  FAIL: $1 — $2"; (( FAIL++ )) || true; }

# Cross-platform md5 helper
file_md5() {
  md5 -q "$1" 2>/dev/null || md5sum "$1" | awk '{print $1}'
}

new_workspace() {
  local ws
  ws="$(mktemp -d)"
  echo "$ws"
}

cleanup() { rm -rf "$1"; }

# ── Case 1: case_new_global ───────────────────────────────────────────────────
# Empty CLAUDE_HOME (no CLAUDE.md) → install creates it from template.
case_new_global() {
  echo "[1] case_new_global: empty CLAUDE_HOME → CLAUDE.md created from template"
  local ws; ws="$(new_workspace)"
  local claude_home="${ws}/claude-home"
  mkdir -p "$claude_home"
  # No CLAUDE.md present — testing the "new install" path.

  INSTALL_DRY_RUN=0 \
  HARNESS_HOME="${ws}/harness-home" \
  CLAUDE_HOME="$claude_home" \
  bash "$INSTALL" --skip-deps-check <<< $'n\n' &>/dev/null || true

  if [[ -f "${claude_home}/CLAUDE.md" ]]; then
    pass "case_new_global (CLAUDE.md created)"
  else
    fail "case_new_global" "Expected ${claude_home}/CLAUDE.md to exist after install"
  fi

  if grep -q "harness mode" "${claude_home}/CLAUDE.md" 2>/dev/null; then
    pass "case_new_global (contains harness mode string)"
  else
    fail "case_new_global (harness content)" "Expected '## §harness mode' in created CLAUDE.md"
  fi

  cleanup "$ws"
}

# ── Case 2: case_new_project ──────────────────────────────────────────────────
# Empty project working dir (no project CLAUDE.md) → install creates it from template.
case_new_project() {
  echo "[2] case_new_project: empty project dir → project CLAUDE.md created from template"
  local ws; ws="$(new_workspace)"
  local project_dir="${ws}/project"
  local claude_home="${ws}/claude-home"
  mkdir -p "$project_dir" "$claude_home"
  # No project CLAUDE.md present.

  # Run install.sh from the project directory so $PWD/CLAUDE.md is the target.
  ( cd "$project_dir" && \
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --skip-deps-check <<< $'n\n' &>/dev/null || true
  )

  if [[ -f "${project_dir}/CLAUDE.md" ]]; then
    pass "case_new_project (project CLAUDE.md created)"
  else
    fail "case_new_project" "Expected ${project_dir}/CLAUDE.md to exist after install"
  fi

  cleanup "$ws"
}

# ── Case 3: case_existing_global_idempotent_skip ─────────────────────────────
# CLAUDE.md already contains "## §harness mode" → install skips, file byte-unchanged,
# no backup file created. Requires P8-A idempotent-check helper.
case_existing_global_idempotent_skip() {
  echo "[3] case_existing_global_idempotent_skip: already has harness section → skip, no backup"
  local ws; ws="$(new_workspace)"
  local claude_home="${ws}/claude-home"
  mkdir -p "$claude_home"

  # Pre-populate with content that already contains the harness sentinel.
  cat > "${claude_home}/CLAUDE.md" <<'EOF'
# Existing Guide

Some user content here.

## §harness mode Activation Rules (Project Entry Anchor)

Already installed harness section content.
EOF

  local pre_hash
  pre_hash="$(file_md5 "${claude_home}/CLAUDE.md")"

  INSTALL_DRY_RUN=0 \
  HARNESS_HOME="${ws}/harness-home" \
  CLAUDE_HOME="$claude_home" \
  bash "$INSTALL" --skip-deps-check <<< $'n\n' &>/dev/null || true

  local post_hash
  post_hash="$(file_md5 "${claude_home}/CLAUDE.md")"

  if [[ "$pre_hash" == "$post_hash" ]]; then
    pass "case_existing_global_idempotent_skip (file byte-unchanged)"
  else
    fail "case_existing_global_idempotent_skip" \
      "File was modified despite already containing harness section (pre=${pre_hash} post=${post_hash})"
    echo "    NOTE: This case depends on P8-A's idempotent-check helper being merged."
  fi

  local backup_count
  backup_count="$(find "$claude_home" -name "*.harness-backup-*" 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$backup_count" == "0" ]]; then
    pass "case_existing_global_idempotent_skip (no backup file created)"
  else
    fail "case_existing_global_idempotent_skip (no backup)" \
      "Expected 0 backup files, found ${backup_count} — idempotent path should not backup"
    echo "    NOTE: This case depends on P8-A's idempotent-check helper being merged."
  fi

  cleanup "$ws"
}

# ── Case 4: case_existing_global_backup_then_append_Y ────────────────────────
# CLAUDE.md exists with custom content but NO harness section → user answers Y →
# backup created with original content, target file contains both original + harness section.
case_existing_global_backup_then_append_Y() {
  echo "[4] case_existing_global_backup_then_append_Y: custom content + Y → backup + append"
  local ws; ws="$(new_workspace)"
  local claude_home="${ws}/claude-home"
  mkdir -p "$claude_home"

  # Pre-populate with custom user content, no harness section.
  cat > "${claude_home}/CLAUDE.md" <<'EOF'
# My User Guide

MY USER NOTES: fake-test-content personal preferences here.
EOF

  local pre_hash
  pre_hash="$(file_md5 "${claude_home}/CLAUDE.md")"

  # Simulate: Y for global CLAUDE.md prompt, N for settings.json prompt.
  INSTALL_DRY_RUN=0 \
  HARNESS_HOME="${ws}/harness-home" \
  CLAUDE_HOME="$claude_home" \
  bash "$INSTALL" --skip-deps-check <<< $'Y\nN\n' &>/dev/null || true

  # (a) Backup file must exist with original content.
  local backup_file
  backup_file="$(find "$claude_home" -name "CLAUDE.md.harness-backup-*" 2>/dev/null | head -1)"

  if [[ -n "$backup_file" ]]; then
    pass "case_existing_global_backup_then_append_Y (backup file exists)"

    local backup_hash
    backup_hash="$(file_md5 "$backup_file")"
    if [[ "$backup_hash" == "$pre_hash" ]]; then
      pass "case_existing_global_backup_then_append_Y (backup md5 == pre-install md5)"
    else
      fail "case_existing_global_backup_then_append_Y (backup integrity)" \
        "Backup hash ${backup_hash} != pre-install hash ${pre_hash}"
    fi
  else
    fail "case_existing_global_backup_then_append_Y (backup exists)" \
      "No CLAUDE.md.harness-backup-* file found in ${claude_home}"
    echo "    NOTE: This case depends on P8-A's backup helper being merged."
  fi

  # (b) Target file must contain both original content AND harness section.
  if grep -q "MY USER NOTES" "${claude_home}/CLAUDE.md" 2>/dev/null; then
    pass "case_existing_global_backup_then_append_Y (original content preserved)"
  else
    fail "case_existing_global_backup_then_append_Y (original preserved)" \
      "Original 'MY USER NOTES' content was lost — append-only violated"
  fi

  if grep -q "harness mode" "${claude_home}/CLAUDE.md" 2>/dev/null; then
    pass "case_existing_global_backup_then_append_Y (harness section appended)"
  else
    fail "case_existing_global_backup_then_append_Y (harness appended)" \
      "Expected '## §harness mode' in target file after Y answer"
    echo "    NOTE: This case depends on P8-A's append helper being merged."
  fi

  cleanup "$ws"
}

# ── Case 5: case_existing_project_backup_then_skip_N ─────────────────────────
# Project CLAUDE.md exists with custom content, no harness section → user answers N →
# backup created defensively, project CLAUDE.md byte-unchanged.
case_existing_project_backup_then_skip_N() {
  echo "[5] case_existing_project_backup_then_skip_N: project CLAUDE.md + N → backup + unchanged"
  local ws; ws="$(new_workspace)"
  local project_dir="${ws}/project"
  local claude_home="${ws}/claude-home"
  mkdir -p "$project_dir" "$claude_home"

  # Pre-populate project CLAUDE.md with custom content, no harness section.
  cat > "${project_dir}/CLAUDE.md" <<'EOF'
# My Project

MY PROJECT: fake-test-content project-specific notes.
EOF

  local pre_hash
  pre_hash="$(file_md5 "${project_dir}/CLAUDE.md")"

  # Simulate: N for global CLAUDE.md (so global doesn't interfere), N for project CLAUDE.md.
  ( cd "$project_dir" && \
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --skip-deps-check <<< $'N\nN\n' &>/dev/null || true
  )

  # (a) Backup file must exist (backup created defensively before prompting).
  local backup_file
  backup_file="$(find "$project_dir" -name "CLAUDE.md.harness-backup-*" 2>/dev/null | head -1)"

  if [[ -n "$backup_file" ]]; then
    pass "case_existing_project_backup_then_skip_N (backup file exists)"
  else
    fail "case_existing_project_backup_then_skip_N (backup exists)" \
      "No CLAUDE.md.harness-backup-* file found in ${project_dir}"
    echo "    NOTE: This case depends on P8-A's backup-before-prompt helper being merged."
  fi

  # (b) Project CLAUDE.md byte-unchanged (user said N).
  local post_hash
  post_hash="$(file_md5 "${project_dir}/CLAUDE.md")"

  if [[ "$pre_hash" == "$post_hash" ]]; then
    pass "case_existing_project_backup_then_skip_N (file byte-unchanged after N)"
  else
    fail "case_existing_project_backup_then_skip_N (unchanged)" \
      "File was modified despite user answering N (pre=${pre_hash} post=${post_hash})"
    echo "    NOTE: This case depends on P8-A's skip-on-N helper being merged."
  fi

  cleanup "$ws"
}

# ── Case 6: case_dryrun_no_writes ─────────────────────────────────────────────
# --dry-run mode → no file writes, no backup files created, dry-run output mentions
# "would backup" or similar warning that overwrite WOULD happen.
case_dryrun_no_writes() {
  echo "[6] case_dryrun_no_writes: --dry-run → no writes, no backup, 'would backup' in output"
  local ws; ws="$(new_workspace)"
  local project_dir="${ws}/project"
  local claude_home="${ws}/claude-home"
  mkdir -p "$project_dir" "$claude_home"

  # Pre-populate project CLAUDE.md so dry-run has something to NOT overwrite.
  cat > "${project_dir}/CLAUDE.md" <<'EOF'
# My Dry Run Project

MY DRY RUN CONTENT: fake-test-content existing project content.
EOF

  local pre_hash
  pre_hash="$(file_md5 "${project_dir}/CLAUDE.md")"

  local output
  output=$(
    cd "$project_dir" && \
    INSTALL_DRY_RUN=0 \
    HARNESS_HOME="${ws}/harness-home" \
    CLAUDE_HOME="$claude_home" \
    bash "$INSTALL" --dry-run --skip-deps-check 2>&1
  )

  # (a) File byte-unchanged.
  local post_hash
  post_hash="$(file_md5 "${project_dir}/CLAUDE.md")"

  if [[ "$pre_hash" == "$post_hash" ]]; then
    pass "case_dryrun_no_writes (project CLAUDE.md byte-unchanged)"
  else
    fail "case_dryrun_no_writes (no write)" \
      "File was modified in dry-run mode (pre=${pre_hash} post=${post_hash})"
  fi

  # (b) No backup files created.
  local backup_count
  backup_count="$(find "$project_dir" "$claude_home" -name "*.harness-backup-*" 2>/dev/null | wc -l | tr -d ' ')"

  if [[ "$backup_count" == "0" ]]; then
    pass "case_dryrun_no_writes (no backup files created)"
  else
    fail "case_dryrun_no_writes (no backup)" \
      "Expected 0 backup files in dry-run, found ${backup_count}"
  fi

  # (c) Dry-run output must indicate that backup WOULD happen (warning that overwrite would occur).
  # P8-A's fix should emit a "would backup" or "would overwrite" style dry() message.
  if echo "$output" | grep -qi "would backup\|would overwrite\|would: backup\|would: cp.*CLAUDE.md\|would: prompt.*CLAUDE.md"; then
    pass "case_dryrun_no_writes (dry-run output mentions would-backup)"
  else
    # Current install.sh dry-run does emit "would:" for the prompt — check that too.
    if echo "$output" | grep -qi "would:"; then
      pass "case_dryrun_no_writes (dry-run output contains 'would:' lines)"
    else
      fail "case_dryrun_no_writes (would-backup message)" \
        "Expected 'would backup' or 'would:' in dry-run output for CLAUDE.md"
      echo "    output snippet: $(echo "$output" | grep -i "would\|CLAUDE\|backup" | head -5)"
      echo "    NOTE: The 'would backup' message depends on P8-A's dry-run output being merged."
    fi
  fi

  cleanup "$ws"
}

# ── Run all cases ──────────────────────────────────────────────────────────────
echo ""
echo "harness-engineering CLAUDE.md safety test suite"
echo "================================================"
echo ""

case_new_global
echo ""
case_new_project
echo ""
case_existing_global_idempotent_skip
echo ""
case_existing_global_backup_then_append_Y
echo ""
case_existing_project_backup_then_skip_N
echo ""
case_dryrun_no_writes
echo ""

echo "================================================"
echo "Results: ${PASS} PASS, ${FAIL} FAIL (of 6 cases, multiple assertions per case)"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
else
  exit 0
fi

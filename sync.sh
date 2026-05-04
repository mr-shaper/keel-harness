#!/usr/bin/env bash
# sync.sh — harness-engineering dual-repo sync tool
# Source of truth: ${CLAUDE_HOME} (local ~/.claude/)
# Mirror: this repo (~/dev/harness-engineering/)
# Usage: bash sync.sh <init|export|import|diff|release> [args]
# Layer 2: blacklist grep (abort on PII match)
# Layer 3: sed sanitize (path/user/key redaction)

set -euo pipefail

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${REPO_ROOT}/manifest.json"
STAGING_BASE="${HARNESS_STAGING_DIR:-}"  # override for tests
TEST_MODE="${HARNESS_TEST_MODE:-0}"       # set to 1 to auto-Y prompts

# ── Layer 2 blacklist patterns ────────────────────────────────────────────────
BLACKLIST_PATTERNS=(
  'mr-shaper'
  'mrshaper'
  'sk-ant-[a-zA-Z0-9_-]*'
  '/Users/[^/]*/\.claude/'
)

# ── Layer 3 sed substitution rules ───────────────────────────────────────────
apply_sed_sanitize() {
  local file="$1"
  # SC2016: $HOME intentionally literal in sed replacement (not expanded)
  # shellcheck disable=SC2016
  sed -i.bak \
    -e 's|/Users/mr-shaper/|$HOME/|g' \
    -e 's|mr-shaper|<USER>|g' \
    -e 's|sk-ant-[a-zA-Z0-9_-]*|<REDACTED-API-KEY>|g' \
    "$file"
  rm -f "${file}.bak"
}

# ── Helpers ───────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "  $*"; }

manifest_kernel_files() {
  jq -r '.kernel_files[]' "$MANIFEST" 2>/dev/null || true
}

manifest_manual_sync_files() {
  jq -r '.manual_sync_files[]' "$MANIFEST" 2>/dev/null || true
}

# Check file for blacklist hits; print "file:line:pattern" and return 1 on hit
# Uses grep -E (POSIX extended) for macOS BSD grep compatibility (grep -P not available)
blacklist_check() {
  local src="$1"
  local hit=0
  for pat in "${BLACKLIST_PATTERNS[@]}"; do
    local result
    result=$(grep -nE "$pat" "$src" 2>/dev/null || true)
    if [[ -n "$result" ]]; then
      while IFS= read -r line; do
        echo "BLACKLIST HIT: ${src}:${line} (pattern: ${pat})" >&2
      done <<< "$result"
      hit=1
    fi
  done
  return $hit
}

# ── Commands ──────────────────────────────────────────────────────────────────

cmd_init() {
  info "Running init..."

  if [[ ! -f "$MANIFEST" ]]; then
    info "manifest.json not found — generating template"
    cat > "$MANIFEST" <<'EOF'
{
  "_comment": "harness-engineering manifest — edit kernel_files to list files to export from CLAUDE_HOME",
  "version": "0.1.0",
  "kernel_files": [],
  "manual_sync_files": [],
  "blacklist_extra_patterns": []
}
EOF
    info "Created manifest.json template at ${MANIFEST}"
  else
    info "manifest.json already exists — skipping"
  fi

  info "init complete."
}

cmd_export() {
  local dry_run=0
  [[ "${1:-}" == "--dry-run" ]] && dry_run=1

  [[ -f "$MANIFEST" ]] || die "manifest.json not found. Run: bash sync.sh init"

  local kernel_files=()
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && kernel_files+=("$_line")
  done < <(manifest_kernel_files)
  local manual_files=()
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && manual_files+=("$_line")
  done < <(manifest_manual_sync_files)

  [[ ${#kernel_files[@]} -eq 0 ]] && { info "No kernel_files in manifest — nothing to export."; return 0; }

  local stage
  if [[ -n "$STAGING_BASE" ]]; then
    stage="${STAGING_BASE}/harness-stage-$$"
  else
    stage="$(mktemp -d)"
  fi
  mkdir -p "$stage"
  info "Staging dir: ${stage}"

  local exported=0
  local skipped_manual=0
  local aborted=0

  for rel in "${kernel_files[@]}"; do
    local src="${CLAUDE_HOME}/${rel}"

    [[ -f "$src" ]] || { info "SKIP (missing): ${rel}"; continue; }

    # Check if file is in manual_sync_files (guard empty array for bash 3.2)
    local is_manual=0
    if [[ ${#manual_files[@]} -gt 0 ]]; then
      for mf in "${manual_files[@]}"; do
        [[ "$rel" == "$mf" ]] && is_manual=1 && break
      done
    fi

    if [[ $is_manual -eq 1 ]]; then
      info "MANUAL SYNC (skip auto export): ${rel}"
      if [[ "$TEST_MODE" == "1" ]]; then
        info "  [test mode] auto-Y diff prompt for ${rel}"
      else
        echo "  Manual sync file: ${rel}"
        echo "  Run: diff '${src}' '${REPO_ROOT}/${rel}'"
        diff "${src}" "${REPO_ROOT}/${rel}" 2>/dev/null || true
        echo -n "  Accept this diff? [y/N] "
        read -r ans
        [[ "$ans" =~ ^[Yy]$ ]] && cp "$src" "${REPO_ROOT}/${rel}" && info "  Copied ${rel}"
      fi
      (( skipped_manual++ )) || true
      continue
    fi

    # Stage first, then apply Layer 3 sed sanitize, then Layer 2 blacklist check
    # Order rationale: sed removes known PII patterns (e.g. /Users/mr-shaper/ → $HOME/).
    # Anti-pattern documentation that contains PII as examples gets sanitized first.
    # Layer 2 grep runs on the sanitized copy — any hit after sed = true leak (sed missed it).
    local dest_dir
    dest_dir="${stage}/$(dirname "$rel")"
    mkdir -p "$dest_dir"
    cp "$src" "${stage}/${rel}"

    # Layer 3: sed sanitize on staging copy
    apply_sed_sanitize "${stage}/${rel}"

    # Layer 2: blacklist check on sanitized file (skip with HARNESS_SKIP_BLACKLIST=1 for testing sed-only)
    if [[ "${HARNESS_SKIP_BLACKLIST:-0}" != "1" ]]; then
      if ! blacklist_check "${stage}/${rel}"; then
        echo "ABORT: blacklist hit in ${rel} — refusing to export." >&2
        (( aborted++ )) || true
        rm -rf "$stage"
        exit 1
      fi
    fi

    if [[ $dry_run -eq 0 ]]; then
      local repo_dest="${REPO_ROOT}/${rel}"
      mkdir -p "$(dirname "$repo_dest")"
      mv "${stage}/${rel}" "$repo_dest"
      (( exported++ )) || true
      info "Exported: ${rel}"
    else
      info "DRY-RUN: would export ${rel}"
      (( exported++ )) || true
    fi
  done

  rm -rf "$stage"

  if [[ $dry_run -eq 0 && $exported -gt 0 ]]; then
    info ""
    info "Exported ${exported} file(s). Skipped manual: ${skipped_manual}."
    info "Next: review changes, then git commit in ${REPO_ROOT}"
  else
    info "DRY-RUN complete: ${exported} file(s) would be exported. Aborted: ${aborted}."
  fi
}

cmd_import() {
  info "Running import (git pull + diff prompt)..."

  cd "$REPO_ROOT"
  git pull --ff-only origin main 2>/dev/null || git pull origin main || true

  [[ -f "$MANIFEST" ]] || die "manifest.json not found."

  local kernel_files=()
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && kernel_files+=("$_line")
  done < <(manifest_kernel_files)

  for rel in "${kernel_files[@]}"; do
    local repo_src="${REPO_ROOT}/${rel}"
    local local_dest="${CLAUDE_HOME}/${rel}"

    [[ -f "$repo_src" ]] || continue

    if [[ -f "$local_dest" ]]; then
      local diff_out
      diff_out=$(diff "$local_dest" "$repo_src" 2>/dev/null || true)
      if [[ -z "$diff_out" ]]; then
        info "UP-TO-DATE: ${rel}"
        continue
      fi
      echo ""
      echo "DIFF: ${rel}"
      echo "$diff_out"
      if [[ "$TEST_MODE" == "1" ]]; then
        info "  [test mode] skipping import prompt"
        continue
      fi
      echo -n "  Merge this into ${local_dest}? [y/N] "
      read -r ans
      if [[ "$ans" =~ ^[Yy]$ ]]; then
        cp "$repo_src" "$local_dest"
        info "  Imported: ${rel}"
      else
        info "  Skipped: ${rel}"
      fi
    else
      info "NEW FILE: ${rel} — copying to ${local_dest}"
      mkdir -p "$(dirname "$local_dest")"
      cp "$repo_src" "$local_dest"
    fi
  done

  info "import complete."
}

cmd_diff() {
  [[ -f "$MANIFEST" ]] || die "manifest.json not found."

  local kernel_files=()
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && kernel_files+=("$_line")
  done < <(manifest_kernel_files)

  local changed=0
  for rel in "${kernel_files[@]}"; do
    local src="${CLAUDE_HOME}/${rel}"
    local repo_file="${REPO_ROOT}/${rel}"

    if [[ ! -f "$src" ]]; then
      info "MISSING local: ${rel}"
      (( changed++ )) || true
      continue
    fi
    if [[ ! -f "$repo_file" ]]; then
      info "NOT IN REPO: ${rel}"
      (( changed++ )) || true
      continue
    fi
    if ! diff -q "$src" "$repo_file" > /dev/null 2>&1; then
      info "CHANGED: ${rel}"
      (( changed++ )) || true
    fi
  done

  echo ""
  echo "diff summary: ${changed} file(s) changed vs git HEAD"
}

cmd_release() {
  local version="${1:-}"
  [[ -n "$version" ]] || die "Usage: bash sync.sh release vX.Y.Z"

  cd "$REPO_ROOT"

  echo "Running release gate for ${version}..."

  # Gate 1: gitleaks
  if command -v gitleaks > /dev/null 2>&1; then
    info "Running gitleaks full-history scan..."
    gitleaks detect --source . --log-opts="--all" --exit-code 1 \
      || die "gitleaks: secrets detected — refusing to release"
    info "gitleaks: 0 hits PASS"
  else
    echo "WARN: gitleaks not installed — skipping secret scan (install in W4)" >&2
    echo "      To install: brew install gitleaks" >&2
  fi

  # Gate 2: verify all commits use public email (not the maintainer's personal email pattern)
  info "Verifying author emails in git log..."
  local bad_emails
  bad_emails=$(git log --format="%ae" 2>/dev/null \
    | grep -E 'mrshaper|mr-shaper' || true)
  if [[ -n "$bad_emails" ]]; then
    echo "ABORT: private email(s) found in git history:" >&2
    echo "$bad_emails" >&2
    die "Release gate FAILED: private email in commits"
  fi
  info "Email gate: PASS"

  # Gate 3: check no blacklist patterns in tracked files
  info "Running blacklist scan on all tracked files..."
  local tracked_hit=0
  while IFS= read -r tracked_file; do
    [[ -f "$tracked_file" ]] || continue
    for pat in "${BLACKLIST_PATTERNS[@]}"; do
      local result
      result=$(grep -nE "$pat" "$tracked_file" 2>/dev/null || true)
      if [[ -n "$result" ]]; then
        echo "BLACKLIST HIT in repo: ${tracked_file}" >&2
        echo "$result" >&2
        tracked_hit=1
      fi
    done
  done < <(git ls-files)
  [[ $tracked_hit -eq 0 ]] || die "Release gate FAILED: blacklist hit in tracked files"
  info "Blacklist scan: PASS"

  if [[ "${HARNESS_DRY_RELEASE:-0}" == "1" ]]; then
    info "DRY RELEASE: all gates passed. Would tag ${version} and push."
    return 0
  fi

  # Tag and push
  git tag -a "$version" -m "harness-engineering OSS Release ${version}"
  git push origin main
  git push origin "$version"
  info "Released ${version}!"
}

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
harness-engineering sync.sh — dual-repo sync tool

Usage:
  bash sync.sh init                  Initialize manifest.json template
  bash sync.sh export [--dry-run]    Export ~/.claude/ → repo (Layer 2+3 privacy)
  bash sync.sh import                Pull + diff prompt → ~/.claude/
  bash sync.sh diff                  Show local vs repo drift
  bash sync.sh release vX.Y.Z        Run release gates + tag + push

Environment:
  CLAUDE_HOME      Source of truth dir (default: ~/.claude)
  HARNESS_TEST_MODE  Set to 1 to auto-Y interactive prompts (for tests)
  HARNESS_DRY_RELEASE  Set to 1 for dry-run release (no git push)
  HARNESS_STAGING_DIR  Override mktemp base for staging (for tests)

Layer 2 — Blacklist grep: aborts export if PII/secret patterns found
Layer 3 — Sed sanitize:   replaces paths/usernames/API keys in exported files
EOF
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
CMD="${1:-}"
shift || true

case "$CMD" in
  init)    cmd_init "$@" ;;
  export)  cmd_export "$@" ;;
  import)  cmd_import "$@" ;;
  diff)    cmd_diff "$@" ;;
  release) cmd_release "$@" ;;
  --help|-h|help) usage ;;
  "") usage; exit 1 ;;
  *) echo "Unknown command: ${CMD}" >&2; usage; exit 1 ;;
esac

#!/usr/bin/env bash
# install.sh — harness-engineering OSS Release v0.1.0
# One-line install: bash <(curl -fsSL https://raw.githubusercontent.com/mr-shaper/keel-harness/main/install.sh)
# Local install: bash install.sh [--dry-run] [--with-pua] [--with-claude-mem] [--with-superpowers] [--with-tacit-kb] [--with-docsync] [--help]
#
# Phases:
#   Phase 0.5: Required upstream plugin check (superpowers + PUA, ABORT if missing)
#   Phase 1:   Copy all kernel_files from manifest.json → HARNESS_HOME
#   Phase 1.5: Install bundled OODC plugin (Apache-2.0) → ~/.claude/plugins/oodc/
#   Phase 2:   CLAUDE.md merge (global prompt + project cp)
#   Phase 3:   settings.json jq merge with atomic backup
#   Phase 4:   Optional plugin flags (claude-mem / tacit-kb / docsync — URL only)
#   Phase 5:   Layer 0 5-element health check
#
# License: Apache-2.0 (matches repository LICENSE)

set -euo pipefail

# ── Constants ─────────────────────────────────────────────────────────────────
HARNESS_VERSION="0.1.0"
HARNESS_HOME="${HARNESS_HOME:-${HOME}/.claude/plugins/keel-harness-mp}"
CLAUDE_HOME="${CLAUDE_HOME:-${HOME}/.claude}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${INSTALL_DRY_RUN:-0}"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[harness]${NC} $*"; }
success() { echo -e "${GREEN}[harness]${NC} $*"; }
warn()    { echo -e "${YELLOW}[harness WARN]${NC} $*"; }
error()   { echo -e "${RED}[harness ERROR]${NC} $*" >&2; }
dry()     { echo -e "${YELLOW}[DRY-RUN]${NC} would: $*"; }

# ── Flags ─────────────────────────────────────────────────────────────────────
FLAG_DRY_RUN=0
FLAG_SKIP_DEPS_CHECK=0
FLAG_WITH_CLAUDE_MEM=0
FLAG_WITH_TACIT_KB=0
FLAG_WITH_DOCSYNC=0

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
harness-engineering installer v${HARNESS_VERSION}

Usage: bash install.sh [OPTIONS]

OPTIONS:
  --dry-run           Preview all changes without writing any files
  --skip-deps-check   Skip the required-dependency pre-flight check (dogfood/dev only)
  --with-claude-mem   Print URL to install claude-mem (AGPL-3.0 — your responsibility)
  --with-tacit-kb     Print URL to install tacit-kb plugin (internal, license unclear)
  --with-docsync      Print URL to install doc-sync plugin (internal, license unclear)
  --help              Show this help message

REQUIRED upstream plugins (auto-detected, install BEFORE running this script):
  superpowers (MIT, by Jesse Vincent / @obra)
    claude plugin marketplace add obra/superpowers-marketplace
    claude plugin install superpowers@superpowers-marketplace
  PUA (MIT, by TanWei Security Lab / @tanweai)
    git clone https://github.com/tanweai/pua ~/.claude/plugins/pua

BUNDLED plugin (auto-installed by this script in Phase 1.5):
  OODC (Apache-2.0) — bundled in plugins/oodc/, copied to
  ~/.claude/plugins/oodc/ during install.

ENVIRONMENT:
  INSTALL_DRY_RUN=1   Same as --dry-run
  HARNESS_HOME        Installation target (default: ~/.claude/plugins/keel-harness-mp)
  CLAUDE_HOME         Claude config dir (default: ~/.claude)

PHASES:
  Phase 0.5: Required upstream plugin check (superpowers + PUA, ABORT if missing)
  Phase 1:   Copy all kernel files from manifest.json → HARNESS_HOME
  Phase 1.5: Install bundled OODC plugin → ~/.claude/plugins/oodc/
  Phase 2:   CLAUDE.md merge (global prompt + project template cp)
  Phase 3:   settings.json jq merge with atomic backup + dry-run diff
  Phase 4:   Optional plugin flags (claude-mem / tacit-kb / docsync — URL only)
  Phase 5:   Layer 0 5-element health check (verify install integrity)

IDEMPOTENT: Safe to re-run. Detects existing install via manifest hash comparison.

EOF
}

# ── Parse arguments ───────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run)          FLAG_DRY_RUN=1 ;;
    --skip-deps-check)  FLAG_SKIP_DEPS_CHECK=1 ;;
    --with-claude-mem)  FLAG_WITH_CLAUDE_MEM=1 ;;
    --with-tacit-kb)    FLAG_WITH_TACIT_KB=1 ;;
    --with-docsync)     FLAG_WITH_DOCSYNC=1 ;;
    --help|-h)          usage; exit 0 ;;
    *)                  error "Unknown flag: $arg"; usage; exit 1 ;;
  esac
done

[[ "$FLAG_DRY_RUN" == "1" || "$DRY_RUN" == "1" ]] && DRY_RUN=1 && FLAG_DRY_RUN=1

[[ "$FLAG_DRY_RUN" == "1" ]] && info "DRY-RUN mode active — no files will be written"

# ── Dep check ─────────────────────────────────────────────────────────────────
check_and_install_jq() {
  if command -v jq &>/dev/null; then
    return 0
  fi
  warn "jq not found. Attempting auto-install..."
  if [[ "$DRY_RUN" == "1" ]]; then
    dry "install jq (brew install jq or apt-get install -y jq)"
    return 0
  fi
  if [[ "$(uname)" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
      brew install jq || { error "brew install jq failed. Install jq manually: https://stedolan.github.io/jq/download/"; exit 1; }
    else
      error "Homebrew not found. Install jq manually: https://stedolan.github.io/jq/download/"
      exit 1
    fi
  else
    if command -v apt-get &>/dev/null; then
      sudo apt-get install -y jq || { error "apt-get install jq failed. Install jq manually: https://stedolan.github.io/jq/download/"; exit 1; }
    elif command -v yum &>/dev/null; then
      sudo yum install -y jq || { error "yum install jq failed. Install jq manually: https://stedolan.github.io/jq/download/"; exit 1; }
    else
      error "No supported package manager found. Install jq manually: https://stedolan.github.io/jq/download/"
      exit 1
    fi
  fi
  success "jq installed successfully"
}

check_deps() {
  info "Checking dependencies..."
  check_and_install_jq
  if ! command -v git &>/dev/null; then
    warn "git not found (optional, used for hash checks)"
  fi
  success "Dependency check passed"
}

# ── Phase 0.5: Required upstream plugin check (superpowers + PUA) ────────────
# These two are MIT-licensed OSS plugins that harness workflow MDs reference at
# runtime. Without them, Skill tool calls in Read PUA/superpowers/* will fail.
phase0_required_deps_check() {
  info "Phase 0.5: Required upstream plugin check (superpowers + PUA)"

  local missing=()

  # superpowers detection: marketplace cache OR direct install
  if [[ ! -d "${CLAUDE_HOME}/plugins/cache/superpowers-marketplace" ]] && \
     [[ ! -d "${CLAUDE_HOME}/plugins/marketplaces/superpowers-marketplace" ]] && \
     [[ ! -d "${CLAUDE_HOME}/plugins/superpowers" ]]; then
    missing+=("superpowers")
  fi

  # PUA detection: direct install OR marketplace cache
  if [[ ! -f "${CLAUDE_HOME}/plugins/pua/plugin.json" ]] && \
     [[ ! -d "${CLAUDE_HOME}/plugins/cache/pua-skills" ]]; then
    missing+=("pua")
  fi

  if [[ ${#missing[@]} -eq 0 ]]; then
    success "  Phase 0.5: superpowers + PUA detected"
    return 0
  fi

  echo ""
  echo -e "${RED}═══════════════════════════════════════════════════════════════════${NC}"
  echo -e "${RED}  REQUIRED DEPENDENCIES MISSING${NC}"
  echo -e "${RED}═══════════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "  harness-engineering depends on TWO upstream OSS plugins (MIT)."
  echo "  Without them, workflow MDs reference Skill protocols that cannot load."
  echo ""

  local m
  for m in "${missing[@]}"; do
    case "$m" in
      superpowers)
        echo -e "${YELLOW}  [MISSING] superpowers (MIT, by Jesse Vincent / @obra)${NC}"
        echo "    Provides: writing-plans, dispatching-parallel-agents, TDD,"
        echo "              verification-before-completion, brainstorming,"
        echo "              executing-plans, subagent-driven-development."
        echo "    Install:"
        echo "      claude plugin marketplace add obra/superpowers-marketplace"
        echo "      claude plugin install superpowers@superpowers-marketplace"
        echo "    Repo: https://github.com/obra/superpowers"
        echo ""
        ;;
      pua)
        echo -e "${YELLOW}  [MISSING] PUA (MIT, by TanWei Security Lab / @tanweai)${NC}"
        echo "    Provides: P10/P9/P8/P7 role protocols, red-line enforcement,"
        echo "              Romeo evaluator, parallel agent topology."
        echo "    Install:"
        echo "      git clone https://github.com/tanweai/pua \\"
        echo "        ~/.claude/plugins/pua"
        echo "    Repo: https://github.com/tanweai/pua"
        echo ""
        ;;
    esac
  done

  echo -e "${RED}  Re-run install.sh after installing the above.${NC}"
  echo "  (Use --skip-deps-check ONLY for development/dogfood.)"
  echo ""

  if [[ "$FLAG_SKIP_DEPS_CHECK" == "1" ]]; then
    warn "  --skip-deps-check provided. Continuing without required deps."
    warn "  harness will install but workflow MDs reference missing skills."
    return 0
  fi

  exit 2
}

# ── Phase 1: Copy kernel files ────────────────────────────────────────────────
phase1_copy_kernel_files() {
  info "Phase 1: Copying kernel files → ${HARNESS_HOME}"

  local manifest="${REPO_ROOT}/manifest.json"
  if [[ ! -f "$manifest" ]]; then
    error "manifest.json not found at ${manifest}"
    exit 1
  fi

  # Read kernel_files from manifest
  local kernel_files
  kernel_files=$(jq -r '.kernel_files[]' "$manifest")

  if [[ "$DRY_RUN" == "1" ]]; then
    dry "mkdir -p ${HARNESS_HOME}"
    while IFS= read -r rel_path; do
      dry "cp ${REPO_ROOT}/${rel_path} → ${HARNESS_HOME}/${rel_path}"
    done <<< "$kernel_files"
    success "Phase 1 (dry-run): would copy $(echo "$kernel_files" | wc -l | tr -d ' ') files"
    return 0
  fi

  mkdir -p "$HARNESS_HOME"

  local copied=0
  while IFS= read -r rel_path; do
    local src="${REPO_ROOT}/${rel_path}"
    local dst="${HARNESS_HOME}/${rel_path}"
    local dst_dir
    dst_dir="$(dirname "$dst")"

    if [[ ! -f "$src" ]]; then
      warn "Source file not found: ${src} — skipping"
      continue
    fi

    mkdir -p "$dst_dir"
    cp "$src" "$dst"
    (( copied++ )) || true
  done <<< "$kernel_files"

  success "Phase 1 complete: ${copied} kernel files copied to ${HARNESS_HOME}"
}

# ── Phase 1.5: Install bundled OODC plugin ────────────────────────────────────
# OODC plugin is shipped inside this repo at plugins/oodc/. Phase 1.5 copies it
# to ~/.claude/plugins/oodc/ so Claude Code can discover and load it.
phase1_5_install_bundled_plugins() {
  info "Phase 1.5: Install bundled OODC plugin"

  local oodc_src="${REPO_ROOT}/plugins/oodc"
  local oodc_dst="${CLAUDE_HOME}/plugins/oodc"

  if [[ ! -d "$oodc_src" ]]; then
    warn "Bundled OODC source not found at ${oodc_src} — skipping"
    return 0
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    dry "mkdir -p ${oodc_dst}"
    dry "cp -R ${oodc_src}/* ${oodc_dst}/"
    success "Phase 1.5 (dry-run): would install bundled OODC to ${oodc_dst}"
    return 0
  fi

  if [[ -d "$oodc_dst" ]] && [[ -f "$oodc_dst/plugin.json" ]]; then
    warn "  ~/.claude/plugins/oodc/ already exists — backing up to oodc.bak.$(date +%s)"
    mv "$oodc_dst" "${oodc_dst}.bak.$(date +%s)"
  fi

  mkdir -p "$oodc_dst"
  cp -R "$oodc_src"/* "$oodc_dst/"

  success "Phase 1.5 complete: OODC v$(jq -r '.version' "$oodc_dst/plugin.json") installed to ${oodc_dst}"
}

# ── Phase 2: CLAUDE.md merge ──────────────────────────────────────────────────

# Harness section template — single definition used by both Phase 2a and 2b.
# Marker substring "## §harness mode" is guaranteed to be present in this block
# and is used as the idempotency grep key.
_harness_section_content() {
  cat <<'HARNESS_CONTRACT'

## §harness mode Activation Rules (Project Entry Anchor)

Automatically activates when entering a harness project (project with `.harness/state`).

**Trigger Conditions** (any one triggers entry):
1. cwd contains `.harness/state` file
2. Single session has run ≥24h
3. User says "continue last time" / "pick up sN" / "harness mode"
4. SessionStart injection contains LATEST_HANDOFF_BANNER

**After Activation: Required 3-Step Read** (fixed order):
1. Read `<cwd>/CLAUDE.md` — project identity + bible entry + sprint state + hooks quick-ref
2. Read `<cwd>/HARNESS_BIBLE.md` — §line 3-22 Bible First Law / §0.1 Layer 0 5 Elements
3. Read `<cwd>/.harness/handoff-sN-to-sN+1.md` (latest sN) — authoritative next_action

**5 Session Opening Checklist**:
1. Read latest handoff MD
2. Read Plan (ratified)
3. Answer Q1 project identity
4. Answer Q4 LATEST_HANDOFF_NAME via grep (no fuzzy fallback)
5. Answer Q5 current week/phase

**3 Red Lines** (violation drops below 3.75 baseline):
- Bible First Law: `$CLAUDE_HOME` only single deployment
- Layer 0 5-Element Rule: elements a/b/c/d/e — missing any = silent dead
- Q4 Fix Method B: grep LATEST_HANDOFF_NAME literal, no fallback

HARNESS_CONTRACT
}

# safe_install_claude_md_section TARGET_PATH LABEL NEW_INSTALL_TEMPLATE
#
# Branches (matching spec):
#   1. TARGET_PATH does not exist  → cp NEW_INSTALL_TEMPLATE → TARGET_PATH (new install)
#   2. TARGET_PATH exists AND already contains "## §harness mode"
#                                  → idempotent skip (no backup, no prompt)
#   3. TARGET_PATH exists, no harness section
#                                  → backup FIRST, then prompt, then append on Y
#
# In DRY_RUN mode: prints what WOULD happen (including backup path and branch taken).
# Respects set -euo pipefail throughout.
safe_install_claude_md_section() {
  local target_path="$1"
  local label="$2"
  local new_install_template="$3"
  local harness_marker="## §harness mode"

  if [[ "$DRY_RUN" == "1" ]]; then
    if [[ ! -f "$target_path" ]]; then
      dry "${label}: target does not exist → would cp ${new_install_template} → ${target_path}  [branch: new install]"
    elif grep -q "$harness_marker" "$target_path" 2>/dev/null; then
      dry "${label}: harness section already present in ${target_path} → would skip  [branch: idempotent]"
    else
      local backup_path="${target_path}.harness-backup-$(date +%s)"
      dry "${label}: file exists, no harness section → would backup to ${backup_path}  [branch: backup+prompt]"
      dry "${label}: → would prompt 'Append harness mode anchor section to ${target_path}? [Y/n]'"
      dry "${label}: → on Y: append harness section; on N: skip with warning"
    fi
    return 0
  fi

  if [[ ! -f "$target_path" ]]; then
    # Branch 1: new install
    if [[ -f "$new_install_template" ]]; then
      cp "$new_install_template" "$target_path"
      success "${label}: Created ${target_path} from template"
    else
      warn "${label}: template not found at ${new_install_template} — skipping"
    fi
    return 0
  fi

  if grep -q "$harness_marker" "$target_path" 2>/dev/null; then
    # Branch 2: idempotent — harness section already present
    info "${label}: harness section already present in ${target_path}, skipping (idempotent)"
    return 0
  fi

  # Branch 3: file exists, no harness section — backup FIRST, then prompt
  local backup_path="${target_path}.harness-backup-$(date +%s)"
  cp "$target_path" "$backup_path"
  info "${label}: Backup: ${backup_path}"

  echo ""
  echo "  Found existing ${target_path} (no harness section)"
  printf "  Append harness mode anchor section to ${target_path}? [Y/n] "
  local answer
  read -r answer
  answer="${answer:-Y}"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    printf '\n' >> "$target_path"
    _harness_section_content >> "$target_path"
    success "${label}: Appended harness contract to ${target_path}"
  else
    warn "${label}: Skipped (user chose N). Backup: ${backup_path}"
    warn "  Manual append: cat <harness section> >> ${target_path}"
  fi
}

phase2_claude_md() {
  info "Phase 2: CLAUDE.md merge"

  local global_template="${REPO_ROOT}/templates/CLAUDE.md.global.template"
  local project_template="${REPO_ROOT}/templates/CLAUDE.md.project.template"
  local global_dest="${CLAUDE_HOME}/CLAUDE.md"
  local project_dest="${PWD}/CLAUDE.md"

  # Phase 2a: global ~/.claude/CLAUDE.md
  safe_install_claude_md_section "$global_dest" "Phase 2a" "$global_template"

  # Phase 2b: project $PWD/CLAUDE.md
  safe_install_claude_md_section "$project_dest" "Phase 2b" "$project_template"
}

# ── Phase 3: settings.json jq merge ──────────────────────────────────────────
phase3_settings_json() {
  info "Phase 3: settings.json jq merge"

  local settings_template="${REPO_ROOT}/templates/settings.json.template"
  local settings_dest="${CLAUDE_HOME}/settings.json"
  local tmp_merged tmp_merged_base
  # Cross-platform mktemp: macOS BSD mktemp does NOT substitute X's followed by
  # a suffix like .json (would create literal "XXXXXX.json"). Use suffix-free
  # template + post-rename, which works on both macOS and Linux.
  tmp_merged_base="$(mktemp /tmp/harness-settings-merged-XXXXXX)"
  tmp_merged="${tmp_merged_base}.json"
  mv "$tmp_merged_base" "$tmp_merged"

  if [[ ! -f "$settings_template" ]]; then
    warn "Phase 3: settings.json.template not found — skipping"
    return 0
  fi

  # Ensure jq is available (Phase 3 requires it)
  if ! command -v jq &>/dev/null; then
    warn "Phase 3: jq not available — skipping settings.json merge"
    return 0
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    if [[ -f "$settings_dest" ]]; then
      dry "backup ${settings_dest} → ${settings_dest}.harness-backup-<timestamp>"
      dry "jq deep merge: user keys preserved, harness hooks appended"
      dry "show diff to user and prompt for confirmation"
    else
      dry "cp ${settings_template} → ${settings_dest}"
    fi
    rm -f "$tmp_merged"
    return 0
  fi

  if [[ -f "$settings_dest" ]]; then
    # Atomic backup
    local backup_path
    backup_path="${settings_dest}.harness-backup-$(date +%s)"
    cp "$settings_dest" "$backup_path"
    info "  Backup created: ${backup_path}"

    # Deep merge: user settings win for scalars, harness hooks appended
    if ! jq -s '
      .[0] as $user |
      .[1] as $harness |
      # Deep merge: user scalars win, hooks arrays: append harness entries not already present
      def merge_hooks(user_hooks; harness_hooks):
        (user_hooks // []) +
        [ harness_hooks[]? |
          . as $h |
          if (user_hooks // [] | map(.hooks[0].command?) | index($h.hooks[0].command?)) then empty
          else $h
          end
        ];
      $user * $harness |
      if $user.hooks then
        .hooks = (
          $harness.hooks | to_entries | map(
            .key as $event |
            .value = merge_hooks($user.hooks[$event]; $harness.hooks[$event])
          ) | from_entries
        ) + ($user.hooks | to_entries | map(select(.key as $k | $harness.hooks | has($k) | not)) | from_entries)
      else .
      end
    ' "$settings_dest" "$settings_template" > "$tmp_merged" 2>/dev/null; then
      # Fallback: simple deep merge if complex hook dedup fails
      warn "  Advanced hook-dedup merge failed; falling back to simple deep merge"
      jq -s '.[0] * .[1]' "$settings_dest" "$settings_template" > "$tmp_merged"
    fi

    # Validate merged JSON
    if ! jq . "$tmp_merged" > /dev/null 2>&1; then
      error "Phase 3: Merged JSON invalid — aborting. Backup at: ${backup_path}"
      rm -f "$tmp_merged"
      exit 1
    fi

    # Show diff
    echo ""
    echo "  === settings.json diff (- current, + merged) ==="
    diff <(jq -S . "$settings_dest" 2>/dev/null) <(jq -S . "$tmp_merged" 2>/dev/null) | head -40 || true
    echo "  ================================================="
    echo ""
    printf "  Apply harness hooks to settings.json? [Y/n] "
    local answer
    read -r answer
    answer="${answer:-Y}"
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      mv "$tmp_merged" "$settings_dest"
      success "Phase 3: settings.json updated with harness hooks (backup: ${backup_path})"
    else
      warn "Phase 3: Skipped settings.json merge (user chose N)"
      warn "  Backup at: ${backup_path}"
      warn "  To apply manually: jq -s '.[0] * .[1]' ~/.claude/settings.json ${settings_template} > ~/.claude/settings.json"
      rm -f "$tmp_merged"
    fi
  else
    # No existing settings.json — install template directly
    mkdir -p "$CLAUDE_HOME"
    cp "$settings_template" "$settings_dest"
    success "Phase 3: settings.json created from template"
    rm -f "$tmp_merged"
  fi
}

# ── Phase 4: Optional plugin flags ───────────────────────────────────────────
# Note: superpowers + PUA moved to Phase 0.5 (REQUIRED). OODC moved to Phase 1.5
# (BUNDLED, auto-installed). Phase 4 only handles 3 truly-optional plugins.
phase4_optional_plugins() {
  local any=0

  if [[ "$FLAG_WITH_CLAUDE_MEM" == "1" ]]; then
    any=1
    info "Phase 4: --with-claude-mem"
    echo ""
    echo -e "  ${RED}⚠ AGPL-3.0 LICENSE WARNING${NC}"
    echo "  ─────────────────────────────────────────────────────────────────"
    echo "  claude-mem is licensed under AGPL-3.0."
    echo "  We do NOT install it for you to avoid license contamination."
    echo "  AGPL-3.0 has strong copyleft requirements: any software that"
    echo "  uses or distributes code under AGPL-3.0 must also be released"
    echo "  under AGPL-3.0 (including network-use SaaS)."
    echo ""
    echo "  Visit for manual install: https://github.com/mr-shaper/claude-mem"
    echo "  YOUR RESPONSIBILITY TO COMPLY with AGPL-3.0 terms."
    echo "  ─────────────────────────────────────────────────────────────────"
    echo ""
  fi

  if [[ "$FLAG_WITH_TACIT_KB" == "1" ]]; then
    any=1
    info "Phase 4: --with-tacit-kb"
    echo "  tacit-kb is an internal plugin (license unclear)."
    echo "  Visit: https://github.com/mr-shaper/tacit-kb (if public)"
    echo "  Install manually per its README. We do NOT install it for you."
    echo ""
  fi

  if [[ "$FLAG_WITH_DOCSYNC" == "1" ]]; then
    any=1
    info "Phase 4: --with-docsync"
    echo "  doc-sync is an internal plugin (license unclear)."
    echo "  Visit: https://github.com/mr-shaper/doc-sync (if public)"
    echo "  Install manually per its README. We do NOT install it for you."
    echo ""
  fi

  [[ "$any" == "0" ]] && info "Phase 4: No optional plugins requested (use --with-* flags to see URLs)"
}

# ── Phase 5: Layer 0 5-element health check ───────────────────────────────────
phase5_health_check() {
  info "Phase 5: Layer 0 5-element health check"

  local manifest="${REPO_ROOT}/manifest.json"
  local kernel_files
  kernel_files=$(jq -r '.kernel_files[]' "$manifest" 2>/dev/null || echo "")

  local pass=0
  local fail=0

  if [[ "$DRY_RUN" == "1" ]]; then
    dry "verify all kernel files present in ${HARNESS_HOME}"
    dry "verify ${CLAUDE_HOME}/settings.json contains harness hooks"
    dry "verify ${CLAUDE_HOME}/CLAUDE.md contains §harness mode section"
    success "Phase 5 (dry-run): health check skipped"
    return 0
  fi

  echo ""
  echo "  [a] Kernel files in HARNESS_HOME"
  local missing_count=0
  while IFS= read -r rel_path; do
    [[ -z "$rel_path" ]] && continue
    if [[ ! -f "${HARNESS_HOME}/${rel_path}" ]]; then
      warn "    MISSING: ${HARNESS_HOME}/${rel_path}"
      (( missing_count++ )) || true
    fi
  done <<< "$kernel_files"
  if [[ "$missing_count" == "0" ]]; then
    success "    [a] All kernel files present"
    (( pass++ )) || true
  else
    error "    [a] ${missing_count} kernel files missing"
    (( fail++ )) || true
  fi

  echo "  [b] HARNESS_HOME directory exists"
  if [[ -d "$HARNESS_HOME" ]]; then
    success "    [b] ${HARNESS_HOME} exists"
    (( pass++ )) || true
  else
    error "    [b] ${HARNESS_HOME} missing"
    (( fail++ )) || true
  fi

  echo "  [c] settings.json contains harness hooks"
  local settings_dest="${CLAUDE_HOME}/settings.json"
  if [[ -f "$settings_dest" ]] && jq -e '.hooks.Stop' "$settings_dest" &>/dev/null; then
    success "    [c] settings.json has harness hooks"
    (( pass++ )) || true
  else
    warn "    [c] settings.json missing or lacks harness hooks (run Phase 3)"
    (( fail++ )) || true
  fi

  echo "  [d] CLAUDE.md (global) readable"
  local global_claude="${CLAUDE_HOME}/CLAUDE.md"
  if [[ -f "$global_claude" ]]; then
    success "    [d] ${global_claude} exists"
    (( pass++ )) || true
  else
    warn "    [d] ${global_claude} not found (optional — create manually)"
    (( fail++ )) || true
  fi

  echo "  [e] §harness mode contract present in global CLAUDE.md"
  if [[ -f "$global_claude" ]] && grep -q "harness mode" "$global_claude" 2>/dev/null; then
    success "    [e] §harness mode contract found in CLAUDE.md"
    (( pass++ )) || true
  else
    warn "    [e] §harness mode contract not found (run Phase 2 with Y)"
    (( fail++ )) || true
  fi

  echo ""
  echo "  ─────────────────────────────────────────────────────────────────"
  echo "  Layer 0 Health: ${pass}/5 elements OK, ${fail}/5 elements WARN/FAIL"
  echo "  ─────────────────────────────────────────────────────────────────"

  if [[ "$fail" == "0" ]]; then
    success "Phase 5 complete: All 5 Layer 0 elements healthy"
  else
    warn "Phase 5: ${fail} element(s) need attention — see warnings above"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "  harness-engineering installer v${HARNESS_VERSION}"
  echo "  ─────────────────────────────────────────────────"
  echo ""

  check_deps
  echo ""
  phase0_required_deps_check
  echo ""
  phase1_copy_kernel_files
  echo ""
  phase1_5_install_bundled_plugins
  echo ""
  phase2_claude_md
  echo ""
  phase3_settings_json
  echo ""
  phase4_optional_plugins
  echo ""
  phase5_health_check
  echo ""

  if [[ "$DRY_RUN" == "1" ]]; then
    success "DRY-RUN complete. No files were written."
  else
    success "harness-engineering install complete!"
    echo ""
    echo "  Next steps:"
    echo "    1. Restart Claude Code to activate hooks"
    echo "    2. Open any project directory and start harness mode"
    echo "    3. See README.md for full documentation"
    echo ""
  fi
}

main "$@"

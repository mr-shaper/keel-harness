# Changelog

All notable changes to **keel-harness** are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0-alpha.4] — 2026-05-05 — Context-aware handoff (PCT gate + model-aware WINDOW)

### Added

- ✨ **`hooks/post-tool-context-monitor.sh`**: New PostToolUse hook that computes
  `context%` from the transcript's last assistant message usage on every tool call,
  persists `total/window/pct` to `.harness/hook-trace.log`, and emits stderr alerts
  at the 60% / 70% thresholds. The 70% line is a HARD STOP nudge to start a fresh
  session; the 60% line writes a `handoff-required.flag` and emits a soft warning.
  The total-token formula matches the upstream claude-hud `getTotalTokens`
  (`src/stdin.ts:134-141`): `cache_read + cache_creation + input` —
  `output_tokens` is intentionally excluded since it does not contribute to the
  current context occupancy seen by the model on the next turn.

- ✨ **Model-aware context window** in the new hook. The window auto-detects from
  the transcript's last assistant `message.model` field: any model id matching
  `*haiku*` resolves to `WINDOW=200000` (Haiku 4.5 ships with a 200k window);
  Opus / Sonnet (and unknown / unmatched ids) default to `WINDOW=1000000` with
  the existing `HARNESS_CTX_WINDOW` env override available. Without this fix,
  sessions on Haiku reported PCT 5× lower than reality and the 70% gate never
  fired, masking real context pressure until the session crashed.

- ✨ **`tests/test-context-aware-handoff.sh`**: e2e test suite (7 cases) covering
  the gate's skip / above-gate / cold-start fallback / force-flag / env-override
  paths plus Haiku-vs-Opus window detection. Default mode runs all 7; the
  `--post-tool-only` flag restricts to Test 6+7 (no stop-handoff dependency).

### Changed

- 🔧 **`hooks/stop-handoff-writer.sh`**: Added a context-aware gate near the top
  of the script (after the harness-project check, before field collection). The
  gate reads the latest `pct` value from `.harness/hook-trace.log`. If the value
  is numeric and below `HARNESS_HANDOFF_PCT_THRESHOLD` (default 70), the hook
  writes a `SKIP ctx=N% < threshold=70%` trace line and exits 0 without writing
  the handoff file. A `.harness/handoff-force.flag` file overrides the gate for
  one Stop event (the flag is auto-cleared on success). Long sessions no longer
  accumulate handoff churn on every Stop — only when context pressure crosses
  the gate. If the trace log is missing or unparseable (cold start, race), the
  gate falls through to the original write path (safe side, never lose a handoff).

- 🔧 **`templates/settings.json.template`**: Registered the new
  `post-tool-context-monitor.sh` hook as a `PostToolUse` entry with `matcher: "*"`
  so it fires on every tool call (5-second timeout). Bumped
  `_harness_hooks_count` 9 → 10.

- 🔧 **`manifest.json`**: Added `hooks/post-tool-context-monitor.sh` to
  `kernel_files[]` so `install.sh` Phase 1 copies the hook into `HARNESS_HOME`
  alongside the other kernel hooks.

### Why this matters

- 🟡 **Long-session handoff churn** (alpha.3 and earlier): every Stop event wrote
  a fresh `.harness/handoff.md`, regardless of whether the session had actually
  accumulated context warranting a handoff. Long dev sessions racked up dozens
  of near-identical handoffs on every interactive pause.
- 🔴 **Haiku PCT under-report (5×)** (alpha.3 and earlier): the original PCT
  formula was hardcoded to a 1M context window. Sessions running Claude Haiku 4.5
  (200k window) reported PCT at 1/5 of the real value, so the 70% nudge never
  fired and users hit the actual context limit without warning.
- 🔵 **`output_tokens` over-counting** (alpha.3 and earlier): including
  `output_tokens` in the total inflates PCT by up to ~6% in edge cases and breaks
  alignment with upstream tooling that consumes the same usage object.

### Verification

- All existing 6 test suites continue to PASS, plus the new
  `test-context-aware-handoff.sh` adds 7 cases (5 stop-handoff PCT-gate paths +
  2 post-tool model-aware paths).
- New hook tested via dummy `.harness/` fixtures with both Opus and Haiku
  transcripts; trace shows `window=200000` for Haiku and `window=1000000` for
  Opus.
- Existing Stop hook behavior is unchanged when `hook-trace.log` is absent (cold
  start) or contains no parsable `ctx-monitor` line — the gate falls through to
  the original write path (safe side).

---

## [0.1.0-alpha.3] — 2026-05-04 — Romeo R2 audit fix (6 findings, 0 P0/P1)

### Fixed

- 🟡 **P2 (Romeo R2 NEW finding — `tests/test-install.sh:113,140,174,220`)**: cases
  3, 4, 5, 6 lacked the same hermetic `cd "$project_dir"` isolation that alpha.2 added
  to the sister file `test-install-claude-md-safety.sh`. The alpha.2 P1 fix solved the
  problem in the wrong scope — sister-file regression. Cases passed only because the
  repo's own `CLAUDE.md` contains `## §harness mode` (silent idempotent-skip on
  Phase 2b). Would surface as hard test failure on a clone with the sentinel stripped.
  Fixed: all 4 cases now allocate a `project_dir="${ws}/project"` and run install via
  `cd "$project_dir" && bash "$INSTALL" ...` subshell, matching the sister file's
  alpha.2 fix.

- 🟡 **P2 (Romeo R2 NEW finding — `.github/workflows/tests.yml:77-95`)**: CI step
  for `test-install-claude-md-safety.sh` (and sibling `test-red-team.sh`) used a
  `if [[ -f tests/<file> ]]` soft guard. Deleting/renaming the test file → CI prints
  "not found, skipping" and exits 0 = silently green. The entire safety suite could
  vanish without a CI failure signal. Fixed: replaced both soft-guarded blocks with
  hard `bash tests/<file>` registration. Sister-file preempt applied to
  `test-red-team.sh` for the same reason.

- 🟡 **P2 (Romeo R1 deferred, R2 confirmed — `install.sh:284-289`)**: OODC backup
  TOCTOU. `$(date +%s)` was evaluated twice (warn message + mv path). On a slow
  system or under I/O pressure, a Unix-second boundary could leave the warn line
  pointing at a path that doesn't exist. Fixed: capture `oodc_ts="$(date +%s)"` once,
  reuse on both lines.

- 🟡 **P2 (Romeo R1 deferred, R2 confirmed — `install.sh:644`)**: Phase 5 health
  check element [e] used the weak substring `grep -q "harness mode"` while Phase 2's
  canonical idempotency sentinel is `## §harness mode`. Any `CLAUDE.md` mentioning
  the phrase in prose (e.g., a trigger-condition comment) would false-pass element
  [e]. Fixed: tightened to `grep -q "## §harness mode"` matching Phase 2.

- 🔵 **P3 (Romeo R2 NEW finding — `install.sh:432,438`)**: Phase 3 settings.json
  merge function created `$tmp_merged` via `mktemp` at the top, but two early-return
  guards (`settings_template not found`, `jq not available`) returned without
  cleaning up. Every install on a system missing the template or `jq` leaked one
  `/tmp/harness-settings-merged-XXXXXX.json` file. Fixed: added `rm -f "$tmp_merged"`
  to both early-return paths.

- 🔵 **P3 (Romeo R2 NEW finding — `tests/test-install-claude-md-safety.sh:245`)**:
  Comment in case 5 said "N for global CLAUDE.md, N for project CLAUDE.md" but the
  actual stdin routing was: claude_home has no CLAUDE.md → Phase 2a hits Branch 1
  (no prompt) → first N answers Phase 2b → second N answers Phase 3. Test worked
  correctly; only the comment misled the reader. Fixed: rewrote comment to reflect
  actual prompt routing.

### Verification

- All 6 test suites PASS (`test-install.sh` 22/22, `test-install-claude-md-safety.sh`
  14/14, `test-pre-commit.sh` 7/7, `test-red-team.sh` 8/8, `test-manifest-completeness.sh`
  2/2, `test-sync.sh` 15/15) — total 68/68 assertions.
- Live dogfood 3/3 PASS on alpha.3 (Case A fresh install, Case B Branch 3
  backup-then-append, Case C `--dry-run` zero writes). Real `~/.claude/` invariant
  held — newest backup age 13239s (3.6h, pre-session) confirms no pollution.
- Phase 5 [e] now reports `5/5 elements OK` with the strict `## §harness mode` sentinel.
- OODC re-install warn message and `oodc.bak.<ts>` directory share single timestamp
  `1777954461` (proves single `oodc_ts` capture works).

### Audit closure

- Romeo R2 6 findings: **6/6 fixed** in alpha.3 (4 P2 + 2 P3, 0 P0/P1).
- ROADMAP.md v0.1.1 P2/P3 items: **2 closed** (OODC TOCTOU + Phase 5 sentinel —
  R1-deferred items now patched here instead of v0.1.1).

---

## [0.1.0-alpha.2] — 2026-05-04 — Romeo R1 audit fix (test rigor + CI gate)

### Fixed

- 🔴 **P1 (Romeo R1 finding)**: `tests/test-install-claude-md-safety.sh` cases 1, 3, 4
  lacked hermetic isolation — they invoked `install.sh` without cd-ing into a temp
  project dir, so `install.sh` Phase 2b targeted the test runner's working directory.
  Cases passed only because the repo's own `CLAUDE.md` happened to contain the harness
  marker (idempotent-skip path). The tests provided false confidence: they did not
  actually verify Phase 2b behavior. Fixed: cases 1, 3, 4 now use the same
  `( cd "$project_dir" && bash install.sh ... )` subshell pattern as cases 2 and 5.
- 🔴 **P1 (Romeo R1 finding)**: `tests/test-install-claude-md-safety.sh` was not
  registered in `.github/workflows/tests.yml`. CI never ran the new suite on push or
  PR. Fixed: added explicit "Run test-install-claude-md-safety.sh" step to the
  existing matrix job.
- 🔴 **P1 (deterministic regression discovered during alpha.2 P9 verify)**:
  v0.1.0-alpha.1's new `install.sh` Phase 2a/2b idempotent-skip branch outputs
  `"skipping (idempotent)"`, which collided with `tests/test-install.sh` line 92's
  over-broad regex `"Source file not found\|skipping"`. Result: test-install
  reported `21 PASS / 1 FAIL` on any host where `$PWD/CLAUDE.md` already contained
  the harness marker. Root cause of P9's false-positive "test pass" claim during
  alpha.1 ship (caught only after CEO challenged). Fixed: tightened grep to literal
  `"Source file not found"` only, with an explanatory comment for future maintainers.

### Verification

- All 6 test cases now run with hermetic isolation (zero pollution in repo root after
  suite run, verified via `git status`).
- CI matrix (macOS + Ubuntu) now executes the new test suite on every push.
- All 6 test suites + new test PASS locally.

### Deferred to v0.1.1 (Romeo R1 P2/P3 findings)

- OODC backup TOCTOU: `$(date +%s)` evaluated twice may mismatch by one second between
  warn message and mv path
- Phase 5 health check sentinel weaker than Phase 2 (`harness mode` vs `## §harness mode`)
- CHANGELOG missing link reference for [0.1.0-alpha.1] heading
- Release notes for v0.1.0-alpha.1 mentioned a "re-run after partial install" case that
  doesn't exist
- Sentinel rename fragility (P3 — any future header rename silently breaks idempotency)
- CI registration discipline (P3 — formalize as gate)

---

## [0.1.0-alpha.1] — 2026-05-04 — User-safety hotfix

### Fixed

- 🔴 **P0 user-safety**: `install.sh` Phase 2b silently overwrote `$PWD/CLAUDE.md`
  (the user's project CLAUDE.md) with the harness template, with no backup, no
  interactive prompt, and no skip-if-exists. Any user who ran `curl ... | bash`
  while cd'd in their existing project directory lost their project CLAUDE.md
  without warning. (Reported by Harrison via dogfood; fixed in this release.)
- Phase 2a (global `~/.claude/CLAUDE.md`) had the inverse problem: it
  interactively prompted but lacked an idempotent skip — re-running install
  would append the harness section a second time, eventually a third time, etc.

### Changed

- Both Phase 2a (global) and Phase 2b (project) now share a single
  `safe_install_claude_md_section()` helper that follows the pattern: detect
  existing → if harness section already present, skip (idempotent) → else backup
  to `*.harness-backup-<timestamp>` → interactively prompt with default Y →
  append section on Y, skip with warning on N. Backup happens BEFORE the prompt
  so even a user typo cannot lose data.

### Verification

- New test suite `tests/test-install-claude-md-safety.sh` covers 6 cases
  (new install, idempotent skip, backup-then-append, backup-then-skip,
  dry-run safety).
- All 5 existing test suites still PASS (no regression).

---

## [Unreleased] — 2026-05-04 (S3-OSS-iter sprint)

OSS kernel hardening derived from cross-host sync-fix retrospective.
Four enhancements that strengthen the universal kernel without exposing private dual-runtime concepts.

### Added

- **`plugins/compound-selfcheck-plugin/`** — New PostToolUse plugin that detects
  large changes (LOC > 100 OR BYTES > 5000) on Write/Edit/MultiEdit/NotebookEdit
  and emits a stderr reminder banner suggesting the change be ingested into a
  knowledge base. Writes audit entries to `.harness/hook-trace.log` with
  `[COMPOUND-CHECK]` prefix for "real-trigger vs performance" distinction.
  Soft-prompt only (exit 0) — never blocks.
- **`docs/sprint-kickoff-checklist.md`** — Five-layer GATE self-check checklist
  (Layer A entity / B content / C gate / D config / E behavior fire). Mandatory
  read at every sprint kickoff to prevent "8/8 PASS but no GATE evidence" score
  inflation.
- **`scripts/sync-self-check.sh`** — Cross-platform 5-layer evidence dump script.
  Maintainer runs it after sprint, reads the dumped evidence, and self-evaluates
  sprint outcome. The script never decides outcome itself (P9-doesn't-decide-L4
  pattern). Read-only by design — no flags, no side effects, always exits 0.
  Uses `$(hostname)` dynamic, `git rev-parse` fallback for `HARNESS_ROOT`.

- **`docs/visuals/`** — Three rendered visual versions of harness core
  concepts, each in a different ljg-card aesthetic mode (English-only, OSS
  attribution footer):
  - `topology-infograph.{html,png}` — 4-Layer Nested Parallel Topology in
    infograph mode (data-density layout, hierarchical 5-layer authority chain
    L0 CEO → P10 → P9 → P8 → P7 with 8 iron rules and benchmark metrics).
  - `pipeline-whiteboard.{html,png}` — Phase 0-4 Pipeline + Wave Structure in
    whiteboard mode (logic-chain style, sequential phase reasoning with red
    dashed arrows and a wave sequence strip).
  - `gaps-sketchnote.{html,png}` — 4 Gaps It Fills + Solutions in sketchnote
    mode (Mike Rohde concept-map style, hand-drawn feel with circled problem
    words, dashed connectors, micro-rotations).
  Three versions exist so a maintainer can pick the aesthetic that best fits
  README hero placement; embedding decision is deferred to a follow-up commit.

### Changed

- **`hooks/pre-tool-handoff-read-gate.sh`** — Introduces a new
  `resolve_harness_root()` function that replaces the previous flat
  `git rev-parse || pwd` fallback. Three explicit priorities:
  (1) git repo root containing `.harness/`,
  (2) `$HARNESS_ROOT` environment variable when set and pointing to a
  `.harness/` directory,
  (3) silent OK exit when neither resolves — preventing the
  "cwd has no `.harness/` → hook silent skip → P9 self-check missing"
  cross-context failure mode.

- **`templates/settings.json.template`** — `PostToolUse` array gains the
  compound-selfcheck wire (matcher `Write|Edit|MultiEdit|NotebookEdit`,
  timeout 10).

- **`hooks/pre-commit`** — `SKIP_PATHS` refined: the previous blanket
  `"docs/"` exemption is replaced with two explicit per-file exemptions
  (`docs/license-audit-report.md`, `docs/manifest-customization-guide.md`).
  This forces `docs/visuals/` and `docs/sprint-kickoff-checklist.md` to
  pass the strict PII gate. `README.zh-CN.md` and `CHANGELOG.md` added
  to the exemption list (bilingual sibling and retrospective release notes
  legitimately reference brand-sweep terms).

- **`manifest.json`** — `kernel_files` adds seven new entries
  (`README.zh-CN.md`, `CHANGELOG.md` newly registered;
  `plugins/compound-selfcheck-plugin/{plugin.json,hook.sh,README.md}`;
  `docs/sprint-kickoff-checklist.md`; `scripts/sync-self-check.sh`).
  An additional positional comma-fix on
  `plugins/oodc/skills/oodc/references/create-protocol.md` appears in the diff
  but is not a new registration (it was already in `kernel_files` and only
  gained a trailing comma when entries were appended after it).
  `private_blacklist_keywords` adds eight scope-forbidden terms
  (`CLAUDE_CONFIG_DIR`, `Maintainer`, `Mobile Documents`, `Mrs-Mac-mini`,
  `Mrs-MacBook-Pro`, `claude-codepilot`, `codepilot`, `dual-runtime`)
  to prevent private terminology leakage in future commits.

### Notes

- The `manifest.json` `private_blacklist_keywords` field is the **scanner
  definition itself** — by necessity it contains the literal forbidden
  strings. Pre-commit hooks must exclude `manifest.json` from blacklist
  scans (meta-paradox: the gate must reference what it forbids).
- This sprint introduces no new `Category H` rules; all changes are kernel
  refinements within the existing `v1.13` ratified scope.

### S3.5 patches (multi-perspective blind audit follow-up)

A second sprint dispatched 3 independent audit perspectives (security/PII deep
scan / OSS maintainer DX / agentic engineering quality) on top of the Romeo
6-dim audit. Each surfaced concrete defects that Romeo's framework did not
catch. Cross-audit consensus fixes:

- **`README.md`** — Static "passing" CI badge replaced with the live GitHub
  Actions badge (linked to the actual `tests.yml` workflow). The static badge
  was always green regardless of CI state, eroding trust.
- **`README.md`** — Removed the false `--dry-run` capability claim from the
  `scripts/sync-self-check.sh` description. The script is read-only by design
  and accepts no flags; the documented capability did not exist.
- **`plugins/compound-selfcheck-plugin/README.md`** — Install snippet path
  corrected: `harness-engineering-mp` → `keel-harness-mp` (the public
  namespace used by `install.sh`). The previous path would have produced a
  silently-broken hook on any install.
- **`templates/settings.json.template`** — Bulk rename of the marketplace name
  and all hook-command paths from `harness-engineering-mp` to
  `keel-harness-mp`. The template's previous default disagreed with
  `install.sh`'s `HARNESS_HOME` choice, meaning hooks would fail to fire on a
  default install (P0 severity bug from the rename in W6 Step 2.5 that the
  template missed).
- **`docs/sprint-kickoff-checklist.md`** — All hardcoded `~/dev/harness-engineering/`
  paths replaced with `${HARNESS_ROOT}` and a setup preamble explaining the
  variable. Previously every command in the checklist was non-portable — a
  fresh OSS clone could not run a single command from the document as-is.
- **`HARNESS_BIBLE.md`** — Two private-path leaks redacted: a
  `~/.claude-codepilot/plans/...` reference and an `iCloud/.../knowledge-base/...`
  reference. Both were protected only by `SKIP_PATHS` exemption (HARNESS_BIBLE.md
  is a SKIP-listed file, so the pre-commit hook could not catch them).
  HARNESS_BIBLE.md `> ZERO ... maintainer references` line generalized away from
  a specific maintainer name.
- **`manifest.json`** — `private_blacklist_keywords` adds three more terms:
  `harness-engineering-mp` (the obsolete pre-rename namespace),
  `MBP` (private device abbreviation),
  `Roy` (a maintainer's given-name token added to prevent future leakage). Total blacklist this sprint: 11 new
  scope-forbidden terms (`Maintainer`, `CLAUDE_CONFIG_DIR`, `MBP`, `Mobile
  Documents`, `Mrs-Mac-mini`, `Mrs-MacBook-Pro`, `Roy`, `claude-codepilot`,
  `claude-roy` was already there, `codepilot`, `dual-runtime`, `harness-engineering-mp`).

### Candidates (forward-looking notes for future sprints)

- **[CANDIDATE] Per-subdirectory pre-commit `SKIP_PATHS`**: The W6 era
  used a `"docs/"` blanket exemption that allowed a brand-sweep regression
  to enter `docs/visuals/` (caught only by Romeo audit). The fix in this
  sprint moved to per-file exemptions — but a more principled approach
  would be hierarchical: an exempted directory should require an explicit
  un-exempt list for higher-risk subdirectories (e.g., `docs/` exempt by
  default, `docs/visuals/` always strict, `docs/license-*.md` exempt).
- **[CANDIDATE] `resolve_harness_root()` Priority 1.5 — cwd `.harness/`
  without git**: The current Priority 1 is `git rev-parse --show-toplevel`,
  so a directory containing `.harness/` but not initialized as a git repo
  will silently skip. Useful for non-git harness experiments (rare but
  worth a Priority 1.5 check on `$PWD/.harness/` directly).
- **[CANDIDATE] Romeo audit as pre-push hook**: This sprint's
  `pre-tool-plan-quality-gate.sh` enforces Romeo ≥0.99 on plan files.
  Extending the same gate to `pre-push` would catch sprint-outcome
  regressions before they hit the remote (caught here only by manual
  audit dispatch).

---

## [0.1.0-alpha] — 2026-05-03

Initial public alpha release. The kernel reaches feature-complete on the
8-week roadmap (Plan rev D: W1 → W6.7) with full English translation, CI
matrix, demo recordings, and private-data sanitization.

### W1 — kernel foundation (2026-05-01)

- Initial commit: harness kernel files (`workflows/`, `hooks/`, `templates/`,
  `audit/`, `manifest.json`, `install.sh`, `sync.sh`, `LICENSE` Apache-2.0,
  `HARNESS_BIBLE.md`).

### W2 — workflow translation (2026-05-01)

- All five core workflow MD files translated from internal Chinese to English
  (926 LOC): `pua-topology` / `oodc-superpower-harness-orchestration` /
  `superpower-pipeline` / `skill-loading-sop` / `kb-ingestion-sop`.
- `manifest.json` hardening (kernel file whitelist + private keyword blacklist).

### W3 — installer (2026-05-01)

- `install.sh` with marketplace dependency declarations
  (superpowers REQUIRED, PUA REQUIRED, OODC BUNDLED).
- `tests/test-install.sh` smoke test.

### W4 — privacy + CI (2026-05-02)

- Five-layer privacy protection in pre-commit hook.
- Red-team test fixture verifying blacklist enforcement.
- GitHub Actions CI workflow (`.github/workflows/`).

### W5 — demos (2026-05-02)

- Four asciinema recordings rendered as agg GIFs
  (`demo/demo-1.gif` through `demo/demo-4.gif`).
- README hero embed of demo-4 (the 90-second elevator demo).

### W6 — release prep (2026-05-03)

- Repository renamed `harness-engineering` → `keel-harness` (W6 Step 2.5).
- shellcheck severity hardening + gitleaks filesystem scan (W6 Steps 2.6–2.8).
- Demo regeneration after rename (W6 Step 2.9).
- Dependencies declarative overhaul (W6 Step 3.0).
- Full-repo English translation pass + bilingual README sibling
  (W6 Step 4.0; `README.zh-CN.md` cross-link added).

### W6.5 — vaporware ship (2026-05-03)

- Eight enforce-core hooks made real (previously template-only).
- Three audit/templates documents (handoff template, Cat-H rule template,
  Romeo 6-dim framework).
- One CI gate workflow renamed.
- Followups: CEO ≠ P10 hierarchy anchoring (concept-level Pattern Replay fix).

### W6.6 — brand sweep (2026-05-03)

- Personal identifiers replaced with `Mr Shaper` brand voice across the
  repository.
- Five-layer PII sanitization hardening.
- Followup: blacklist deduplication + demo-3 manifest_kw cleanup.

### W6.7 — meta-cog fix (2026-05-03)

- `HARNESS_BIBLE.md` placement clarification.
- `Stop` hook smart-pull mechanism for handoff `next_action` (no more
  `TBD-next-action-absent` placeholder).
- `SKIP_PATHS` honored in handoff scanning.

---

[Unreleased]: https://github.com/mr-shaper/keel-harness/compare/v0.1.0-alpha.3...HEAD
[0.1.0-alpha.3]: https://github.com/mr-shaper/keel-harness/compare/v0.1.0-alpha.2...v0.1.0-alpha.3
[0.1.0-alpha.2]: https://github.com/mr-shaper/keel-harness/compare/v0.1.0-alpha.1...v0.1.0-alpha.2
[0.1.0-alpha.1]: https://github.com/mr-shaper/keel-harness/compare/v0.1.0-alpha...v0.1.0-alpha.1
[0.1.0-alpha]: https://github.com/mr-shaper/keel-harness/releases/tag/v0.1.0-alpha

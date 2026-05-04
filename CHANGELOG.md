# Changelog

All notable changes to **keel-harness** are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
  `Roy` (private maintainer first name). Total blacklist this sprint: 11 new
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

[Unreleased]: https://github.com/mr-shaper/keel-harness/compare/v0.1.0-alpha...HEAD
[0.1.0-alpha]: https://github.com/mr-shaper/keel-harness/releases/tag/v0.1.0-alpha

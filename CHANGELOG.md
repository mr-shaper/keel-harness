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
  pattern). Supports `--dry-run`, uses `$(hostname)` dynamic, `git rev-parse`
  fallback for `HARNESS_ROOT`.

### Changed

- **`hooks/pre-tool-handoff-read-gate.sh`** — `resolve_harness_root()` three-path
  fallback ratified (was already in S2 W6.7, formalized as kernel pattern). Now
  resolves harness root via cwd → `$HARNESS_ROOT` env override → silent OK,
  preventing "cwd has no `.harness/` → hook silent skip → P9 self-check missing"
  cross-context failure mode.

- **`templates/settings.json.template`** — `PostToolUse` array gains the
  compound-selfcheck wire (matcher `Write|Edit|MultiEdit|NotebookEdit`,
  timeout 10).

- **`manifest.json`** — `kernel_files` adds two new entries
  (`docs/sprint-kickoff-checklist.md`, `scripts/sync-self-check.sh`).
  `private_blacklist_keywords` adds seven scope-forbidden terms
  (`CLAUDE_CONFIG_DIR`, `Mobile Documents`, `Mrs-Mac-mini`, `Mrs-MacBook-Pro`,
  `claude-codepilot`, `codepilot`, `dual-runtime`) to prevent private terminology
  leakage in future commits.

### Notes

- The `manifest.json` `private_blacklist_keywords` field is the **scanner
  definition itself** — by necessity it contains the literal forbidden strings.
  Pre-commit hooks must exclude `manifest.json` from blacklist scans
  (meta-paradox: the gate must reference what it forbids).
- This sprint introduces no new `Category H` rules; all changes are kernel
  refinements within the existing `v1.13` ratified scope.

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

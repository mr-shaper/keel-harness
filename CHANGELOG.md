# Changelog

All notable changes to **keel-harness** are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0-alpha.9] — 2026-05-14 — s51 Wave 2 R25 watcher cron PATH portable fix (Romeo P2 OSS guide cross-apply correctness)

### Fixed (P0 真活体 bug)

- 🔴 **`~/.claude/scripts/fork-bomb-fix-mtime-watcher.sh`**: macOS cron 默认
  `PATH=/usr/bin:/bin` 不含 `/sbin`, BSD `md5` 在 `/sbin/md5` →
  `command not found` → `$CURRENT=""` ≠ baseline → 假阳性
  `FORK_BOMB_FIX_REVERT_DETECTED`. **真活体血例** 2026-05-14 alert log
  12:00:01 + 12:15:02 两次假阳性 (CURRENT 段空白).

### Added (3 layer defense-in-depth)

- 🛡️ **Layer 1 watcher script**: 顶端 `export PATH="/usr/local/bin:/usr/bin:/bin:/sbin"`
  + portable detect `MD5_CMD=$(command -v md5 \|\| command -v md5sum)`
  (macOS/Linux 自适应) + exit code/empty check (R22 fail-close sibling)
  + R18 atomic mv baseline init.

- 🛡️ **Layer 2 crontab entry**: `PATH=/usr/local/bin:/usr/bin:/bin:/sbin`
  显式前缀双保险, idempotent sed (防 duplicate entry).

- 🛡️ **Layer 3 OSS guide §3.2 + §3.2.1**: 同步 watcher script + 新增
  "⚠️ cron 环境注意" 段防 GitHub OSS 用户照搬踩坑. §4 Step 5 crontab install
  命令同步加 PATH= 前缀 (Romeo P2 finding cross-apply correctness fix).

- 📚 **KB decision MD**: `knowledge-base/raw/ai-systems/decision-s51-wave2-r25-cron-path-fix.md`
  (290 LOC, 7 段) ingest via `kb-ingest-compile.sh --hint decision`
  → `[COMPOUND-PASS]` 三铁律. `kb query "R25 cron PATH 假阳性"` rank 1
  (score 43.35).

- 🔖 **USER CLAUDE.md R25 律本体**: 加 `cron PATH 缺 /sbin` note + 触发词
  3 新增 (`cron PATH 缺 /sbin` / `watcher 假阳性` / `Wave 2 cron 环境注意`).
  v1.13 freeze 红线严守, 不加 Category H ratified 律 (R25 仍 candidate
  maintenance reference).

### Sprint methodology (P10-RATIFY 7 维 ≥0.99 hardcore gate)

- 📋 **Implementation Plan**:
  `docs/plans/2026-05-14-s51-wave2-r25-watcher-cron-path-fix.md`
  (844 LOC, 16 section). 拓扑嵌套并行 4 层 (Harness ⊃ OODC ⊃ Superpower
  Pipeline Phase A-D ⊃ PUA P10-9-8-7 真并行). TaskCreate 看板 8 task
  + blocking chain (T3→T4→T5→T6,T7→T8). Phase 3 Wave A 5 P8 真并行
  (同 message multi-Agent, 文件域 D1-D5 grep verify 0 collision).

- 🔍 **P10 audit 4 round**: round-1 REJECT (6 fix) → round-2 REJECT (1 fix)
  → round-3 REJECT (1 fix D5 OODC Observe/Orient 实证段) → round-4 RATIFY
  全 7 维 ≥0.99 hardcore gate (D1=战略对齐, D2=文件域隔离, D3=Wave 真并行,
  D4=TaskCreate 看板, D5=4 层嵌套, D6=Romeo audit, D7=verify
  evidence-paste).

- 🔬 **Romeo audit (Anthropic Sprint Contract)**: 5/5 P8 coverage (P8-A/B/C/D/E),
  7 Q checklist. 找到 **1 真 bug** (OSS guide §4 Step 5 crontab install
  cmd 缺 PATH= 前缀, OSS 用户照搬还踩坑) + 2 P2 traceability gap.
  全 3 finding P9 inline 闭环修复.

### Verification (12/12 PASS)

- ✅ `env -i PATH=/usr/bin:/bin bash watcher.sh; echo exit=$?` → **exit=0**
  (cron 真活体环境跑通)
- ✅ alert log `FORK_BOMB_FIX_REVERT_DETECTED` 修后 0 hit
- ✅ crontab PATH 显式 = 1 + idempotent = 1
- ✅ OSS guide §3.2 portable detect = 10 hits, cron 环境注意段 = 3
- ✅ KB decision MD ingest [COMPOUND-PASS] + kb query rank 1
- ✅ USER CLAUDE.md R25 段 cron PATH 缺 /sbin = 1 + sibling 律 R10-R24
  零触碰 (diff exit=0)
- ✅ baseline 4 hash 不变 (锁定值 diff exit=0)
- ✅ Romeo fix verify: OSS guide crontab install PATH= = 2, §3.2.2 dangling
  = 0, R25 trigger 3 新词加入

### Sibling 律 family (defense-in-depth, freeze 期 candidate maintenance reference)

- **R13 v3.5** grep+tail 顺序律 — P8-A exit code check 是 fail-close 二层
- **R17** metadata cache 同步 — Rollback Step 6 三层 cleanup
- **R18** atomic write — P8-A baseline 用 mktemp + atomic mv
- **R19 v2** 双机不对称 — Wave B sync to mini cross-peer (.claude-to-im mini only 排除)
- **R22** fail-close — P8-A md5 失败 silent exit 0 不写假 alert
- **R24** rsync --checksum (s51 sprint 1) — Wave B config-import 严守
- **R25** mtime watcher (本 Wave 2 修法对象) — cron PATH note 完整化

---

## [0.1.0-alpha.8] — 2026-05-06 — Handoff-must-ask gate (R16 three-piece + L45 candidate, sibling L24 fix)

### Added

- ✨ **`hooks/pre-tool-handoff-must-ask-gate.sh`**: new PreToolUse hook
  that blocks Write/Edit/MultiEdit on `handoff-sN-to-sN+1.md` files unless
  the originator is explicitly authorised. Three exempt paths:
  (1) `HARNESS_HANDOFF_VIA_STOP=1` env (set by `stop-handoff-writer.sh`
  on its own auto-write), (2) `HARNESS_HANDOFF_USER_OK=1` env (user
  pre-set bypass), (3) a literal-keyword scan over the last 30 user
  messages in the transcript looking for `write handoff` / `go handoff` /
  `yes handoff` / `写 handoff` / `交接 handoff` / `生成 handoff` /
  `写交接`. When none match, exit 2 with stderr lines that *enumerate*
  the three PASS paths — a blocking gate that does not teach itself
  wastes the user's time. (L43: matcher is the literal whitelist
  `Write|Edit|MultiEdit`, never `*`. Internal regex
  `handoff-s[0-9]+-to-s[0-9]+\.md$` keeps work proportional inside the
  whitelist.)

### Changed

- 🔧 **`hooks/stop-handoff-writer.sh`**: at the top of the script (right
  after `set -uo pipefail`), `export HARNESS_HANDOFF_VIA_STOP=1`. This
  marks the subprocess so the new must-ask gate exempts the Stop hook's
  legitimate auto-write while still blocking arbitrary AI writes from
  elsewhere.

- 🔧 **`templates/settings.json.template`**: registered the new hook as a
  PreToolUse entry with an explicit `Write|Edit|MultiEdit` matcher and a
  5-second timeout. Bumped `_harness_hooks_count` 11 → 12.

- 🔧 **`manifest.json`**: added the new hook
  (`hooks/pre-tool-handoff-must-ask-gate.sh`) to `kernel_files[]` so
  `install.sh` Phase 1 ships it.

- 📝 **`docs/r15-and-l44-candidate.md`**: appended the R16 sibling
  pattern (PreToolUse hook + multiple exempt paths + default-block +
  stderr education) and the L45 Cat-H candidate. Documents why R15 and
  R16 are siblings (R15 governs growth, R16 governs creation; both rely
  on the same hook discipline) and gives the recipe for applying R16 to
  future restricted file patterns. Sibling-rule notes extended to
  cover L24 (matcher-scope-mismatch — the reason R16 exists at all).

### Why this matters

The Stop-hook PCT gate (alpha.4–6) controls when the Stop hook *itself*
writes a handoff. It does not — and cannot — control arbitrary Write
tool calls from elsewhere in the session. An autonomous AI that decides
to write `handoff-sN-to-sN+1.md` directly bypasses the PCT gate
entirely. That is L24 (matcher-scope-mismatch) hitting in production:
two different events, two different scopes, one rule covering only one
of them.

R16 is the sibling fix: a PreToolUse hook in the Write/Edit/MultiEdit
scope, regex-filtered to handoff files only, with explicit auto-exempt
for the legitimate Stop-hook originator. Together with the alpha.4–6
PCT gate, the two rules give defense-in-depth: the Stop side governs
*when* the Stop hook fires, the PreToolUse side governs *who* can fire
a Write at all.

### Verification

- `bash -n` syntax PASS on the new hook.
- Mock fixtures cover three scenarios:
  - **A** — non-handoff path (`/tmp/dummy-PROJECT_STATE.md`): regex
    miss → exit 0 silent.
  - **B** — handoff path with no env and no transcript keyword:
    `[HANDOFF-MUST-ASK] ❌ BLOCK` on stderr + exit 2.
  - **C** — handoff path with `HARNESS_HANDOFF_VIA_STOP=1`:
    `[HANDOFF-MUST-ASK] PASS: stop-handoff-writer env exempt` + exit 0.
- All 7 e2e cases continue to PASS.
- All 6 baseline test suites still PASS (75/75 total).

### L43 compliance note

The matcher in `settings.json.template` is a literal whitelist
(`Write|Edit|MultiEdit`), not `*`. The internal regex filter
(`handoff-s[0-9]+-to-s[0-9]+\.md$`) is anchored at end-of-string so
sibling files (`handoff.md`, `handoff-required.flag`, `handoff-lite-*`)
do *not* fire the gate. Matcher discipline + filter discipline together
keep the hook proportional and self-locking-resistant.

---

## [0.1.0-alpha.7] — 2026-05-06 — PROJECT_STATE size-gate forcing function (R15 three-piece + L44 candidate)

### Added

- ✨ **`hooks/post-tool-project-state-size-gate.sh`**: new alert-only
  PostToolUse hook that watches `PROJECT_STATE.md` size on every
  Write/Edit/MultiEdit. When the file passes 180 LOC (the alert
  threshold; the contract's hard cap is 200), the hook emits a
  `[SIZE-GATE-ALERT]` line to stderr and appends to `.harness/alert.log`
  and `.harness/hook-trace.log`. Exit code is always 0 — the hook
  *informs* the user, it never blocks the Write. (L43: alert-only,
  matcher is a literal whitelist, never `*`.)

- ✨ **`templates/PROJECT_STATE.md.template`**: a starter template for a
  harness project's backbone file. Ships with the inline `BACKBONE-FROZEN`
  HTML comment, a `size-contract:` frontmatter block, and the seven
  standard anchors (Identity, Current sprint, Live decisions, Stable
  anchors, Sprint history index, Constraints, Open backlog) so a new
  project starts compliant with R15.

- ✨ **`docs/sprint-history-spec.md`**: convention for collapsing old
  sprint detail out of `PROJECT_STATE.md` into single-file partitions
  under `.harness/sprint-history/sNN-<topic-slug>.md`. Defines the
  filename convention, frontmatter template, `sha256sums.txt` integrity
  workflow, README index, and the manual collapse workflow that is
  triggered when the size-gate alert fires.

- ✨ **`docs/r15-and-l44-candidate.md`**: documents the R15 three-piece
  pattern (inline size contract + forcing-function hook + canonical-md5
  baseline) and the L44 Cat-H candidate that captures the rule for
  ratification once the v1.13 freeze lifts. Explains why each of the
  three pieces fails alone, the sibling-rule family
  (L23 / L31 / L41 / L43 + R12 third constraint), and a recipe for
  applying the pattern to future backbone files.

### Changed

- 🔧 **`templates/settings.json.template`**: registered the new hook as a
  PostToolUse entry with an explicit `Write|Edit|MultiEdit` matcher
  (5-second timeout). Bumped `_harness_hooks_count` 10 → 11.

- 🔧 **`manifest.json`**: added the new hook
  (`hooks/post-tool-project-state-size-gate.sh`) and the new template
  (`templates/PROJECT_STATE.md.template`) to `kernel_files[]` so
  `install.sh` Phase 1 ships both.

### Why this matters

Long-running harness projects accumulate detail in the same backbone file
(`PROJECT_STATE.md`) — across decisions, sprints, and contributors —
and that file routinely outgrows readability. Documented size limits
without enforcement get ignored; enforced limits without a documented
contract feel arbitrary. R15 binds the two: the file declares its own
contract, the hook enforces it, and a baseline md5 anchors the contract
against silent drift.

In real deployment of the upstream harness this hook fired correctly on
a 196-LOC `PROJECT_STATE.md` belonging to a downstream user project — a
cross-project verification that the size-gate behaves the same on a
foreign `.harness/` tree as it does on its own.

### L43 compliance note

The matcher in `settings.json.template` is a literal whitelist:
`"matcher": "Write|Edit|MultiEdit"`. It is **not** `"*"`. A `*` matcher
would let this hook fire on every tool call and risks self-locking the
session if the hook ever degrades. The internal file-path filter (only
fire when the path contains `PROJECT_STATE.md`) keeps the work
proportional even within the whitelist.

### Verification

- All 7 e2e cases continue to PASS.
- All 6 baseline test suites still PASS (75/75 total).
- New hook tested via mock JSON fixture: a 200-LOC dummy
  `PROJECT_STATE.md` produced `[SIZE-GATE-ALERT] PROJECT_STATE.md = 200
  LOC > 180 threshold (200 hard cap)` on stderr, exit code 0. Files
  below threshold (e.g. 50 LOC) emit no alert and exit 0.

---

## [0.1.0-alpha.6] — 2026-05-06 — Symmetric FIRE/SKIP trace (R12 verifiability fix)

### Added

- 🔧 **`hooks/stop-handoff-writer.sh:103-110`**: emit a `FIRE` trace line in
  `.harness/hook-trace.log` when the PCT gate passes, symmetric to the
  existing `SKIP` line. alpha.4 and alpha.5 only wrote a trace when the gate
  *skipped* the handoff. After a real-session Stop event, a user running
  `grep stop-handoff .harness/hook-trace.log` would see zero entries when
  the gate had actually fired correctly, and falsely conclude the hook never
  ran. The third constraint of R12 (fresh-terminal verify-before-completion)
  was unobservable on the success path.

### Why this matters

R12 says "the hook must be observed firing in a fresh session before the fix
is considered shipped." That observation requires a trace line on the
success path, not only on skip. alpha.5 fixed the threshold but left the
verification surface asymmetric — users could verify a SKIP but not a FIRE.
This release makes both observable with a single `grep`:

```
$ grep 'stop-handoff:' .harness/hook-trace.log
[2026-05-06T...] stop-handoff: SKIP ctx=42% < threshold=50%
[2026-05-06T...] stop-handoff: FIRE ctx=63% >= threshold=50%
```

### Verification

- All 7 e2e cases continue to PASS — fixtures inspect `handoff.md`
  presence/absence and SKIP-trace presence; FIRE-trace addition is purely
  additive and does not affect the existing assertions.
- All 6 baseline test suites still PASS (75/75 total).

---

## [0.1.0-alpha.5] — 2026-05-06 — P0 hotfix: PCT gate threshold 70 → 50

### Fixed

- 🔴 **P0 — `hooks/stop-handoff-writer.sh:64`**: the alpha.4 default
  `HARNESS_HANDOFF_PCT_THRESHOLD=70` was empirically wrong. Real-session
  reproduction: Claude UI displayed 71% context while the hook's
  `ctx-monitor` measured 53–58% on the same session (~18% gap — the hook
  follows the upstream claude-hud `getTotalTokens` formula `cache_read +
  cache_creation + input` and intentionally excludes `output_tokens` and
  tooling/system overhead, both of which Claude UI does count). The 70%
  gate therefore never fired in practice; every Stop event hit `SKIP
  ctx=53% < threshold=70%` and the handoff was perpetually skipped,
  defeating the entire feature. Lowered the default to **50** so the gate
  preserves a ~20% buffer below observed real-session ctx% and fires
  reliably. The `HARNESS_HANDOFF_PCT_THRESHOLD` environment-variable
  override remains available for users with an unusual mix.

### Why this matters

- alpha.4 shipped a feature that was, in real sessions, indistinguishable
  from no feature at all — the gate was set above the real ceiling. Users
  installing alpha.4 saw long sessions but no handoff churn reduction
  *and* no handoff being written when context was actually high — both
  worse than the alpha.3 baseline (which always wrote a handoff).
- The bug was caught via dogfood by a downstream user (spiritual-jewelry-dtc
  S0 sprint) who reported `Claude UI 71% but harness hook never fires`.

### Compound takeaway (R12)

Any hook PCT gate (e.g. context-monitor / token-monitor / heartbeat-monitor)
must satisfy three constraints before ship:

1. **Verify against the user-visible PCT** in a real session — `gap > 5%`
   between hook math and UI math is a fix-blocking signal.
2. **Keep ≥20% buffer** below the observed real-session ctx% rather than
   hard-coding the boundary itself (50% default with a 1M window survives
   any realistic Claude-UI-vs-hook gap).
3. **Fresh-terminal verification before completion** — a code-level test
   passing is necessary but not sufficient; the hook must be observed
   firing in a fresh session before the fix is considered shipped.

Recorded as cross-sprint rule R12 in
`patterns/decisions/2026-05-06-harness-context-monitor-threshold-p0-fix-decision.md`.

### Verification

- All 7 `tests/test-context-aware-handoff.sh` cases continue to PASS — the
  test fixtures supply explicit ctx values (30, 60, 75) on either side of
  both the old (70) and new (50) defaults, so no test needed updating.
- All 6 baseline test suites still PASS (75/75 total assertions).

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

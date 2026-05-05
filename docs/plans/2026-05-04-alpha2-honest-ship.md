# v0.1.0-alpha.2 Honest Ship + Phase F Live Dogfood — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking. TaskCreate IDs cross-reference live kanban.

**Goal:** Ship clean `v0.1.0-alpha.2` with HONEST evidence (no false-positive grep), Romeo R2 audit-clean, then run live multi-scenario dogfood proving `install.sh` never overwrites user CLAUDE.md / settings.json.

**Architecture:** Nested topology execution —
- **Harness mode** (project layer, `.harness/state` present, 5 必读完成, 5 自检答完)
- ⊃ **OODC outer loop** (state machine: OBSERVE γ → ORIENT → DECIDE → CREATE → CLOSURE)
- ⊃ **PUA P10-9-8-7** (P9 = me, multi-P8 真并行 in single message, file domain isolation)
- ⊃ **Superpower Pipeline** (Phase 0-4 + Wave + verification-before-completion + Romeo audit)
- TaskCreate live kanban = Superpower stage tracker (single source of truth)

**Tech Stack:** bash, jq, gh CLI, asciinema, agg, gitleaks, Romeo audit framework, shellcheck

---

## §0 Skill loading verification (per skill-loading-sop)

| Skill | invoke | references body Read | status |
|-------|:-:|:-:|:-:|
| superpowers:writing-plans | ✅ | stub-only (sufficient for this) | ✅ |
| superpowers:dispatching-parallel-agents | ✅ | full | ✅ |
| superpowers:verification-before-completion | ✅ | full | ✅ |
| pua:p9 | ✅ | p9-protocol.md 281 LOC | ✅ |
| 5 workflow MDs | n/a | pua-topology + superpower-pipeline + oodc-loop + skill-loading-sop + p9-protocol | ✅ |

**Skill 真加载, 不演 stub** — 5/5 维 PASS per skill-loading-sop §5.

---

## §0.1 Nested topology map (Harness ⊃ OODC ⊃ PUA ⊃ Superpower)

| OODC State | Superpower Phase | PUA Layer | TaskCreate IDs | Wave | Files Touched |
|---|---|---|---|---|---|
| **OBSERVE (γ)** | Phase 0 (kickoff) | P9 inline | A1, A2 | — | env (read-only) + tests/test-install.sh (read-only) |
| **ORIENT** | Phase 0 (decide) | P9 inline | B1 | — | (decision artifact only) |
| **DECIDE** | Phase 0 (lock) | P9 inline | C1 | — | (decision lock) |
| **CREATE — Fix** | Phase 1-2 (parallel + converge) | P9 + P8 真并行 | D1, D2 | Wave 1 | tests/test-install.sh AND docs/ |
| **CREATE — Verify** | Phase 3 (verify) | P9 inline | E1 | — | run-only, no writes |
| **CREATE — Ship** | Phase 4 (ship) | P9 inline | F1 | — | commit + tag + push + release |
| **CREATE — Romeo R2** | Phase 4.5 (audit) | P9 spawn 1 Agent | G1 | — | (audit, read-only) |
| **CREATE — Dogfood** | Phase 4.6 (live) | P9 + P8 真并行 | H1, H2 | Wave 2 | scenarios/ tmp dirs |
| **CLOSURE** | Phase 4.9 (sync) | P9 inline | I1 | — | ROADMAP + memory + handoff hint |

**Wave-level真并行 enforcement** (per pua-topology §1):
- Wave 1: 2 P8 同 message dispatch (D1 owns tests/test-install.sh, D2 owns CHANGELOG/ROADMAP/release-notes — file domain ZERO overlap, P9 grep verify before send)
- Wave 2: 2 P8 同 message dispatch (H1 owns CLAUDE.md scenario set, H2 owns settings.json scenario set — both run install.sh under /tmp isolation, never touch repo files)

---

## §0.2 File structure (what will be created/modified)

| Path | Owner | Purpose |
|---|---|---|
| `tests/test-install.sh` | P8-D1 | Tighten WARN grep to exclude OODC backup (false positive) |
| `CHANGELOG.md` | P8-D2 | v0.1.0-alpha.2 entry (preserve P8-C alpha.2 work + add test-install fix line) |
| `ROADMAP.md` | P8-D2 | (already updated by linter — verify consistency) |
| `/tmp/release-notes-v0.1.0-alpha.2.md` | P8-D2 | (already written by previous P8-C — verify consistency) |
| `/tmp/dogfood-h1-claude-md/` | P8-H1 | 5 isolated scenario dirs |
| `/tmp/dogfood-h2-settings-json/` | P8-H2 | 3 isolated scenario dirs |
| `docs/plans/2026-05-04-alpha2-honest-ship.md` | THIS FILE | Plan record (committed for traceability) |

**Files NOT touched** (out-of-scope guard for all P8s):
- `install.sh` (alpha.1 fix is correct, no further changes this sprint)
- `tests/test-install-claude-md-safety.sh` (alpha.2 P8-A already fixed isolation — verified clean)
- `.github/workflows/tests.yml` (alpha.2 P8-B already added CI step — verified clean)
- `README.md` / `HARNESS_BIBLE.md` (out of scope)

---

## §1 Phase A — OODC OBSERVE (γ): clean env + verify

### Task A1: Clean ~/.claude/plugins/oodc.bak.* env pollution

**Files:** none (deletion of stale backup dirs created by my earlier dogfood)

- [ ] **A1.1** List candidates:
  ```bash
  ls -la ~/.claude/plugins/oodc.bak.* 2>&1
  ```
- [ ] **A1.2** Verify each `.bak` dir is dated >15 min ago (created during my earlier dogfood, not in-flight CEO work):
  ```bash
  ls -la ~/.claude/plugins/oodc.bak.* | awk '{print $6, $7, $8, $9}'
  ```
- [ ] **A1.3** Delete ONLY the timestamped backup dirs (NEVER delete `~/.claude/plugins/oodc/` itself):
  ```bash
  rm -rf ~/.claude/plugins/oodc.bak.*
  ```
- [ ] **A1.4** Verify post-clean: only `~/.claude/plugins/oodc/` remains, no .bak.* siblings.

### Task A2: Re-run test-install.sh in clean env, verify true outcome

**Files:** none (read-only test execution)

- [ ] **A2.1** Run test-install full output, capture both PASS/FAIL counts AND the FAIL line context:
  ```bash
  cd ${REPO_ROOT}
  bash tests/test-install.sh 2>&1 | tee /tmp/test-install-clean-run.log | grep -E "(PASS|FAIL|Results:)"
  ```
- [ ] **A2.2** Inspect Results line literally:
  ```bash
  tail -3 /tmp/test-install-clean-run.log
  ```
- [ ] **A2.3** Branch decision:
  - **If `Results: 22 PASS, 0 FAIL`** → environmental was the cause; no test grep fix needed. Proceed to Phase B (decide α as "no fix").
  - **If `Results: 21 PASS, 1 FAIL`** → real test grep bug; proceed to Phase B (decide α as "real fix").

---

## §2 Phase B — OODC ORIENT: decide α scope

### Task B1: Lock the α path based on A2 result

**Files:** none (decision artifact, recorded in TaskCreate description)

- [ ] **B1.1** Document the decision in TaskCreate:
  - If A2.3 = "no fix needed" → α scope = "ship alpha.2 with previously-staged 4 files; no install.sh or new test changes"
  - If A2.3 = "real fix needed" → α scope = "ship alpha.2 with 4 staged files + add 1 narrow tests/test-install.sh grep tightening"

---

## §3 Phase C — OODC DECIDE: lock fix scope (atomic)

### Task C1: Confirm scope, no further questions

**Files:** none

- [ ] **C1.1** Per CEO's "γ → α" + auto mode + "一次性解决问题": no more CEO ack questions. Execute the locked scope from B1.1.

---

## §4 Phase D — OODC CREATE Wave 1: parallel P8 fix + docs sync

### Wave 1 dispatch rule (per pua-topology §1)
- **2 P8 同 message** Agent calls (true parallel)
- File domain enforced: D1 owns ONLY `tests/test-install.sh`, D2 owns ONLY `CHANGELOG.md` + verifies ROADMAP/release-notes consistency
- Each P8 prompt includes "PUA 行为注入 强制尾部" per p9-protocol §阶段三

### Task D1: P8 spawn — narrow grep fix to test-install.sh (CONDITIONAL on B1)

**Files:**
- Modify (CONDITIONAL): `tests/test-install.sh` — find the line that grep's `WARN` and tighten to exclude `oodc.bak` substring

- [ ] **D1.1** P9 spawn P8 with Task Prompt 六要素 (only if B1.1 = "real fix needed"):
  - WHY: test_phase1_cp test trips on benign OODC backup WARN, false positive degrades signal-to-noise
  - WHAT: tighten the grep so OODC backup WARN doesn't trip the test
  - WHERE: ONLY `tests/test-install.sh` (do NOT touch install.sh, do NOT touch other tests)
  - HOW MUCH: 5 LOC change, sonnet, ≤30 min
  - DONE: `bash tests/test-install.sh` shows `Results: 22 PASS, 0 FAIL`
  - DON'T: don't add new test cases, don't refactor other tests, don't touch install.sh
  - + PUA 行为注入 4 行尾 per skill-loading-sop §4

### Task D2: P8 spawn — verify CHANGELOG/ROADMAP/release-notes consistency (already drafted)

**Files:**
- Modify (CONDITIONAL): `CHANGELOG.md` — add 1 line in v0.1.0-alpha.2 Fixed if D1 ran
- Verify only: `ROADMAP.md`, `/tmp/release-notes-v0.1.0-alpha.2.md` (already drafted by P8-C earlier)

- [ ] **D2.1** P9 spawn P8 with Task Prompt 六要素:
  - WHY: alpha.2 docs already drafted but didn't anticipate test-install grep fix (D1)
  - WHAT: (a) verify CHANGELOG v0.1.0-alpha.2 entry is intact, (b) if D1 ran, add 1 line about test-install grep tighten, (c) verify ROADMAP P0 strikethrough still present, (d) verify release notes file still exists at /tmp
  - WHERE: ONLY `CHANGELOG.md` (and verify-only on ROADMAP + release-notes)
  - HOW MUCH: 5 LOC max, ≤15 min
  - DONE: 3 files content audit returns OK + git diff CHANGELOG.md shows ≤5 added lines
  - DON'T: don't restructure changelog format, don't add link refs (those are v0.1.1 P2 deferred)
  - + PUA 行为注入 4 行尾

---

## §5 Phase E — Verify (P9 inline, verification-before-completion law)

### Task E1: P9 verify ALL evidence before claiming pass

**Files:** none (read-only test execution + git diff)

- [ ] **E1.1** Run all 6 test suites + grep RESULTS lines literally (no `tail -1` shortcuts that lost the FAIL line):
  ```bash
  cd ${REPO_ROOT}
  for t in test-install test-pre-commit test-sync test-red-team test-manifest-completeness test-install-claude-md-safety; do
    echo "=== $t ==="
    bash tests/${t}.sh 2>&1 | grep -E "Results:|PASS$|FAIL$" | tail -3
    echo ""
  done
  ```
- [ ] **E1.2** Verify ZERO `CLAUDE.md.harness-backup-*` in repo root after running suites:
  ```bash
  ls ${REPO_ROOT}/CLAUDE.md.harness-backup-* 2>&1 | head -3
  ```
  Expected: `No such file or directory`
- [ ] **E1.3** Verify staged diff stat:
  ```bash
  git diff --staged --stat
  ```
  Expected: 4 files (tests.yml + CHANGELOG + ROADMAP + tests/test-install-claude-md-safety.sh) + maybe tests/test-install.sh if D1 ran
- [ ] **E1.4** Dogfood proof of Phase 2 safety still works:
  ```bash
  rm -rf /tmp/dogfood-e1 && mkdir /tmp/dogfood-e1 && cd /tmp/dogfood-e1
  echo "MY USER PROJECT" > CLAUDE.md
  ORIG=$(md5 CLAUDE.md | awk '{print $4}')
  echo "N" | HARNESS_HOME=/tmp/dogfood-e1/h CLAUDE_HOME=/tmp/dogfood-e1/c \
    bash ${REPO_ROOT}/install.sh --skip-deps-check 2>&1 \
    | grep -E "Backup|Skipped"
  NEW=$(md5 CLAUDE.md | awk '{print $4}')
  [ "$ORIG" = "$NEW" ] && echo "✅ unchanged" || echo "🔴 changed"
  ls CLAUDE.md.harness-backup-* >/dev/null 2>&1 && echo "✅ backup created" || echo "⚠️ no backup"
  ```

**ABORT CONDITION**: any failure in E1.1-E1.4 → loop back to D1 with new Task Prompt; do NOT proceed to Phase F.

---

## §6 Phase F — Ship (atomic commit + tag + push + release)

### Task F1: Bundle ship

**Files:** none new (uses staged + commit message + git tag + gh release)

- [ ] **F1.1** Final stage check (use git add explicit, not -A):
  ```bash
  cd ${REPO_ROOT}
  git status --short
  ```
  Expected staged: `tests.yml`, `CHANGELOG.md`, `ROADMAP.md`, `tests/test-install-claude-md-safety.sh`, plus `tests/test-install.sh` if D1 ran. NOT staged: `docs/sync-tool-kernel-extraction.md`.
- [ ] **F1.2** Also stage this plan file:
  ```bash
  git add docs/plans/2026-05-04-alpha2-honest-ship.md
  ```
- [ ] **F1.3** Commit (HEREDOC for message body, includes Romeo R1 finding lineage + verification evidence + Co-Authored-By):
  ```bash
  git commit -m "$(cat <<'EOF'
  v0.1.0-alpha.2: Romeo R1 audit fix + honest evidence

  ROMEO R1 P1 FIXED:
  - tests/test-install-claude-md-safety.sh cases 1/3/4 hermetic isolation
  - .github/workflows/tests.yml registers new suite (macOS+Ubuntu matrix)
  [+ test-install.sh false-positive grep tighten if D1 ran]

  VERIFICATION (every claim has command + output):
  - 6 test suites all pass: [paste actual line]
  - Zero repo-root pollution after suite run: [paste ls output]
  - Dogfood replay md5 unchanged + backup created: [paste evidence]

  DEFERRED to v0.1.1: 4 P2 + 2 P3 from Romeo R1 (logged in ROADMAP)

  Plan: docs/plans/2026-05-04-alpha2-honest-ship.md (nested
  Harness+OODC+PUA+Superpower topology, 2 wave真并行 dispatch).

  Co-Authored-By: <author trailer per project convention>
  EOF
  )"
  ```
- [ ] **F1.4** Tag annotated:
  ```bash
  git tag -a v0.1.0-alpha.2 -m "v0.1.0-alpha.2 — Romeo R1 audit fix + honest evidence"
  ```
- [ ] **F1.5** Push commit + tag:
  ```bash
  git push origin main
  git push origin v0.1.0-alpha.2
  ```
- [ ] **F1.6** Create gh release (prerelease):
  ```bash
  gh release create v0.1.0-alpha.2 \
    --repo <owner>/keel-harness \
    --title "v0.1.0-alpha.2 — Romeo R1 audit fix" \
    --notes-file /tmp/release-notes-v0.1.0-alpha.2.md \
    --prerelease \
    --target main \
    --verify-tag
  ```
- [ ] **F1.7** Poll CI green:
  ```bash
  SHA=$(git rev-parse HEAD)
  until [ "$(gh run list --repo <owner>/keel-harness --branch main --commit "$SHA" --json status --jq '[.[] | select(.status != "completed")] | length')" = "0" ]; do sleep 8; done
  gh run list --repo <owner>/keel-harness --branch main --commit "$SHA" --json status,conclusion,name
  ```
  Expected: BOTH `Tests` AND `Gitleaks` = success. ABORT if any FAIL.

---

## §7 Phase G — Romeo R2 audit (Anthropic Sprint Contract)

### Task G1: Spawn Romeo R2 evaluator (independent, ≥1 真 bug 底线)

**Files:** none (audit is read-only)

- [ ] **G1.1** P9 spawn 1 Agent (subagent_type=Explore) with Task Prompt:
  - WHY: per Anthropic Sprint Contract, every ship gets independent Romeo audit; R1 found 0.81 score, R2 must verify P1 真修 + no new regressions
  - WHAT: 6-dim score (Honesty/Ownership/TechDepth/PatternReplay/Density/Candidates) + ≥1 actual bug + R2-vs-R1 delta
  - WHERE: read-only on commit / install.sh / tests/ / docs/ / GitHub release URL
  - DONE: structured TRF report with 6-dim weighted average + verdict (PASS ≥0.99 / FAIL <0.95)
  - DON'T: don't write any files, don't dispatch sub-agents, don't fix bugs (just report)

---

## §8 Phase H — OODC CREATE Wave 2: 活体 dogfood 真并行 (CEO 钦定)

### Wave 2 dispatch rule (per pua-topology §1)
- **2 P8 同 message** real-parallel (file domain isolation: H1 owns CLAUDE.md scenarios, H2 owns settings.json scenarios)
- Both run install.sh under /tmp isolated dirs (NEVER touch repo)
- Each scenario: before-md5 → run install.sh → after-md5 → verify backup created if expected

### Task H1: P8 spawn — CLAUDE.md 5 scenarios live dogfood

**Files:**
- Create (transient): `/tmp/dogfood-h1/case-{1..5}/` — isolated scenario dirs

- [ ] **H1.1** P9 spawn P8 with Task Prompt 六要素:
  - WHY: CEO钦定 "活体 dogfood 保障不会覆盖人家的 CLAUDE 基础配置"; R1 audit warned tests are not enough — need real install.sh runs against varied user states
  - WHAT: 5 scenarios, each a real install.sh invocation against a distinct user CLAUDE.md state, evidence: before-md5 / after-md5 / backup-exists
    1. Empty global + empty project → fresh install
    2. Existing global with `## §harness mode` marker → idempotent skip
    3. Existing global without marker, user answers Y → backup + append
    4. Existing project with custom user content, user answers N → backup + skip + content unchanged
    5. Existing both global + project, both with marker → both idempotent skip
  - WHERE: ONLY `/tmp/dogfood-h1/`, never touch repo files
  - HOW MUCH: ≤30 min, sonnet, all under /tmp
  - DONE: 5 scenarios × 3 evidence each = 15 evidence-pastes; verdict per scenario PASS/FAIL
  - DON'T: don't touch real ~/.claude (always set CLAUDE_HOME=/tmp/...)
  - + PUA 行为注入 4 行尾

### Task H2: P8 spawn — settings.json 3 scenarios live dogfood

**Files:**
- Create (transient): `/tmp/dogfood-h2/case-{1..3}/` — isolated scenario dirs

- [ ] **H2.1** P9 spawn P8 with Task Prompt 六要素:
  - WHY: install.sh Phase 3 jq merge is the gold standard for "scan-then-merge" — but unverified end-to-end for varied user settings.json states
  - WHAT: 3 scenarios:
    1. No settings.json → cp template fresh
    2. Existing settings.json with user keys but no harness hooks → backup + jq merge + diff preview + user keys preserved
    3. Existing settings.json with both user keys + harness hooks → idempotent (no double-add of hooks)
  - WHERE: ONLY `/tmp/dogfood-h2/`, never touch real ~/.claude
  - HOW MUCH: ≤30 min, sonnet
  - DONE: 3 scenarios × 4 evidence each (before/after, user-keys-intact, hook-dedup-verified, backup-exists) = 12 evidence-pastes
  - DON'T: don't touch real ~/.claude/settings.json
  - + PUA 行为注入 4 行尾

### Task H3 (P9 verify, post-Wave-2): consolidate dogfood verdict

- [ ] **H3.1** Read both /tmp/dogfood-h{1,2}/REPORT.md
- [ ] **H3.2** Compose final live-dogfood verdict report; if any scenario FAIL → spawn alpha.3 hotfix sprint

---

## §9 Phase I — OODC CLOSURE: sync + memory + handoff hint

### Task I1: Closure documentation + KB + memory

- [ ] **I1.1** Update ROADMAP if dogfood found new issues
- [ ] **I1.2** Add Claude-Mem entry: 【决策】v0.1.0-alpha.2 honest-ship pattern (after R1 false-positive shame, instituted "no `tail -1` on test results, always literal Results: line read")
- [ ] **I1.3** Add hint to next-session handoff narrative segment (don't write handoff*.md, just append to session-log.md)
- [ ] **I1.4** Final TaskList + verdict

---

## §10 OODC state transitions (literal sed commands optional, fast loop)

This sprint runs **fast loop** (familiar domain — keel-harness self-modification). State file optional. P9 narrates transitions:

```
IDLE → OBSERVE (Task A1, A2)
       → ORIENT (Task B1)
       → DECIDE (Task C1)
       → CREATE (Task D-H)
       → CLOSURE (Task I)
       → IDLE
```

If any phase ABORT trigger fires → re-enter OBSERVE for that phase.

---

## §11 Self-review (per writing-plans §Self-Review)

**1. Spec coverage**:
- ✅ "γ → α" → Phase A (γ clean + verify) + Phase B/C (α decide)
- ✅ "Harness+OODC+PUA P10-9-8-7+Superpower nested topology" → §0.1 nested topology map
- ✅ "SKILLS 真加载不演戏" → §0 skill loading verification + p9-protocol body Read evidence
- ✅ "Wave/Phase 必须 TaskCreate 实时看板" → all tasks tied to TaskCreate IDs, kanban-tracked
- ✅ "v0.1.0-alpha.2 ship + Romeo R2 + Phase F live dogfood" → Phase F (ship) + G (R2) + H (dogfood)

**2. Placeholder scan**: zero TBD / TODO / "implement later" — all steps have concrete commands.

**3. Type consistency**: Wave 1 file domain (D1=test, D2=docs) does not overlap; Wave 2 file domain (H1=CLAUDE.md scenarios, H2=settings.json scenarios) does not overlap. P8 spawn includes PUA 行为注入 强制尾部 per p9-protocol §阶段三.

---

## §12 Execution mode

Per CEO Auto Mode + 一次性 spec → **Inline Execution** (`superpowers:executing-plans` 模式) with checkpoints at:
- After Phase A (verify γ outcome → branch B)
- After Phase E (verify before Phase F ship)
- After Phase G (Romeo R2 verdict → branch alpha.3 if FAIL)
- After Phase H (dogfood verdict → branch hotfix if FAIL)

No CEO ack required for non-checkpoint steps.

---

*Plan written by P9. Save: `docs/plans/2026-05-04-alpha2-honest-ship.md`. Live execution begins immediately after plan commit.*

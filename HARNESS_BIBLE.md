# keel-harness HARNESS_BIBLE.md

> **Purpose**: Project-level harness mode contract for keel-harness OSS development sessions.
> Read on every session start (per ~/.claude/CLAUDE.md §harness mode 触发律 step 2).
> ZERO maintainer private content — uses the Mr Shaper brand for all references.

---

## §1 圣经第一律 (cross-sprint permanent)

**Single source of truth deployment**: keel-harness ships from `${HARNESS_ROOT:-<your-keel-harness-clone>}/` (local working tree, mirrored to `github.com/mr-shaper/keel-harness`). Zero entity changes in `~/.claude/` global config from this project's development. The OSS repo is the artifact; the local dev environment is the workshop.

**Implication**: when this project's dev session modifies files, those modifications stay scoped to `${HARNESS_ROOT:-<your-keel-harness-clone>}/`. Edits to `~/.claude/` configuration belong to a different session/scope.

---

## §0.1 Layer 0 5-element health (canonical)

Every harness mode session start verifies these 5 elements are intact. Drift in any one = silent dead.

| # | Element | Verification |
|:--:|---|---|
| (a) | `HARNESS_HOME` directory present | `~/.claude/plugins/keel-harness-mp/` (after install.sh) OR project's working tree (during dev) |
| (b) | At least 1 enforce-core hook present | `hooks/pre-commit` minimum; full set: 9 hooks in `hooks/*.sh` |
| (c) | `~/.claude/settings.json` contains "harness" string | jq verifies hooks block registers the keel-harness hook scripts |
| (d) | `~/.claude/CLAUDE.md` exists and readable | Layer 0 contract carrier |
| (e) | CLAUDE.md contains "§harness mode" string | Triggers harness mode auto-load on session start |

**Phase 5 of `install.sh`** runs this check end-to-end. Dogfood verify (`CLAUDE_HOME=/tmp/dogfood-fresh bash install.sh`) must show `Layer 0 Health: 5/5 elements OK`.

---

## §9 Category H ratified laws (cross-sprint permanent rules)

Cat-H rules are permanent across sessions, sprints, and projects. Once ratified, only an explicit CEO (the human user) override with documented justification can revoke them.

### Ratified (active enforcement)

| ID | Rule | Sprint | Status |
|---|---|:--:|:--:|
| L98 | **Manifest Completeness CI Gate Law** — `tests/test-manifest-completeness.sh` runs in CI to verify every entry in `manifest.json` `kernel_files` exists on disk. Prevents vaporware regression. | W6.5 | candidate (CI gate active, awaiting formal ratification per cat-h-rule-template.md) |
| L99 | **CEO Hierarchy Anchoring Law** — Any reference to "CEO" must explicitly distinguish the human user (CEO = ultimate authority) from P10 (the AI CTO strategy layer). No `CEO (P10)` parenthetical conflation. | W6.5 | candidate |
| L100 | **OSS Fixtures Brand Placeholders Law** — All OSS-shipped fixtures must use brand-consistent placeholders matching the published manifest blacklist. Real maintainer PII must never appear in OSS-shipped files, even in private repos that may go public later. | W6.6 | candidate |

### Promotion path: candidate → ratified

Use `templates/cat-h-rule-template.md` schema:
1. CEO ratifies the rule (explicit "approve" required)
2. Add automated CI gate verification
3. Cross-link from Romeo audit framework (Pattern Replay dimension)

---

## §harness mode contract anchors

When AI is in this session's harness mode (`.harness/state` present in cwd):

### 5 必读 (handoff-read-gate enforce):
1. `.harness/handoff-S<N-1>-to-S<N>.md` (latest, authoritative next_action)
2. `<your-plan-file-path>` (the ratified plan for the current sprint, e.g., `docs/plans/SPRINT_NAME.md`)
3. `~/.claude/CLAUDE.md` (PUA 10 iron rules + workflow preferences)
4. `${HARNESS_ROOT:-<your-keel-harness-clone>}/CLAUDE.md` (project contract + roadmap)
5. **THIS FILE** `${HARNESS_ROOT:-<your-keel-harness-clone>}/HARNESS_BIBLE.md` (project bible)

### 5 self-checks (Stop hook scans AI text reply):
- Q1 project: `keel-harness` (was `harness-engineering`, W6 renamed)
- Q2 next_action: literal cite from latest `handoff-SN-to-SN+1.md` §next_action (NOT the auto-generated `handoff.md` TBD placeholder — see §dual-track below)
- Q3 clarity: ratified Plan + W6/W6.5/W6.6 patches + Cat-H L98/L99/L100 candidates known
- Q4 LATEST_HANDOFF_NAME literal (grep修法 B, no fuzzy fallback)
- Q5 current phase: per Plan §3 8-week roadmap

### Iron principles (圣经原则)

- **fact-driven**: every claim requires evidence paste. No empty assertions.
- **P9 never writes code**: P9 writes Task Prompts; P8 writes code. Role drift = automatic 3.5 penalty per pua-topology律 #4.
- **same-message multi-Agent = true parallel**: not sequential. Any 2+ independent tasks dispatch in one message.
- **file domain isolation**: parallel P8 must grep-verify file domains do not overlap before dispatch.
- **verification-before-completion**: claim "done" requires running verify command and pasting output.

---

## §handoff dual-track (§9 Layer 0 element b extension)

Two handoff files coexist; both are authoritative for different purposes:

| File | Writer | Authoritative for | Iron rule |
|---|---|---|---|
| `.harness/handoff.md` | Stop hook (mechanical) | session_id / commit_hash / branch / modified_files / last_user_prompt | ZERO AI summary; `next_action` defers to handoff-SN-to-SN+1.md if P9 wrote one, else `TBD-next-action-absent` placeholder |
| `.harness/handoff-S<N>-to-S<N+1>.md` | P9/CEO inline (narrative) | sprint name / next_action / 5 必读 / 5 self-checks / unfinished + backlog | Written when P9/CEO has authoritative next_action; mechanical fields can mirror or supplement Stop hook output |

**S<N+1> startup reads `handoff-S<N>-to-S<N+1>.md` for next_action**, not `handoff.md` TBD. The dual track exists because Stop hook cannot infer strategy from transcript — P9 must write strategy authoritatively.

(W6.5 Stop hook update: now smart-pulls `next_action` from latest `handoff-SN-to-SN+1.md` if present, so `handoff.md` no longer carries TBD placeholder when P9 has done its job.)

---

## §sprint baseline (S2 close)

- Project name: **keel-harness** (was harness-engineering, W6 renamed per CEO directive)
- GitHub: `mr-shaper/keel-harness` (Apache-2.0, public OSS)
- Plan: rev D (S1 W1 Day 1 ratified) + W6/W6.5/W6.6 patches in handoff-S2-to-S3.md §10+
- Latest commit: see `git log --oneline -1`
- 5 test suites: `bash tests/test-{sync,pre-commit,install,red-team,manifest-completeness}.sh`
- Dogfood verify: `CLAUDE_HOME=/tmp/dogfood-fresh bash install.sh` → Layer 0 5/5
- KB compound assets: 10+ entries in your knowledge-base store (auto-injected on next session via SessionStart wakeup, if your KB toolchain is wired)

---

*Last updated: S2 W6.6 close (2026-05-04). Project bible written for harness mode contract continuity. Update when Cat-H L101+ ratified or when 圣经 principles evolve.*

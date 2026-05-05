# keel-harness ROADMAP

> Where this project is going after `v0.1.0-alpha`. Plain-language priorities,
> rough version targets, and known unfinished work that anchored sprint S4's
> audit cycle. Versions are aspirational; reality is a function of community
> interest and maintainer bandwidth.

---

## v0.1.1 — Post-flip patches (next 1-2 weeks)

The S4 audit cycle (Privacy / Bug / PublicReady / Doc-Writer) closed all P0
and P1 findings before the public flip. The audit also surfaced a handful
of P2 (cosmetic / consistency) items that were intentionally deferred. They
land here.

- ~~🔴 **[LAUNCH BLOCKER — P0 user-safety] `install.sh` Phase 2b silently
  overwrites the user's `$PWD/CLAUDE.md`.** Lines 371-373 do `cp
  templates/CLAUDE.md.project.template $PWD/CLAUDE.md` with no
  backup, no skip-if-exists, no interactive prompt. Any user who runs the
  one-liner `curl ... | bash` while `cd`'d in their existing project
  directory loses their project CLAUDE.md without warning. Reproduction:
  `mkdir /tmp/x && cd /tmp/x && echo "MY NOTES" > CLAUDE.md && bash
  /path/to/install.sh --dry-run --skip-deps-check` → dry-run output ends
  with `would: cp templates/CLAUDE.md.project.template → /tmp/x/CLAUDE.md`
  with zero overwrite warning. Fix: mirror Phase 2a's pattern (detect
  existing → backup `.harness-backup-<ts>` → interactive prompt with diff
  preview → cp only on Y). Must ship before any public launch posting.~~
  → ✅ **Fixed in v0.1.0-alpha.1**, see [release notes](https://github.com/mr-shaper/keel-harness/releases/tag/v0.1.0-alpha.1) and [CHANGELOG](CHANGELOG.md#v010-alpha1)

- 🔴 **[LAUNCH-READINESS related] `install.sh` Phase 1 also silently
  overwrites `${HARNESS_HOME}/*` if user already had files there.**
  Lower severity than 2b because `~/.claude/plugins/keel-harness-mp/` is
  the harness's own plugin directory — but still: if the user manually
  customized any kernel file (e.g., a hook script), re-running install
  loses that change. Fix: add an integrity hash check that warns when an
  installed kernel file's hash differs from the template's hash, and
  prompts before overwriting.

- **[Romeo R1 P2] OODC backup TOCTOU.** `install.sh` lines 284-285: `$(date +%s)`
  evaluated separately in the `warn` message vs the `mv` path. On slow systems or under
  I/O pressure the timestamps can differ by 1 second, leaving the warn message pointing
  to a path that doesn't exist. Fix: assign `oodc_ts="$(date +%s)"` once and reuse.

- **[Romeo R1 P2] Phase 5 health check sentinel weaker than Phase 2.** `install.sh`
  line ~636: Phase 5 grep checks `"harness mode"` while the Phase 2 idempotency check
  uses `"## §harness mode"`. A `CLAUDE.md` containing the substring elsewhere (e.g., in
  a trigger-condition comment) makes Phase 5 falsely report PASS. Fix: align both checks
  to `"## §harness mode"`.

- **[Romeo R1 P2] CHANGELOG link references missing.** `CHANGELOG.md` uses
  Keep-a-Changelog headings like `## [0.1.0-alpha.1]` but previously lacked the
  corresponding `[0.1.0-alpha.1]: <url>` definitions at file bottom. Fixed partially in
  `v0.1.0-alpha.2` (alpha.2 and alpha.1 refs added); full audit of all bracketed
  headings and the `[Unreleased]` compare URL should be verified and locked down.

- **[Romeo R1 P2] Release notes case description mismatch.** The GitHub release body
  for `v0.1.0-alpha.1` claims a "re-run after partial install" test case that does not
  exist in the shipped suite. Fix: edit the GitHub release body to remove the fictitious
  case and replace it with an accurate enumeration of the 6 real cases.

- **[Romeo R1 P3] Sentinel rename fragility.** `install.sh` uses the plain string
  `## §harness mode` as the idempotency gate. Any future header rename (e.g., to
  `## §keel-harness mode` in a brand sweep) silently breaks idempotency, causing
  repeated section appends on re-install. Fix: add a machine-readable comment marker
  (e.g., `<!-- harness-section:v1 -->`) on a dedicated line, or centralize the sentinel
  as a named constant.

- **[Romeo R1 P3] CI registration discipline gate.** New test files added without a
  corresponding `tests.yml` step are silent no-ops — as demonstrated by the alpha.1
  test suite omission caught in Romeo R1. Fix: add a CI step that asserts every
  `tests/test-*.sh` has a matching `Run` step in `tests.yml`, so the gap cannot recur.

- **Stale file counts in install.sh, tests/test-install.sh, README.md.**
  Several places hardcode `29 kernel_files` or `23 kernel files` or
  `8 enforce-core hooks (~80 LOC)`. The actual numbers are 50, 50, and
  9 hooks at ~125 LOC. None of these break function (the install reads the
  list from `manifest.json` dynamically), but they confuse readers.
  Fix: replace literals with computed counts where feasible.

- **HARNESS_BIBLE.md residual `~/dev/harness-engineering/` paths.** Four
  lines still reference the maintainer's local working tree path. The path
  is benign (not a credential), but it's an inconsistency vs the W6.6 brand
  sweep intent. Fix: parameterize as `<your-harness-clone>` or
  `${HARNESS_ROOT}`.

- **`compound-selfcheck-plugin/` plugin metadata.** Currently has only
  `hooks/` + `README.md` + `.claude-plugin/plugin.json`. The OODC plugin
  ships with richer metadata; harmonize for consistency.

- **`manifest.json` top-level `license` field.** Add an explicit
  `"license": "Apache-2.0"` for machine-readable license scanners.

- **`.github/dependabot.yml` for GitHub Actions.** Auto-PR security patches
  for `actions/checkout@v4` and similar. One file, low effort, real value.

- **Branch protection on `main` (post-flip).** Once public, free-tier branch
  protection unlocks: require status checks (`tests.yml` + `gitleaks.yml`)
  to pass, require 1 review for external PRs.

- **Version-pinned install URL in README.** Document
  `curl -fsSL .../releases/download/v0.1.0-alpha/install.sh | bash` as the
  stable install path alongside the rolling `main` URL.

---

## v0.2 — Compound Engineering deeper (1-3 months)

The current `compound-selfcheck` plugin is a *reminder* hook: it detects
large changes and suggests ingestion into a knowledge base. It does not
*do* the ingestion. The compound flywheel only spins if the next step
actually happens — and right now it requires a human to decide.

### v0.2 goal

Move from *reminder* to *partial automation* — keep the human in the loop
on judgment, but eliminate the friction of repeatedly running the same
ingestion command.

### Concrete additions

- **`scripts/compound-ingest.sh`.** Generic CLI that takes a file + a
  domain tag and emits a structured snapshot to a configurable knowledge
  base location (file-system, sqlite, or a user-defined hook). The hook
  can call this directly when a `.claude/.compound-auto` flag is present.

- **`docs/compound-engineering-pattern.md`.** A standalone explainer of
  the three iron laws and how to recognize when a change is a compound
  asset vs a one-shot artifact. Content lives in commit messages and
  the plugin's stderr banner today; collecting it makes it citable.

- **Hook-trace audit dashboard (offline).** A small `scripts/compound-stats.sh`
  that reads `.harness/hook-trace.log`, counts `[COMPOUND-CHECK]` entries
  vs total writes, and reports the ingestion-trigger ratio. Helps answer
  "is the compound discipline actually happening, or am I performing it?"

### Why not ship this in `v0.1.0-alpha`

These features assume a working KB store. The OSS audience may use
markdown directories, Obsidian, Notion, or nothing at all. Designing the
plugin so it works for *any* KB store requires a configuration surface that
deserves its own design pass — not a rushed addition before launch.

---

## v0.3 — Generic KB store interface (3-6 months)

The internal `tacit-kb` reference in `workflows/kb-ingestion-sop.md` points
to a private Python implementation. For the OSS kernel to be self-sufficient,
it needs a *generic* interface — something a user can either implement
against, or ignore entirely without breaking the rest of the harness.

### v0.3 goal

Define a minimal "KB store" contract (a tiny Bash + JSON surface) that the
kernel calls when it wants to ingest. Ship one reference adapter (probably
markdown-on-disk). Document how to write your own adapter (Notion, Obsidian,
internal wiki, etc.).

### Concrete additions

- **`docs/kb-store-spec.md`.** A 100-line contract: what fields a KB store
  must accept, what it returns, what failure modes it handles.

- **`plugins/kb-fs-adapter/`.** Bundled adapter that writes structured
  markdown into a configurable directory. Uses no external dependencies.

- **`scripts/kb-query.sh`.** Generic search command that delegates to the
  active adapter. Replaces hardcoded `kb.py query` references.

- **Migrate `workflows/kb-ingestion-sop.md`** to reference the spec rather
  than the private implementation. The current text is correct in spirit
  but unactionable for OSS users.

---

## v0.4 — OODC loop completeness (6-12 months)

The OODC loop (Observe → Orient → Decide → Create → Closure) is documented
in `workflows/oodc-superpower-harness-orchestration.md` and bundled as a
skill in `plugins/oodc/`. The loop has unfinished edges that S4's audits
flagged or that prior sprints knew about and deferred. They land here.

### Observe phase

The current Observe step asks for `source_count: ≥3 (fast) / ≥20 (slow)`
across `github`, `x`, `nlm`, `local`, etc. The fast loop works fine for
familiar domains. The slow loop assumes the maintainer has a private
multi-source research tool ("argus-style") — that tool is not OSS.

What v0.4 ships:

- A **lightweight Observe protocol** that uses only widely-available tools:
  `gh search` for GitHub, public web search via `WebFetch`, and the
  user's own local files. No proprietary integrations.
- A reference example plan that walks through Observe for a typical OSS
  feature design (e.g., "should we add a CONTRIBUTING.md?").

### Orient phase

Currently relies on `Skill tool` invocations for "experts" (perspectives).
The bundled OODC plugin lists perspective names but the actual perspective
skills are private. OSS users without those skills hit a fallback path
that is not well exercised.

What v0.4 ships:

- A **generic expert framework**: any markdown file in a configurable
  `experts/` directory with a `name:` and a 1-paragraph viewpoint becomes
  an "expert" the Orient phase can cite. No skill plugin required.
- 3-5 sample experts as reference (Karpathy-style engineering rigor,
  Naval-style leverage thinking, Taleb-style risk aversion — all derived
  from public writings, with attribution).

### Decide phase

`references/decide-template.md` already contains the 5-elements +
DP-1..N pattern. What's missing is concrete OSS examples. v0.4 ships
2-3 worked examples of Decide-phase output for real harness sprints
(documented retroactively from S2-S4).

### Create phase

The shipped pieces here are TDD, code-reviewer, verification-before-completion,
and the Romeo audit framework. The audit cycle in S3-S4 itself is the
worked example. v0.4 ships a **Romeo audit pre-push hook** (currently a
[CANDIDATE] in CHANGELOG): the gate runs Romeo automatically on the diff
before allowing `git push`. Catches sprint-outcome regressions before
they hit the remote.

### Closure phase

Currently ends with "doc-sync + KB + Mem completed". The KB part is
addressed in v0.3. The Mem part references a private memory system. v0.4
ships a **generic memory hook**: a configurable post-closure command that
writes a JSON record of what was decided. Users can pipe it into anything.

### State machine enforcement

`workflows/oodc-loop.md` defines a state file (`~/.claude/.oodc-state-{project}`)
and a hook (`oodc-guard.sh`) that blocks Write/Edit/NotebookEdit when the
state demands it. The hook is described but not bundled. v0.4 ships it as
a real plugin.

---

## v0.5+ — Community-driven (12+ months)

Once the kernel is feature-complete on the Compound + KB + OODC axes, the
direction is community-driven. Open priorities (no commitments):

- **Windows / WSL2 first-class support.** Today: untested, community
  welcome. Tomorrow: tested in CI matrix.
- **VS Code / Zed / Cursor integration.** Adapters for editor-side hooks
  beyond pure Claude Code.
- **Multi-model agent support.** The current topology assumes Claude Code.
  The conceptual layer (Harness + OODC + role topology + Pipeline) is
  model-agnostic; the hooks are not. Adapter framework for other agent
  runtimes.
- **Telemetry-free metrics.** A way for users to self-report "harness
  caught X bugs in my last sprint" without sending data anywhere.

---

## What S4's audits explicitly deferred to this roadmap

These are the items the multi-perspective audit (S3.5 + S4) identified
that did *not* block the public flip and are tracked here so they don't
get forgotten:

| Item | Source | Lands in |
|------|--------|----------|
| Compound-selfcheck Edit-tool LOC measurement edge cases | Audit-C | v0.2 |
| Plan-quality-gate self-score gameability | Audit-C | v0.4 (Romeo pre-push) |
| `pre-commit` Python subprocess injection via filename | Audit-A | v0.1.1 |
| Context filter over-broad (line-level removal) | Audit-A | v0.1.1 |
| No `commit-msg` hook scanning blacklist in titles | Audit-A | v0.1.1 |
| Binary file blacklist scan silently false-negative | Audit-A | v0.1.1 |
| `templates/` blanket SKIP_PATHS | Audit-A | v0.1.1 |
| `_harness_hooks_count` hardcoded integer | Audit-B | v0.1.1 |
| OODC backup TOCTOU (`date +%s` double-eval) | Romeo R1 P2 | v0.1.1 |
| Phase 5 health check sentinel weaker than Phase 2 | Romeo R1 P2 | v0.1.1 |
| CHANGELOG link references missing | Romeo R1 P2 | v0.1.1 |
| Release notes fictitious case description | Romeo R1 P2 | v0.1.1 |
| Sentinel rename fragility (idempotency gate) | Romeo R1 P3 | v0.1.1 |
| CI registration discipline gate | Romeo R1 P3 | v0.1.1 |
| OODC slow-loop multi-source research is private | inherent | v0.4 |
| OODC orient experts depend on private skills | inherent | v0.4 |
| OODC state machine hook not bundled | `oodc-loop.md` | v0.4 |

---

## How to influence this roadmap

- **Open an Issue** for bugs or specific suggestions on a listed item.
- **Open a Discussion** for direction changes or "should we add X" before
  it becomes an Issue.
- **Open a PR** for v0.1.1 items if you have time — most are doc fixes.
- **Sponsor a sprint** (informal, no money) by saying "I'd use harness
  if v0.X shipped tomorrow" — it helps prioritization.

This roadmap is a living document. Last updated: S4 close, 2026-05-04.

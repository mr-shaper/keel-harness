# harness-engineering

> Harness for Claude Code: 24h cross-session continuity + canonical honesty enforcement + P10-9-8-7 nested parallel agent topology — Karpathy's agentic engineering, made enforceable.

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](https://github.com/mrshaper/harness-engineering/actions)
[![Version](https://img.shields.io/badge/version-v0.1.0--alpha-orange)](https://github.com/mrshaper/harness-engineering/releases)

![5 vocab + 4 gaps demo](demo/demo-4.gif)

> *90 seconds to grok harness. The 4 gaps it fills + the 5 words we want in the agentic engineering vocabulary. Reproduce with `bash demo/record.sh 4`.*

---

## 30-Second Elevator Pitch

Stop your AI from getting dumber over a 24h session. harness-engineering is the infrastructure
layer that makes Karpathy's agentic engineering enforceable in Claude Code — through immutable
handoffs, Romeo 6-dim audit, canonical honesty hooks, and P10-9-8-7 nested parallel agent
topology. Apache-2.0. macOS + Linux.

---

## The 4 Gaps It Fills

Most teams hit these walls within weeks of using Claude Code for serious engineering:

- **Gap 1 — 24h session memory loss**: Every new session, the AI forgets what it decided last
  sprint. harness fixes this with an immutable 7-field handoff schema — written at session stop,
  read at session start, enforced by hooks. Zero context drift.

- **Gap 2 — Paper victory (Romeo audit blind spots)**: AI claims "done" when hooks are registered
  but never fire. The Romeo 6-dimensional audit framework (Honesty / Ownership / TechDepth /
  PatternReplay / Density / Candidates) enforces a hardcore ≥0.99 bar across 6 independent
  dimensions — not a single-axis pass/fail.

- **Gap 3 — P9 role drift**: Your tech lead AI starts writing code instead of writing prompts.
  The P10-9-8-7 topology with 8 iron rules hard-separates strategy (P10), task-prompt writing
  (P9), implementation (P8), and sub-tasks (P7) — and enforces it via pre-tool hooks that block
  role violations before they happen.

- **Gap 4 — Silent dead hooks**: Hooks appear registered in settings.json but never trigger
  because the Layer 0 contract (CLAUDE.md + settings.json) is incomplete or inconsistent. harness
  ships a Layer 0 enforcement spec — 5 elements that must all be present or the system silently
  dies — plus templates you can fill in and ship.

---

## Quickstart (5 min)

> **Note**: `install.sh` ships in W3 (see roadmap). The one-liner below will work when W3 lands.

```bash
curl -fsSL https://raw.githubusercontent.com/mrshaper/harness-engineering/main/install.sh | bash
```

Until then, manual bootstrap:

```bash
# Step 1: Clone the kernel
git clone https://github.com/mrshaper/harness-engineering.git ~/.claude/plugins/harness-engineering-mp

# Step 2: Apply Layer 0 contract templates
cp ~/.claude/plugins/harness-engineering-mp/templates/CLAUDE.md.global.template ~/.claude/CLAUDE.md
# Edit ~/.claude/CLAUDE.md — fill in the <PLACEHOLDER> fields for your context

# Step 3: Merge hooks into settings.json (requires jq)
jq -s '.[0] * .[1]' \
  ~/.claude/settings.json \
  ~/.claude/plugins/harness-engineering-mp/templates/settings.json.template \
  > /tmp/settings-merged.json && mv /tmp/settings-merged.json ~/.claude/settings.json
# Restart Claude Code — harness hooks are now active
```

After install, start your first harnessed session:

```
1. Read .harness/handoff-S<N-1>-to-S<N>.md   — previous session's authoritative next_action
2. Answer 5 self-checks (Q1 project / Q2 next_action / Q3 clarity / Q4 handoff name / Q5 week)
3. Work — Stop hook writes the next handoff automatically
```

---

## What's Inside (Kernel Scope)

The kernel is the minimum viable harness — no private configuration, no personal plugins,
no company-specific logic. Everything that ships is universally applicable to any Claude Code
power user.

### Workflow Documentation (5 files)

| File | What it encodes |
|---|---|
| `workflows/pua-topology.md` | P10-9-8-7 nested parallel topology + 8 iron rules |
| `workflows/oodc-superpower-harness-orchestration.md` | OODC loop (Observe → Orient → Decide → Create) orchestration across Harness + Superpower + PUA layers |
| `workflows/superpower-pipeline.md` | Phase 0-4 engineering pipeline (kickoff → parallel explore → decision convergence → dev → close) |
| `workflows/skill-loading-sop.md` | Skill discovery + loading SOP — prevents hallucinated tool calls |
| `workflows/kb-ingestion-sop.md` | Knowledge base ingestion pipeline — Compound Engineering, not one-shot generation |

### Hooks (8 enforce-core hooks)

| Hook | Type | What it enforces |
|---|---|---|
| `stop-handoff-writer.sh` | Stop | Writes 7-field handoff at every session end |
| `pre-tool-handoff-read-gate.sh` | PreToolUse | Blocks file writes until handoff is read (sticky flag) |
| `pre-tool-handoff-semantic-gate.sh` | PreToolUse | Semantic check — prevents writing wrong session's handoff |
| `user-prompt-l42-workflow-trigger-gate.sh` | UserPromptSubmit | Routes trigger words (harness/OODC/PUA/Superpower) to the correct workflow MD |
| `pre-tool-doc-sync-sop-enforce.sh` | PreToolUse | Enforces doc-sync routing before any knowledge base write |
| `post-tool-chmod-ci-gate.sh` | PostToolUse | chmod guard — prevents CI scripts from losing execute bit silently |
| `session-start-layer0-health.sh` | SessionStart | Layer 0 health check — verifies all 5 contract elements are present |
| `pre-tool-plan-quality-gate.sh` | PreToolUse | Blocks low-quality plan writes (Romeo ≥0.99 gate) |

### Templates

- `templates/handoff-template.md` — 7-field handoff schema (sprint / next_action / blockers / decisions / files_changed / self_check / romeo_score)
- `templates/cat-h-律-template.md` — Category H canonical law template (for adding new ratified rules)
- `templates/CLAUDE.md.global.template` — Generic global Claude Code contract (~180 LOC, scrubbed of personal config)
- `templates/CLAUDE.md.project.template` — Generic project contract (~50 LOC, 5-must-reads + 5-self-checks + bible principles placeholder)
- `templates/settings.json.template` — Generic settings.json with 8 enforce-core hooks registered (~80 LOC)

### Audit Framework

- `audit/romeo-6-dim-framework.md` — Romeo 6-dimensional audit spec (Honesty / Ownership / TechDepth / PatternReplay / Density / Candidates), ≥0.99 hardcore gate, evidence-alignment rules

### Tooling

- `sync.sh` — 5-command sync (init / export / import / diff / release) with 5-layer privacy protection
- `manifest.json` — Kernel file whitelist + private blacklist keywords (what stays in, what never ships)
- `install.sh` — One-line bootstrap (ships W3)
- `LICENSE` — Apache-2.0

---

## Demos (asciinema → agg-rendered GIFs)

Three additional reproducible demos cover the gaps in motion:

| # | Demo | Length | Gap |
|---|---|---|---|
| 1 | [24h Cross-Session Continuity](demo/demo-1.gif) | 3 min | Gap 1 — AI memory loss |
| 2 | [4-Layer Nested Parallel — 7 P8 → 7× speedup](demo/demo-2.gif) | 2 min | Gap 3 — P9 role drift |
| 3 | [Canonical Honesty Hooks — 5-layer defense](demo/demo-3.gif) | 2.5 min | Gap 2 — paper victory |

Reproduce locally: `brew install asciinema agg && bash demo/record.sh all`

---

## Architecture: 4-Layer Nested Parallel Topology

```
═══════════════════════════════════════════════════════════════════
Harness (cross-session, weeks to months)
   │
   └─ OODC (Observe → Orient → Decide → Create, 1 major goal = 1 loop)
        │
        └─ Superpower Pipeline (Phase 0 → 1 → 2 → 3 → 4)
             │   Phase 0  kickoff (load skills + create tasks + manifest draft)
             │   Phase 1  parallel exploration (brainstorm, retro, compete scan)
             │   Phase 2  decision convergence (P10 ratifies, no more options)
             │   Phase 3  development  (N waves of true parallel P8 agents)
             │   Phase 4  close (launch / retrospective / handoff)
             │
             └─ PUA P10 / P9 / P8 / P7
                  P10  = CEO override — ratifies strategy, never writes code
                  P9   = Tech Lead — writes Task Prompts, never writes code
                  P8   = Senior Eng — same-message true parallel, owns a file domain
                  P7   = P8-spawned sub-agent — granular sub-tasks
═══════════════════════════════════════════════════════════════════
```

### The 8 P9 Iron Rules (never violate)

1. P9 dispatches multiple P8s in a single message — true parallel, not sequential
2. P8 spawns P7 internally — P9 never manages P7 directly
3. P10 never writes Task Prompts, never manages P8
4. **P9 never writes code** — writing code = role drift = automatic PUA 3.5 penalty
5. CEO (P10) always overrides P9
6. File domain isolation — grep-verify no overlap before dispatch
7. Same-message multi-Agent = true parallel (not loop-sequential)
8. P9 runs verification commands and pastes output — no empty claims

---

## The 5 Words We Want in the Agent Engineering Vocabulary

harness-engineering introduces 5 precise concepts that fill gaps in the current agent
engineering lexicon:

| Term | Definition |
|---|---|
| **Thin Watering Principle** (薄浇水律) | Apply harness constraints as a thin, universal layer — never couple enforcement to private personal config. The harness should work for anyone without modification. |
| **7-Field Handoff Schema** (session 交接 7 字段) | The minimum viable handoff: `sprint / next_action / blockers / decisions / files_changed / self_check / romeo_score`. Missing any field = the next session is flying blind. |
| **Romeo 6-Dim Audit** (Romeo 6 维 audit) | Six independent dimensions — Honesty, Ownership, TechDepth, PatternReplay, Density, Candidates — each scored 0-1.00. Overall bar: average ≥0.99 hardcore. Not a checklist, a judgment framework. |
| **Canonical Honesty Rule** (canonical 诚实律) | Every claim requires evidence paste. "It works" without command output = 0 points. The hook system enforces this at the PreToolUse layer, before the AI can write a completion. |
| **4-Layer Nested Parallel** (4 层嵌套并行) | Harness ⊃ OODC ⊃ Superpower Phase 0-4 ⊃ PUA P10-9-8-7. Concurrency at every layer. Not just "run agents in parallel" — structured parallelism with role separation and file domain isolation. |

---

## Documentation

Workflow MDs ship as part of the kernel. English versions land in W2:

- [`workflows/pua-topology.md`](workflows/pua-topology.md) — P10-9-8-7 topology + 8 iron rules
- [`workflows/oodc-superpower-harness-orchestration.md`](workflows/oodc-superpower-harness-orchestration.md) — OODC loop orchestration
- [`workflows/superpower-pipeline.md`](workflows/superpower-pipeline.md) — Phase 0-4 engineering pipeline
- [`workflows/skill-loading-sop.md`](workflows/skill-loading-sop.md) — Skill loading SOP
- [`workflows/kb-ingestion-sop.md`](workflows/kb-ingestion-sop.md) — KB ingestion + Compound Engineering

---

## Optional Integrations

harness-engineering is the kernel. These are optional layers you can add on top:

### superpowers (recommended)

The `superpowers` plugin by Jesse Vincent provides the Skill system that harness workflow MDs
reference. Install separately:

```bash
claude plugin install superpowers
# or: see https://github.com/jessevictoria/superpowers
```

When installing harness with install.sh, pass `--with-superpowers` to auto-install.

### Maintainer's Private Plugins (optional, advanced)

The following plugins are referenced in harness workflow MDs and available from their respective
repositories. They are **not bundled** with harness-engineering and are **not auto-installed**.
Review each project's license before use — license compatibility with Apache-2.0 is your
responsibility.

- **PUA** (`--with-pua`): Performance Under Accountability — P10-9-8-7 topology enforcement +
  Romeo 6-dim scoring. Visit the PUA repo for installation.
- **claude-mem** (`--with-claude-mem`): Persistent semantic memory across sessions.
- **tacit-kb** (`--with-tacit-kb`): Tacit knowledge base — Compound Engineering pipeline
  (decisions / exemplars / analogies / evolution).
- **doc-sync** (`--with-doc-sync`): Document synchronization + knowledge base ingestion routing.

> These plugins were built for a specific engineering context. They work best when you understand
> the harness topology first. Start with the kernel, add plugins when you feel the gap.

---

## Compatibility

| Platform | Status |
|---|---|
| macOS Sonoma 14+ (Apple Silicon + Intel) | Tested |
| macOS Monterey 12 / Ventura 13 | Should work (bash 3.2+) |
| Ubuntu 22.04 LTS (x86_64) | Tested (W6 cross-platform verify) |
| Ubuntu 20.04 LTS | Should work |
| Windows (WSL2) | Untested, community welcome |

**Requirements**: `bash 3.2+` · `jq` · `git` · Claude Code CLI

Install jq if missing:
```bash
# macOS
brew install jq

# Ubuntu / Debian
sudo apt-get install -y jq
```

---

## License

[Apache-2.0](LICENSE)

You are free to use, modify, and distribute this software for any purpose. The Apache-2.0 license
includes a patent grant — appropriate for infrastructure frameworks. See LICENSE for full terms.

---

## Credits

- **Mitchell Hashimoto** — "harness engineering" naming. The concept of a thin harness layer
  that constrains and shapes a more powerful underlying system without replacing it.
- **Andrej Karpathy** — Agentic engineering vision. The Why behind structured AI agent
  engineering: systems that are reliable, auditable, and production-grade. harness is the How.
- **Jesse Vincent** — superpowers plugin architecture. The Skill system that makes harness
  workflow MDs composable and discoverable.

---

## Status Badges (W5 CI)

The following badges will be populated when GitHub Actions CI ships in W5:

```
[![CI](https://github.com/mrshaper/harness-engineering/actions/workflows/ci.yml/badge.svg)]
[![Coverage](https://img.shields.io/badge/coverage-TBD-lightgrey)]
[![Version](https://img.shields.io/github/v/tag/mrshaper/harness-engineering)]
```

---

## Contributing

Issues and PRs welcome. Before opening a PR:

1. Read `workflows/pua-topology.md` — understand the P8 file domain isolation rule
2. Every claim in the PR description needs evidence (command output, test results)
3. New hooks: must pass Layer 0 health check + add a test in `tests/`
4. New workflow MDs: must follow the 7-field handoff schema and Romeo audit format

If you find a use case the kernel doesn't cover, open an issue before building — the kernel
scope is intentionally narrow. Scope creep is the enemy of a reusable harness.

---

*"The goal is not to make AI smarter. The goal is to make AI reliable."*

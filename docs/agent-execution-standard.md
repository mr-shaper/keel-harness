---
type: standard
domain: sprint-ops
created: 2026-05-03
version: 0.1.0
---

# Agent Execution Standard for harness-managed Sprints

> Any agent (LLM-based or human) working on a harness-managed sprint **must** read and follow
> this standard before executing any multi-step plan. This document is part of the harness OSS
> kernel and is checked on every install via `manifest.json`.

---

## §1 Purpose

This standard exists because execution quality collapses when agents start work without loading
the correct methodology. A plan that looks complete on paper fails at runtime when the agent
skips Skill verification, ignores the role topology, or runs phases without a real-time kanban.
This document gives any agent — regardless of which LLM runtime powers it — an unambiguous
pre-execution contract: read these workflow files, verify these Skill dimensions, create these
TaskCreate entries, then and only then begin sprint work.

---

## §2 Plan-Authoring Rule

Every multi-step plan (3 or more steps, or any plan touching more than one file) **must be
designed for execution under the 4-layer nested topology** listed below. The plan document
itself must be readable as a guide for the executing agent: each Wave or Phase in the plan
must name which topology layer governs it.

### 2.1 The Four Topology Layers

**Layer 1 — Harness (cross-session continuity)**
Harness provides immutable, append-only handoff documents between sessions. Every plan must
identify its handoff boundary: where does one session end and the next pick up? Handoff files
are the ground truth for `next_action`. No agent may override a handoff's stated next action
without a new handoff superseding it.

**Layer 2 — OODC (cognitive loop)**
Every plan's phases map onto the OODC cognitive cycle:
- **Observe** — gather raw facts, audit current state, run probes
- **Orient** — synthesize findings, identify gaps, score options
- **Decide** — ratify a direction (P10 or CEO authority required for L4 decisions)
- **Create** — implement, verify, ship

A plan that jumps straight to Create without Observe/Orient/Decide produces unverified work.
The plan document must label which Wave is Observe, which is Orient, and so on.

**Layer 3 — PUA P10-9-8-7 role topology**
Every plan must state who owns each decision level:
- **CEO** overrides all
- **P10 (CTO / Strategy)** owns L4 strategic decisions — sprint scope, Wave order, outcome
  evaluation. P10 does not write Task Prompts.
- **P9 (Tech Lead)** writes Task Prompts and dispatches P8 agents in true parallel (same
  message, multiple Agent calls). P9 never writes code.
- **P8 (Independent executor)** owns a file domain, internally spawns P7 for sub-tasks.
  P8 does not overlap file domains with sibling P8 agents (grep verify before writing).
- **P7 (Sub-agent)** executes narrow, bounded tasks as instructed by P8.

**Layer 4 — Superpower Pipeline (Phase 0-4 engineering stages)**
Every plan follows the five-phase engineering lifecycle:
- **Phase 0 — Kickoff**: verify Skill loading, create TaskCreate kanban, confirm topology mapping
- **Phase 1 — Parallel Explore**: P9 dispatches multiple P8 agents in the same message to
  investigate independent questions simultaneously
- **Phase 2 — Decision Convergence**: P9 aggregates P8 reports; P10 or CEO ratifies direction
- **Phase 3 — Development**: P8 agents implement in parallel, file domains non-overlapping
- **Phase 4 — Close**: verification evidence pasted, handoff written, doc-sync triggered

### 2.2 How to Write a Topology-Aware Plan

In each Wave or Phase header, include a parenthetical tag naming the governing layer:

```
### Wave 1 — Codebase Audit (OODC: Observe | Superpower: Phase 1 | P9 dispatches 3 P8)
### Wave 2 — Gap Analysis (OODC: Orient | Superpower: Phase 2 | P9 aggregates)
### Wave 3 — Implementation (OODC: Create | Superpower: Phase 3 | P8 parallel, file-domain isolated)
```

This annotation makes the plan self-documenting for the executing agent and prevents
topology confusion mid-sprint.

---

## §3 Mandatory Pre-Execution Workflow Reads

Before executing any multi-step plan, an agent **must** read all five workflow files below.
Reading them is not optional — the `user-prompt-l42-workflow-trigger-gate.sh` hook emits
warnings when an agent references these methodologies without having read the source file
in the current session. Reading up-front prevents those warnings and ensures the agent
applies the real protocol, not a cached approximation.

| File | One-line Purpose |
|------|-----------------|
| `workflows/pua-topology.md` | P10-9-8-7 nested parallel topology, 10 iron rules, decision tree for who decides what and when |
| `workflows/oodc-superpower-harness-orchestration.md` | How OODC cognitive phases (Observe/Orient/Decide/Create) integrate with Superpower Pipeline phases and Harness handoffs |
| `workflows/superpower-pipeline.md` | Phase 0-4 standard stage definitions, trimming table by project type, TaskCreate kanban contract |
| `workflows/skill-loading-sop.md` | How to verify a Skill is actually loaded in the current session (not just listed), 5-dimension verification protocol |
| `workflows/kb-ingestion-sop.md` | Compound Engineering ingestion pipeline, single entry point `kb-ingest-compile.sh`, §10 true vault_root |

**Read order**: read all five before writing any Task Prompt or dispatching any P8 agent.
An agent that dispatches P8 agents before reading `workflows/pua-topology.md` is writing
blind Task Prompts — the dispatched agents will lack role boundary clarity.

---

## §4 Skill-Loading Verification — 5 Dimensions

A Skill name appearing in a list is not evidence that the Skill is loaded. Listing a Skill
without verifying it is "stub-only" loading — the agent performs a Skill without applying its
rules. Stub-only loading is the single most common cause of sprint failures.

Verify all five dimensions before claiming any Skill is active:

| Dim | What to Check | PASS Signal |
|-----|--------------|------------|
| **(a) Tool invocation confirmed** | Skill tool was actually called (not just mentioned) | Skill tool call appears in session transcript |
| **(b) References body actually read** | The Skill's reference documents were Read (≥200 LOC consumed) | `Read` tool call on `references/` files with line-count evidence |
| **(c) Protocol rules actually applied** | Skill-specific constraints are enforced in behavior, not just recited | Concrete behavior demonstrates constraint: e.g., P9 dispatches Task Prompts, does not write code |
| **(d) Sub-agent injection fires** | When spawning sub-agents, the parent agent injects the Skill's protocol into the Task Prompt | Task Prompt contains explicit Read instruction for the Skill file |
| **(e) Self-evaluation evidence-aligned** | Self-score ≥ 3.75 only if the above four dims are all pasted as evidence | Score is accompanied by concrete evidence per dim, no assertion-only claims |

**If any dimension is missing** → the Skill is stub-only / performing-not-loaded → sprint
work built on that Skill is invalid. Stop, load the Skill properly, re-run Phase 0.

---

## §5 Wave/Phase Real-Time Kanban — TaskCreate Requirement

Every Wave and every Phase in a multi-step plan **must be backed by a TaskCreate entry**
before work on that Wave begins. The aggregate TaskCreate list is the Superpower Pipeline
stage tracker. It is the only authoritative view of sprint progress.

### 5.1 Creation Rule

At Phase 0 (Kickoff), P9 creates one TaskCreate entry per Wave/Phase in the plan. Do not
wait until a Wave starts to create its entry — create all entries up front so the kanban
is complete and reviewable from the first moment of the sprint.

### 5.2 Status Lifecycle

```
pending → in_progress → completed
```

- Mark a Wave `in_progress` when the first P8 agent begins work on it.
- Mark a Wave `completed` only after verification evidence has been pasted (no empty claims).
- Never mark `completed` while any P8 agent's file-domain work is unverified.

### 5.3 Why This Matters

A sprint without TaskCreate entries is invisible. P9 cannot aggregate progress. P10 cannot
verify Wave order. The Harness Stop hook cannot confirm handoff completeness. Phases without
TaskCreate are treated as unevidenced — same penalty as a missing verification command.

---

## §6 Pre-Execution Checklist

Copy and paste this checklist into your session before executing any multi-step plan.
Every item must be checked — unchecked items block sprint GATE.

```
- [ ] Read workflows/pua-topology.md (P10-9-8-7 topology + 10 iron rules)
- [ ] Read workflows/oodc-superpower-harness-orchestration.md (OODC-Superpower integration)
- [ ] Read workflows/superpower-pipeline.md (Phase 0-4 stage tracker)
- [ ] Read workflows/skill-loading-sop.md (Skill 5-dim verification protocol)
- [ ] Read workflows/kb-ingestion-sop.md (Compound Engineering ingestion pipeline)
- [ ] Verify each active Skill on all 5 dims (a)-(e) — paste evidence per dim
- [ ] Create TaskCreate entries for every Wave/Phase in the plan (do this at Phase 0)
- [ ] Annotate plan Waves with topology layer tags (OODC phase + Superpower Phase + role)
- [ ] Confirm role mapping: who is CEO/P10/P9 in this sprint? Who decides L4 questions?
- [ ] Confirm file-domain isolation: no two P8 agents share a file domain (grep verify)
```

---

## §7 Failure Modes

The following mistakes account for the majority of sprint quality drops. Each maps to a
specific topology violation.

| Failure Mode | Topology Layer Violated | Consequence |
|-------------|------------------------|-------------|
| **Skipping workflow reads** — agent applies remembered approximations of OODC/PUA/Superpower instead of reading the source files | L42 rule (workflow MD emphasis-keyword trigger) | Wrong methodology applied; hook emits warnings; sprint output invalid |
| **Treating Skill name in a list as "loaded"** — no tool invocation, no reference read, no dim verification | Skill-loading SOP §5 (5-dim) | Stub-only performance; Skill constraints not applied; sprint fails silently |
| **Phase work without TaskCreate** — Waves executed without a kanban entry | Superpower Pipeline Phase 0 (kickoff) | Sprint progress invisible; P9 cannot aggregate; Stop hook reports incomplete |
| **P9 writing code instead of Task Prompts** — Tech Lead role confusion | PUA P10-9-8-7 Iron Rule ④ | Role boundary collapse; code quality ungated; drops below 3.75 baseline |
| **Sequential agent dispatch** — P9 sends one P8 at a time instead of same-message parallel | PUA P10-9-8-7 Iron Rule ① | Sprint wall-clock doubles; parallelism gain lost; P9 role mis-executed |
| **P9 self-deciding L4 strategy** — sprint scope or Wave order decided without P10/CEO | PUA P10-9-8-7 Iron Rule ⑨ | L41 rule triggered; strategic decision unratified; sprint outcome questioned |
| **Evidence-free completion claim** — "done" stated without pasted verification output | PUA red-line 1 (closure awareness) | Red-line breach; drops below 3.75; L3 review triggered |
| **File-domain overlap between P8 agents** — two P8s write to the same file | PUA P10-9-8-7 Iron Rule ⑥ | Merge conflicts; one P8's work silently overwrites another's |

---

## §8 References

- `HARNESS_BIBLE.md` — Sprint contract law. Layer 0 five-element iron rules, Category H
  canonical rules (L16-L37), handoff format, scope_forbidden list (25 conditions, frozen
  at v1.13), and the Bible First Law governing single-deployment constraint.
- `audit/romeo-6-dim-framework.md` — Sprint quality gate. Six scoring dimensions (Honesty /
  Completeness / Root-Cause / Alternatives / Prose / Evidence-Chain) used by Romeo audit
  agents to evaluate sprint output. A sprint claiming ≥ 3.75 must pass all six dimensions
  with pasted evidence.
- `docs/sprint-kickoff-checklist.md` — Five-layer GATE self-check (Entity / Content / GATE /
  Config / Behavior-Fire). Run at every sprint kickoff to verify harness wiring before
  declaring any sprint work valid.
- `workflows/skill-loading-sop.md` — Full 4-layer loading mechanism and 5-dimension Skill
  verification protocol referenced in §4 of this document.

---
type: workflow
domain: ai-systems
name: PUA P10-9-8-7 Parallel Topology
description: P10-9-8-7 parallel topology — permanent law. P9 dispatches multiple P8 in true parallel, P8 spawns P7 internally, P9 never writes code directly.
created: 2026-04-29
confidence: 0.9
stale: false
---

# PUA P10-9-8-7 Parallel Topology (Permanent Cross-Sprint Law)

> v1.11.2 · Synthesized from 8+ teaching sessions · Required reading for any P9-led sprint

## Topology Diagram

```
═════════════════════════════════════════════════════════════════════════════
                CEO (ultimate authority)
           Ratifies / decides / overrides P10 (D-path override)
                              │
                              │ strategic ask
                              ↓
═════════════════════════════════════════════════════════════════════════════
                       ┌──────────┐
                       │   P10    │  ← Agent spawn (subagent_type=pua:cto-p10)
                       │ Strategy │
                       └──────────┘
   Output: 6 strategic inputs + ratification
   Iron Rule: does NOT write Task Prompts, does NOT manage P8, talks only to P9
                              │
                              │ strategic inputs dispatched
                              ↓
═════════════════════════════════════════════════════════════════════════════
                       ┌──────────┐
                       │    P9    │  ← inline this session (director)
                       │Tech Lead │
                       └──────────┘
   Output: Task Prompt 6-element spec (WHY/WHAT/WHERE/HOW MUCH/DONE/DON'T) + 4-line PUA tail injection
   Iron Rule: NEVER writes code. Your code IS the Prompt.
                              │
                              │ true parallel spawn in same message (no dependencies)
       ┌──────────────┬───────┴───────┬──────────────┐
       ↓              ↓               ↓              ↓
═════════════════════════════════════════════════════════════════════════════
   ┌──────┐       ┌──────┐        ┌──────┐       ┌──────┐
   │ P8-A │       │ P8-B │        │ P8-C │       │ P8-D │  ← Agent spawn (parallel)
   │ Self-│       │ Self-│        │ Self-│       │ Self-│     non-overlapping file domains
   │suff. │       │suff. │        │suff. │       │suff. │
   └──────┘       └──────┘        └──────┘       └──────┘
   Output: code / system / solution + TRF + evidence-paste
   Iron Rule: P8 self-determines sub-topology. Spawns P7 in true parallel for complex tasks.
       │                │                │              │
       │ (self-decided) │                │              │
       ↓                ↓                ↓              ↓
═════════════════════════════════════════════════════════════════════════════
  ┌──┬──┬──┐         ┌──┬──┐          ┌──┐         ┌─────┐
  ↓  ↓  ↓  ↓         ↓  ↓  ↓          ↓  ↓         ↓     ↓
 P7 P7 P7 P7        P7 P7 P7         P7 (solo)   P7 P7 (pair)
 (P8-A: 4 P7)     (P8-B: 3 P7)    (P8-C: 1 P7)  (P8-D: 2 P7)
   Output: solution + impact analysis + 3-question self-audit + [P7-COMPLETION] report to P8
═════════════════════════════════════════════════════════════════════════════
```

## 8 Iron Rules (sprint-validated, v1.11.2)

| # | Rule | Violation = |
|---|------|-------------|
| 1 | **P9 dispatches multiple P8 in true parallel** (same-message multi-Agent calls for independent tasks) | P8 runs serially 90 min instead of true-parallel 25 min |
| 2 | **P8 spawns P7 internally** — P9 does not micromanage P8's sub-topology | P9 overstepping into P8 internals (role confusion) |
| 3 | **P10 does NOT write Task Prompts, does NOT manage P8** (talks only to P9) | P10 operating below its level |
| 4 | **P9 NEVER writes code** (writing code = role misalignment failure mode) | Falls below 3.5 baseline |
| 5 | **CEO (the human user) overrides P10** with final ratification (D-path examples). CEO is human, P10 is the AI CTO; CEO is the ultimate authority above the entire AI hierarchy | — (CEO is always trump card) |
| 6 | **Non-overlapping file domains**: parallel P8s must not touch the same files; P9 grep-verifies | Race conditions + data corruption |
| 7 | **Same-message** multi-Agent calls = true parallel (NOT sequential) | Pseudo-parallel — performance loss |
| 8 | **Verification loop closed**: P9 runs commands to verify P8 actually shipped, no verbal claims | Breaks red-line #1 (closed loop) |

## True Parallel vs Pseudo-Parallel

**True Parallel (correct):**
- Multiple Agent tool calls within the same message → execute simultaneously
- Non-overlapping file domains (e.g., 5 different files for 5 deliverables)
- Each P8 has an independent, self-contained context

**Pseudo-Parallel (wrong):**
- Sequential spawn (wait for previous to finish before spawning next)
- P8 dispatches P7 as "parallel" (that level belongs to P9 dispatching P8)
- Overlapping file domains → race conditions
- P9 runs Bash commands directly (role misalignment)

## Decision Tree (P9 on receiving a task)

```
Receive task
   │
   ├─ < 3-step small change? ─→ P9 inline (no pipeline)
   │
   └─ Cross-module / complex?
        │
        ├─ Sprint scope unclear? ─→ spawn P10 to ratify strategy
        │
        └─ Scope already defined?
             │
             ├─ Single deliverable? ─→ spawn 1 P8 (≤90 min)
             │
             ├─ 2+ independent deliverables, non-overlapping file domains?
             │    ─→ same-message multi-Agent calls (P9 dispatches multiple P8 in true parallel)
             │
             └─ 5+ deliverables, large granularity?
                  ─→ TeamCreate tmux multi-P8 + independent worktrees
```

## Granularity Rules

- **2–3 P8** → same-message multi-Agent calls
- **4–5 P8** → same-message multi-Agent OR TeamCreate tmux team
- **>5 P8** → coordination cost > benefit; split into multiple sprints

## Nested Parallelism (P8 Internal P7)

```
P8-A receives complex task
   │
   └─ decides to spawn 4 P7 in true parallel (P8 self-decides; P9 does not manage):
       ┌───┬───┬───┬───┐
       ↓   ↓   ↓   ↓
      P7  P7  P7  P7    ← P8 internal sub-topology
       │   │   │   │
       └───┴───┴───┴───→ P8 aggregates → TRF reports to P9
```

One P9 sprint can run 5 P8 × 4 P7 = **20 LLM agents in true nested parallelism**.

## Sprint Benchmark Data

- Phase 6.6 first attempt (wrong): 1 P8 running 6 deliverables serially — 90 min
- After correction: 5 P8 in true parallel (5 non-overlapping file domains) — **25 min**
- Real 3.5x speedup (wall time determined by slowest P8)

## Common Anti-Patterns

| Anti-Pattern | Root Cause | Correct Behavior |
|---|---|---|
| P9 writes code directly | Role confusion: P9 should direct, not implement | Write a Task Prompt; spawn P8 |
| P8s spawned one-at-a-time | Sequential mindset | Dispatch all independent P8s in the same message |
| P10 writes detailed prompts | P10 operates at strategy level only | P10 outputs 6-element strategic input; P9 writes prompts |
| P9 micromanages P8 internals | Unnecessary downward coupling | Trust P8 to self-determine sub-topology |
| "Parallel" P8s share files | Missing domain isolation step | P9 verifies non-overlapping domains before dispatch |

## Quick-Reference Card

```
Role     Owns                           Never Does
──────   ────────────────────────────   ──────────────────────────────────
CEO      Final authority / override     —
P10      6-element strategic input      Write Task Prompts / manage P8
P9       Task Prompts + dispatch        Write code / micromanage sub-topology
P8       Deliverable + TRF              Touch another P8's file domain
P7       Sub-task solution + self-audit Report to P9 directly (goes to P8)
```

## Supporting Protocols

- p10-protocol: `$CLAUDE_HOME/plugins/pua/skills/pua/references/p10-protocol.md`
- p9-protocol: `$CLAUDE_HOME/plugins/pua/skills/pua/references/p9-protocol.md`
- p7-protocol: `$CLAUDE_HOME/plugins/pua/skills/p7/SKILL.md`
- pua three red lines: `$CLAUDE_HOME/plugins/pua/skills/pua/SKILL.md`

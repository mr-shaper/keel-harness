---
type: workflow
domain: ai-systems
name: OODC + Superpower Pipeline + Harness — Three-Methodology Nested Orchestration
description: Required reading before starting any complex sprint. One-line positioning of each methodology, nested relationship, and how PUA topology executes within them. Distilled from v1.11.2 production sprints; permanent across sessions.
created: 2026-04-29
confidence: 0.8
stale: false
last_ingested: 2026-04-30T02:51:31Z
---

# OODC + Superpower Pipeline + Harness — Nested Orchestration Guide

> Distilled from v1.11.2 production sprints (s35→s38, 4 sessions, K12 6/6 FULL + L36 fix).
> Required reading for any P9-led complex sprint before kickoff.

## §1 Three-Methodology One-Line Positioning

- **OODC**: Cognitive Loop — 4 steps (Observe → Orient → Decide → Create). One sprint = one full cycle. Prevents paper victory.
- **Superpower Pipeline**: Engineering execution — 5 phases (Phase 0 Kickoff → 1 Explore → 2 Decide → 3 Build → 4 Wrap-up). Runs inside the Create phase.
- **harness mode**: Time dimension — 24h+ cross-session continuity. Prevents "Claude getting dumber over time." Wraps both layers above.

## §2 Three-Methodology Nested Relationship

```
═══════════════════════════════════════════════════════════════════
Harness (time dimension 24h+, wraps everything)
   │
   └─ OODC (cognitive loop — one sprint = one OODC cycle)
        │
        └─ Superpower Pipeline (execution layer — OODC-C phase = Phase 0-4)
             │
             └─ PUA P10-9-8-7 (org layer — multiple P8 agents run in true parallel within each Phase)
═══════════════════════════════════════════════════════════════════
```

Each layer has a distinct, non-overlapping responsibility:
- **Harness**: Cross-session immutable handoff; prevents memory loss.
- **OODC**: Prevents jumping straight to Create without research.
- **Superpower**: Prevents chaotic execution inside Create without phase convergence.
- **PUA**: Prevents single-agent serial work inside each Phase.

## §3 OODC 4-Step Mapping to Sprint Activities

### O — Observe (Research)
- Read the 5 required docs (handoff / SELFCHANGELOG / HARNESS_BIBLE / lessons / previous handoff).
- Run argus skill for genuine research if a new domain is involved.
- Evidence-paste required — no verbal claims (epoch / md5 / trace.log / lsof / ps).
- List root-cause hypotheses (H1 … HN).

### O — Orient (Diagnosis)
- Eliminate hypotheses via evidence (evidence-driven, not voting).
- Evolve true cause N+0 → N+1 → N+2 (paper → true cause → sub-cause).
- Socratic inquiry: keep drilling to the lowest layer.

### D — Decide (Strategy)
- Spawn P10 to define the 6-element strategic input.
- CEO override always trumps P10.
- List paths A/B/C/D as equals with quantified Pros/Cons.
- Define scope boundary explicitly: what is in scope / out of scope.

### C — Create (Execution)
- Enter Superpower Pipeline 5-phase execution.

## §4 Superpower Pipeline — 5 Phases Mapped to Sprint Activities

| Phase | Activities | v1.11.2 Example |
|-------|------------|-----------------|
| **Phase 0 Kickoff** | Load SKILLS for real + TaskCreate board + read 5 required docs + answer 5 self-checks | Phase 0.1 (skill body Read) + 0.2 (12 tasks created) |
| **Phase 1 Explore** | P9 dispatches multiple P8 agents in true parallel to research + verify hypotheses | Phase 6.3 (P8 verify 6 plugin hook fire statuses) |
| **Phase 2 Decide** | P9 reports up; P10 ratifies; CEO override path | Phase 6.1+6.2 (P10 round 2+3 ratify S3 hybrid) |
| **Phase 3 Build** | P9 dispatches multiple P8 agents in true parallel to ship deliverables | Phase 6.4 (P8 round 6 S3 migrate script + apply) |
| **Phase 4 Wrap-up** | NEW handoff + SELFCHANGELOG + state + lessons + KB ingest via doc-sync skill | Phase 5.6 + 6.6 (5 P8 true-parallel ship 6 deliverables) |

## §5 How Harness Wraps the Time Dimension

- **`.harness/state` trigger**: If present in cwd → harness mode activates automatically.
- **5 required reads + 5 self-checks**: SessionStart auto-injects; AI must complete all.
- **Immutable handoff**: sN-to-sN+1 cannot be modified after sN+1 kicks off. When sN+1 closes, write a NEW handoff-sN+1-to-sN+2.
- **L31-L36 meta-law family**: CLAUDE.md revision 6-dim / Runtime ≠ Code ship / round-N amendment / subtree mp symlink / self-development blind spot / transcript byte-slice.
- **Compound 4 true-value sources burned in**: KB raw + HARNESS_BIBLE §9 + handoff + lessons.

## §6 PUA P10-9-8-7 Executing Inside Each Phase

See `$CLAUDE_HOME/workflows/pua-topology.md` for the full decision tree and nested parallel graph. Core:

- **CEO** (ultimate authority) — ratifies / overrides P10.
- **P10** (strategy layer) — spawns `pua:cto-p10`, writes 6-element strategic input, does NOT write Task Prompts.
- **P9** (Tech Lead) — runs inline this session, writes Task Prompts, dispatches multiple P8 agents in true parallel.
- **P8** (independent contributor) — spawned as Agent, file domain must not overlap, resolves P7 internally.
- **P7** (sub-task) — spawned internally by P8, applies three-question self-review.

**8 Iron Rules**: P9 dispatches multiple P8 in true parallel / P8 spawns P7 internally / P10 does not manage P8 directly / P9 never writes code (role violation) / CEO always overrides / file domain isolation / same-message multi-Agent = true parallel / verification-before-completion closes the loop.

## §7 v1.11.2 Production Example (Live Case)

### O — Observe (s35 Romeo audit + s36 fresh terminal reveal)
- s35: paper victory — K9 0.855 / K13 0.990 (Romeo R1→R3).
- Fresh terminal verify FAIL → revealed 13 days of silent dead.
- Evidence: outcomes epoch stuck at 1777420591 / cumulative stuck at 1777420593.

### O — Orient (True Cause N+0 → N+3)
- N+0: paper victory (Romeo audit measuring the wrong dimension).
- N+1: codepilot 3 mp were independent copies, not symlinks (physical violation of Bible First Law).
- N+2: plugin loader silent vs USER-level fire (Claude Code runtime bug).
- N+3: handoff-read-gate jq parse on 23KB byte-slice (L36 emergent).

### D — Decide (CEO Override)
- P10 round 1 ratified Path B (push v1.12) → CEO overrode to Path D (symlink unify).
- P10 round 2 ratified S1 Path A workaround → CEO upgraded to S3 hybrid.
- P10 round 3 ratified S3 hybrid 1.C / 2.A / 3.B / 4 (Wave 1 enforce core / hooks={} skeleton / drift detection / 6-dim verify).

### C — Create (Phase 0-4 in Production)
- Phase 5.1-5.4: P8 round 2 Path D atomic mv + symlink unify (md5 same-source verified).
- Phase 5.6: P8 round 3 — 5 deliverables accounted.
- Phase 5.7: P8 round 4 — handoff naming corrected.
- Phase 6.4: P8 round 6 — S3 migrate script + applied.
- Phase 6.6: 5 P8 true-parallel (D1+D3+D4+D5+D6) — 25 min vs 90 min single P8 = 3.5x speedup.

### Wrap-up
- Compound 7 permanent assets burned in (KB / HARNESS_BIBLE / handoff / lessons / CLAUDE.md / workflows / feedback memory).
- L36 emergent fix — 1-line sed (`tail -c 200000` → `tail -n 200`).
- v1.12 backlog R7-R9 + L34/L35/L36 candidate ratify.

## §8 7-Step Reuse Checklist for Any Architecture-Level Sprint

1. **Enter harness mode** (cwd contains `.harness/state` → automatic) — SessionStart auto-injects.
2. **OODC O phase** — argus genuine research + 5 required reads + evidence-paste true-cause reveal.
3. **OODC D phase** — spawn P10 to define 6-element strategic input (CEO override is always the trump card).
4. **Superpower Phase 0 Kickoff** — load Skills for real + TaskCreate board + answer 5 self-checks.
5. **Superpower Phase 1-3** — P9 dispatches multiple P8 agents in true parallel (same-message multi-Agent calls).
6. **Superpower Phase 4 Wrap-up** — NEW handoff + SELFCHANGELOG + state + lessons + KB ingest via doc-sync skill.
7. **Compound 4-7 true-value sources burned in** — KB raw / HARNESS_BIBLE §9 / handoff / lessons / CLAUDE.md / workflows / feedback memory.

Complete all 7 steps = genuine ship + genuine close-loop + genuine Compound. Skip any step = performance art.

## §9 Anti-Patterns (What False Execution Looks Like)

| Anti-Pattern | Detection Signal | Correct Action |
|---|---|---|
| Skip OODC-O, jump straight to Create | No evidence-paste, no hypothesis list | Force OODC-O; run argus or 5 required reads first |
| P9 writes code directly | P9 edits a file instead of dispatching P8 | Halt; spawn P8 for the coding task |
| Single P8 serial execution | Only one Agent call per message | Dispatch multiple P8 agents in the same message |
| "Done" without verification | Verbal claim, no command output pasted | Run verification command; paste stdout evidence |
| Compound as performance | AI mentions Compound but no KB file created | Check `kb.py query`; demand trace log entry |

## §Companion Protocols

- **pua-topology**: `$CLAUDE_HOME/workflows/pua-topology.md` (8 iron rules + decision tree + nested parallel)
- **skill-loading-sop**: `$CLAUDE_HOME/workflows/skill-loading-sop.md` (Skill stub vs body)
- **kb-ingestion-sop**: `$CLAUDE_HOME/workflows/kb-ingestion-sop.md` (doc-sync skill as sole entry point)
- **claude-env-sprint-playbook**: `$CLAUDE_HOME/workflows/claude-env-sprint-playbook.md` (14-step replication)
- **p10-protocol**: `$CLAUDE_HOME/plugins/pua/skills/pua/references/p10-protocol.md`
- **p9-protocol**: `$CLAUDE_HOME/plugins/pua/skills/pua/references/p9-protocol.md`
- **pua 3 red lines**: `$CLAUDE_HOME/plugins/pua/skills/pua/SKILL.md`

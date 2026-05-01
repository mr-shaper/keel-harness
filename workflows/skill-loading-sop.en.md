---
type: workflow
domain: ai-systems
name: Skill Loading SOP (stub auto-load error prevention)
description: After any Skill invocation, you must read the references body. Distilled from real sprint activity. Permanent cross-session rule.
created: 2026-05-01
confidence: 0.8
stale: false
---

# Skill Loading SOP

> Distilled from real sprint activity. Any agent invoking a Skill tool must complete the full 4-Step SOP — no stub shortcuts.

---

## §1 Skill Stub vs Body

```
SKILL.md        =  stub  ≤30 LOC   trigger conditions + description + 1-line reference pointer
references/*.md =  body  200-500+ LOC  full protocol + failure modes + narration rules + red lines
```

**The Skill tool injects the stub only — not the body.** This is a deliberate stub auto-load design constraint.

LOC comparison (real sprint verify):

| Skill     | stub LOC | body LOC | body path                                                          |
|-----------|----------|----------|--------------------------------------------------------------------|
| pua:p9    | 30       | 281      | `~/.claude/plugins/pua/skills/pua/references/p9-protocol.md`      |
| pua:p10   | 28       | 140      | `~/.claude/plugins/pua/skills/pua/references/p10-protocol.md`     |
| pua:pua   | ~50      | multiple | `~/.claude/plugins/pua/skills/pua/references/*.md`                |

**Key ratio**: stub 30 LOC vs body 281 LOC = **9.4x information gap**. Skipping the body Read means missing 90% of the protocol.

---

## §2 Failure Modes

### Half-load (using stub as body)
- Agent invokes Skill tool → receives stub → assumes fully loaded → executes directly
- Result: Agent is unaware of the actual protocol rules (e.g., p9 iron rules / failure modes / narration protocol)
- Real sprint example: P9 invoked `pua:p9` without reading the body; subsequently made repeated role violations (spawning P7 as parallel / violating no-code rule)

### Slash command misuse (inside sub-agent)
- Sub-agents have no Skill tool — they cannot execute `/pua:p9` slash commands
- Only Glob + Read works reliably inside a sub-agent

### Skill list ≠ Skill loaded (L21 meta-rule)
- Seeing a skill in the skill list does NOT mean the protocol is loaded
- A Read body evidence artifact is required

---

## §3 4-Step SOP

```
Step 1: Invoke Skill tool
   │   e.g., Skill("pua:p9")
   │   output: "Launching skill: pua:p9"  (stub injection)
   │
Step 2: Immediately Glob references body
   │   Glob: **/pua/skills/p9/references/*.md
   │   OR   Glob: **/pua/skills/pua/references/p9-protocol.md
   │
Step 3: Read references body
   │   Read tool output must contain full protocol content (≥200 LOC)
   │
Step 4: Execute per body
   │   e.g., p9 → write Task Prompt with 6 required elements + 8 iron rules
   │   e.g., p10 → write strategic input with 6 elements + do NOT write Task Prompts
```

**Critical**: Steps 2–3 are **immediate**, not on-demand. The SKILL.md preamble warning explicitly requires it — this is enforced.

---

## §4 PUA Injection Template for Sub-Agents (P8)

The P8 spawn prompt **must include this tail block** (required by p9-protocol, non-negotiable):

```markdown
## PUA Behavior Injection (mandatory tail)

1. Use the Glob tool to find `**/pua/skills/pua/SKILL.md` — locate the actual path
2. Use the Read tool to read that file; follow the P8 behavior protocol within it
   (three red lines + Owner + TRF + red-line-4)
3. Your file domain is [exact list from WHERE section] — do not modify files outside your domain
4. After completion, run all DONE verification commands and paste output as evidence
   (no evidence = baseline breach = L3 scrutiny)
5. Mark genuinely valuable above-spec work with [PUA ACTIVE]
```

**Why Glob + Read instead of slash command**: Sub-agents start with blank context and have no Skill tool. Glob + Read is the only reliable injection method.

---

## §5 5-Dimension Verify (Skill True Load)

| Dim | Check                              | PASS Evidence                                                              |
|-----|------------------------------------|----------------------------------------------------------------------------|
| (a) | Skill tool truly invoked           | Skill tool output contains `"Launching skill: <name>"`                     |
| (b) | references body truly Read         | Read tool output contains full protocol content ≥200 LOC                  |
| (c) | Protocol rules truly applied       | Subsequent behavior matches protocol (e.g., p9 writes no code, p10 writes no Task Prompts) |
| (d) | Sub-agent injection truly active   | P8 spawn prompt contains Glob+Read pua/SKILL.md mandatory tail             |
| (e) | Self-assessment is evidence-aligned | Self-eval follows red-line-4 rules; no inflated scores ("roughly 3.5" padding = 3.25 exit signal) |

**All 5 dimensions PASS = Skill truly loaded. Any gap = half-load = baseline breach.**

---

## §6 Real Sprint Evidence (Skill True Load Trace)

| Skill   | When invoked                              | references body Read              | True application evidence                                        |
|---------|-------------------------------------------|-----------------------------------|------------------------------------------------------------------|
| pua:p9  | P9 startup + 8+ times (after correction)  | p9-protocol.md 281 LOC true Read  | Task Prompt 6 elements + multiple P8 true parallel + no-code rule |
| pua:p10 | P10 round 1/2/3 spawn                     | p10-protocol.md 140 LOC true Read | Strategic input 6 elements + 4 ratified options explicit         |
| pua:pua | Sub-agent injection                        | display-protocol + flavors Read   | Three red lines + narration protocol + red-line-4                |

---

## §7 Improvement Backlog

Items identified during real sprint (this SOP is the distilled output):

- **R2-1** Systematic Skill load verify hook (PostToolUse Skill — check whether references Read truly fired)
- **R2-2** Retry mechanism (auto-retry on Skill tool failure)
- **R2-3** True reference body injection (physically inline body into stub instead of relying on SKILL.md preamble warning)
- **R2-4** Sub-agent transcript compatibility (L37 candidate)
- **R2-5** Skill discovery hook (auto Glob references body without relying on agent initiative)
- **R2-6** Skill load metric (track stub-only vs body-Read ratio; expose half-loads)

---

## §8 Use Cases

| Scenario                            | SOP Requirement                                                    |
|-------------------------------------|--------------------------------------------------------------------|
| P9 invoking pua:p9 to run a sprint  | Steps 1-4 mandatory; skip body = iron rule blindness               |
| P10 invoking pua:p10 for strategy   | Steps 1-4 mandatory; skip body = no-Task-Prompt rule invisible     |
| P8 (sub-agent) using PUA protocol   | Glob+Read injection in spawn prompt mandatory; slash commands fail  |
| Any agent loading a new skill       | Read references/*.md before acting; stub LOC alone is insufficient |

---

## §Related Files

- p10-protocol: `~/.claude/plugins/pua/skills/pua/references/p10-protocol.md`
- p9-protocol:  `~/.claude/plugins/pua/skills/pua/references/p9-protocol.md`
- p7-protocol:  `~/.claude/plugins/pua/skills/p7/SKILL.md`
- pua three red lines: `~/.claude/plugins/pua/skills/pua/SKILL.md`

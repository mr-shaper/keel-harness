# Quickstart Prompts — How a User Triggers harness Mode

> Copy-pasteable first messages a user sends to Claude Code in a fresh
> session to enter harness mode and start working on a sprint. These are
> *user-facing* prompts; the *agent-facing* execution standard lives in
> `agent-execution-standard.md`.

---

## Prerequisites

Before any of these prompts work, you must have run the installer once:

```bash
curl -fsSL https://raw.githubusercontent.com/mr-shaper/keel-harness/main/install.sh | bash
```

This sets up `~/.claude/CLAUDE.md` with the `§harness mode` contract,
copies the kernel files to `~/.claude/plugins/keel-harness-mp/`, and
registers the 9 enforce-core hooks in `~/.claude/settings.json`.

A successful install ends with `Layer 0 Health: 5/5 elements OK`.

---

## Prompt 1 — Bootstrap a new harness project

Use this when you have a fresh project directory and want to enable harness
mode for it. Run once per project.

```text
I want to enable harness mode for the project in this directory.

1. Read ~/.claude/CLAUDE.md "§harness mode" section so you know the contract.
2. Read ~/.claude/plugins/keel-harness-mp/HARNESS_BIBLE.md — the single
   source of truth for project-level harness rules.
3. Initialize the local harness state:
   - mkdir -p .harness
   - touch .harness/state
   - cp ~/.claude/plugins/keel-harness-mp/templates/handoff-template.md \
        .harness/handoff-S0-to-S1.md
4. Confirm Layer 0 health: bash ~/.claude/plugins/keel-harness-mp/hooks/session-start-layer0-health.sh
5. Tell me what's set up and what I should do next.
```

Expected: agent reads the contract, creates `.harness/`, writes a starter
`handoff-S0-to-S1.md`, and reports Layer 0 5/5 OK before asking for the
first sprint goal.

---

## Prompt 2 — Resume an in-progress harness project

Use this when the project already has `.harness/` and you are picking up
where a previous session left off.

```text
Resume harness mode. Read the latest handoff-SN-to-SN+1.md in .harness/
and the project bible. Then run the 5-self-check (Q1-Q5) before
proposing the next action.
```

Expected: agent finds the latest `handoff-SN-to-SN+1.md`, reads
HARNESS_BIBLE.md, answers the 5 self-checks (project / next_action /
clarity / latest handoff name / current phase) literally before
proposing concrete work.

---

## Prompt 3 — Start a non-trivial multi-step plan

Use this when you have a real feature or refactor that involves three or
more steps. Triggers the agent execution standard's plan-authoring rules.

```text
I have a non-trivial task: <one-paragraph description>.

Before you write the plan, follow docs/agent-execution-standard.md:
- Read the 5 workflow MDs (pua-topology, oodc-superpower-harness-orchestration,
  superpower-pipeline, skill-loading-sop, kb-ingestion-sop)
- Verify Skill loading (5 dimensions)
- Map each plan step to its topology layer (Harness / OODC / role / Pipeline)
- Create TaskCreate entries for every Wave/Phase

Then propose the plan and ask me for ratification before executing.
```

Expected: agent reads the 5 workflow MDs, surfaces what each layer dictates
about the task, drafts a plan with explicit topology annotations, and stops
to ask for ratification (does not start writing code yet).

---

## Prompt 4 — Sprint kickoff with the 5-Layer GATE

Use this when starting a new sprint and you want the kickoff checklist
enforced.

```text
I am starting sprint S<N>. Before any work, run the 5-Layer GATE
self-check from docs/sprint-kickoff-checklist.md (Layer A entity /
B content / C gate / D config / E behavior). Paste the evidence command
output for each layer. If any layer fails, stop and tell me why before
proposing sprint scope.
```

Expected: agent runs the entity / content / gate / config / behavior
checks in order, pastes raw command output for each, and only proceeds
to scope discussion if all 5 layers pass.

---

## Prompt 5 — Closing a sprint

Use this when a sprint's work is shipped and you want a clean handoff.

```text
We are closing sprint S<N>. Spawn a Romeo audit agent
(docs/agent-execution-standard.md §4-§5) to evaluate the sprint across
the 6 dimensions (Honesty / Ownership / TechDepth / PatternReplay /
Density / Candidates). Threshold is weighted average ≥ 0.99.

If the audit fails, surface the deductions with file:line evidence and
ask me how to address each before retrying. If it passes, propose the
content of the next handoff-S<N>-to-S<N+1>.md (skeleton only — I will
fill the narrative).
```

Expected: agent dispatches a Romeo-style independent audit, returns a
score with paste evidence per dimension, and either lists rectification
items or drafts the handoff skeleton for human narrative completion.

---

## Anti-prompt — what *not* to say

Avoid prompts that ask the agent to "just do the thing" without going
through the contract. Examples that bypass harness:

- "Quickly add X feature." → bypasses plan-authoring + Skill loading
- "Fix this bug, don't bother with the audit." → bypasses Romeo gate
- "Skip the workflow reads, you've read them before." → bypasses L42 hook,
  triggers UserPromptSubmit warnings (and silently violates correctness
  guarantees)

If you find yourself wanting to bypass, the task is probably small enough
to be a `<3-step` exemption from the standard — say so explicitly:

```text
This is a small <3-step change. Inline-edit it without invoking the
agent-execution-standard. Just run the change and paste the diff.
```

---

## Where these prompts come from

The contract these prompts trigger lives in:

- `~/.claude/CLAUDE.md` — global Claude Code preferences (installed by
  `install.sh` from `templates/CLAUDE.md.global.template`)
- `<project>/CLAUDE.md` — project-level contract (installed by
  `install.sh` from `templates/CLAUDE.md.project.template`)
- `~/.claude/plugins/keel-harness-mp/HARNESS_BIBLE.md` — single source of
  truth for project-level rules
- `~/.claude/plugins/keel-harness-mp/docs/agent-execution-standard.md` —
  what the agent must do once a prompt triggers harness mode
- `~/.claude/plugins/keel-harness-mp/workflows/*.md` — the five workflow
  MDs the agent reads before any non-trivial plan

---

## Customization

You can edit `templates/CLAUDE.md.global.template` (before install) or
`~/.claude/CLAUDE.md` (after install) to add your own preferences on top
of the harness contract. The standard prompts above will still work as
long as the `§harness mode` section is intact.

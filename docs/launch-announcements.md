# Launch Announcements — v0.1.0-alpha

> Three platform drafts. Voice is engineering-pragmatic — honest about
> alpha status, no marketing fluff. Each draft is ready to copy-paste with
> light platform-specific tweaks. Final post timing is the maintainer's
> call.

---

## 1) X (Twitter) — long-form thread

Post as a thread (10 posts). Reply to the thread root, not as separate
top-level posts.

### Tweet 1 / 10 (root)

```
Shipping keel-harness v0.1.0-alpha — the infrastructure layer that
keeps Claude Code agents honest over a 24-hour session.

Open-source. Apache-2.0. macOS + Linux. One-line install.

🔗 https://github.com/mr-shaper/keel-harness

Why this matters in 9 tweets ↓
```

### Tweet 2 / 10

```
The 4 walls every team hits when using Claude Code for serious work:

1. 24h session memory loss — every new session, the AI forgets last
   sprint's decisions
2. Paper victory — claims "done" without running verification
3. P9 role drift — agents start writing code instead of orchestrating
4. Sprint score inflation — "8/8 PASS" with zero gate evidence
```

### Tweet 3 / 10

```
keel-harness fixes each wall with a concrete mechanism, not vibes:

1 → Immutable 7-field handoff schema, written at session stop, read
    at session start, enforced by hooks
2 → Canonical-honesty hooks (5-layer pre-commit + Romeo audit gate)
3 → P10-9-8-7 nested parallel agent topology with 8 iron rules
4 → Romeo 6-dimension audit framework (≥0.99 hardcore threshold)
```

### Tweet 4 / 10

```
The audit framework is the part I'm most proud of.

Romeo scores 6 dimensions on every sprint outcome:
  Honesty / Ownership / TechDepth / PatternReplay / Density / Candidates

Threshold is 0.99 weighted average. Below that, you patch and re-audit.
"Self-evaluating high without evidence" is no longer the path of least
resistance.
```

### Tweet 5 / 10

```
The hooks are the load-bearing part.

9 enforce-core hooks in v0.1.0-alpha:
  Stop / PreToolUse × 4 / PostToolUse × 2 / SessionStart /
  UserPromptSubmit

They run on every tool call. They block what should be blocked, soft-
prompt what should be soft-prompted. No vibes — explicit policy.
```

### Tweet 6 / 10

```
The four-layer execution topology you might have seen me reference:

Harness ⊃ OODC ⊃ PUA P10-9-8-7 ⊃ Superpower Pipeline

It's nested-parallel. Outer layers set context for inner layers. Each
layer is a separate workflow MD. Plans annotate which layer drives
each Wave / Phase, and TaskCreate is the live kanban.
```

### Tweet 7 / 10

```
Real numbers from this sprint cycle (S2 → S4):

- 13 commits across 4 sub-sprints
- 50+ kernel files in manifest
- 9 enforce-core hooks
- 5 mandatory workflow MDs (~926 LOC total)
- Romeo audit cycle: 0.758 → 0.96 → 0.97 → 0.99 → 0.9925
- 0 PII patterns in final git history
- DOGFOOD: Layer 0 5/5 OK on fresh CLAUDE_HOME
```

### Tweet 8 / 10

```
What it is NOT:

- Not a Claude Code replacement — it sits on top
- Not a magic productivity tool — it's discipline-enforcement
- Not opinionated about your domain — domain stays yours
- Not closed-source proprietary stack — Apache-2.0 in full

What it IS: a kernel, intentionally narrow, that you bolt onto Claude
Code to make agentic engineering enforceable instead of aspirational.
```

### Tweet 9 / 10

```
Alpha caveats (read these):

- v0.1.0-alpha — APIs may evolve before v1.0
- Tested on macOS Sonoma + Ubuntu 22.04. Windows WSL2 untested
- Requires superpowers + PUA upstream plugins (install.sh aborts if
  missing, with exact install commands printed inline)
- File an issue if anything breaks, ideally with hook-trace excerpt
```

### Tweet 10 / 10

```
If you've felt the 4 walls, fork it and try it on your next sprint:

  curl -fsSL https://raw.githubusercontent.com/mr-shaper/keel-harness/main/install.sh | bash

Discussions are open for "I tried adapting this and X happened" stories.
The roadmap has v0.2 (Compound deeper) and v0.4 (OODC complete) on the
public board.

🔗 https://github.com/mr-shaper/keel-harness
```

### Pinned visual

Attach `docs/visuals/topology-infograph.png` to tweet 1 or tweet 6
(whichever gets more engagement in the first hour).

---

## 2) HN Show — Show HN post

### Title (HN, ≤80 chars)

```
Show HN: keel-harness — discipline layer for Claude Code (Apache-2.0)
```

### URL field

```
https://github.com/mr-shaper/keel-harness
```

### Text body (HN allows long text, target ~300-400 words)

```
keel-harness is an infrastructure layer for Claude Code that turns
"agentic engineering" from aspirational vibes into enforceable
mechanisms. Apache-2.0, macOS + Linux, one-line install.

The four walls it addresses:

1. 24h session memory loss — every new session, the AI forgets last
   sprint. Fix: an immutable 7-field handoff schema written at session
   stop and read at session start, enforced by hooks.

2. Paper victory — agents claim "done" without running verification.
   Fix: canonical-honesty hooks (a 5-layer pre-commit blacklist gate +
   Romeo 6-dimension audit framework with a 0.99 weighted threshold).

3. P9 role drift — agents start writing code when they should be
   orchestrating. Fix: an explicit P10-9-8-7 nested parallel agent
   topology with 8 iron rules, hook-enforced.

4. Sprint score inflation — "8/8 PASS" with zero gate evidence. Fix:
   a 5-Layer GATE checklist (Entity / Content / Gate / Config /
   Behavior fire) and a Romeo audit that deducts for evidence-misalignment.

The kernel scope is intentionally narrow. What ships:

- 9 enforce-core hooks (Stop / PreToolUse / PostToolUse / SessionStart /
  UserPromptSubmit)
- 5 workflow MDs that an agent reads before any non-trivial plan
  (PUA topology, OODC orchestration, Superpower pipeline, Skill loading
  SOP, KB ingestion SOP)
- Romeo 6-dimension audit framework
- 5 test suites (54 tests, macOS + Ubuntu CI matrix)
- Three rendered visuals + 4 demo GIFs

What it's not:

- Not a Claude Code replacement
- Not a productivity tool
- Not opinionated about your domain
- Not closed-source

This is alpha. Tested on macOS Sonoma + Ubuntu 22.04. WSL2 untested.
Requires the superpowers + PUA upstream plugins (install.sh aborts
with exact install commands printed inline if missing).

The maintainer audit cycle that produced this release ran the Romeo
gate four times: 0.758 → 0.962 → 0.9727 → 0.9925. The repo's git
history is post-filter-repo, with zero PII patterns. CI is green on
the latest run.

Comments and adversarial issues welcome. Especially welcome: "I tried
adapting this and X broke" — those are the stories that turn an alpha
into a v1.

GitHub: https://github.com/mr-shaper/keel-harness
Roadmap (v0.2 Compound + v0.3 KB + v0.4 OODC):
  https://github.com/mr-shaper/keel-harness/blob/main/ROADMAP.md
```

---

## 3) Reddit r/ClaudeCode — release post

### Title

```
Released keel-harness v0.1.0-alpha — discipline layer for serious
agentic engineering
```

### Flair

```
Release / Tools
```

### Body

```
Just shipped v0.1.0-alpha of **keel-harness**, an Apache-2.0 layer
that sits on top of Claude Code and makes the "discipline" parts of
agentic engineering actually enforceable instead of aspirational.

**What it fixes** (the four walls every Claude Code user hits within
weeks):

| Wall | Mechanism |
|------|-----------|
| 24h session memory loss | Immutable 7-field handoff + Stop / SessionStart hooks |
| Paper victory ("I'm done!" with no evidence) | 5-layer pre-commit + Romeo 6-dim audit ≥0.99 |
| Agent role drift (P9 starts coding) | P10-9-8-7 topology + 8 iron rules, hook-enforced |
| Score inflation ("8/8 PASS, no evidence") | 5-Layer GATE checklist (A/B/C/D/E) |

**What's in the kernel**:

- 9 enforce-core hooks
- 5 workflow MDs (~926 LOC) that the agent must read before any
  non-trivial plan — failing to read trips a UserPromptSubmit warning
- Romeo audit framework (Honesty / Ownership / TechDepth / PatternReplay
  / Density / Candidates)
- 5 test suites, 54 tests, macOS + Ubuntu CI green
- 3 rendered visuals + 4 demo GIFs

**Standard prompt** (copy-paste this for any non-trivial task — it
binds the agent to the four-layer topology and prevents the most
common failure mode):

The README has the full text. Short version: read the 5 workflow MDs
before drafting, verify Skill loading is real (not stub), and every
Wave/Phase needs a TaskCreate entry.

**Install**:

```
curl -fsSL https://raw.githubusercontent.com/mr-shaper/keel-harness/main/install.sh | bash
```

**Caveats**: alpha, macOS+Linux only, requires superpowers+PUA
upstream plugins (the installer aborts with exact install commands if
missing).

GitHub: https://github.com/mr-shaper/keel-harness
ROADMAP (v0.2/0.3/0.4): in repo

Discussions are open. Especially welcome: adversarial issues — "I
tried adapting this and it broke at step X" — those stories matter
more right now than stars.
```

---

## Posting checklist (for the maintainer)

Before any post:

- [ ] Verify the GitHub URL renders cleanly without auth
- [ ] Confirm the install one-liner works on a fresh checkout
- [ ] Check the latest commit on `main` is the intended release commit
- [ ] Confirm Discussions and Issues are enabled (S3 already did this)
- [ ] Have one of the visuals (`docs/visuals/topology-infograph.png` or
      `pipeline-whiteboard.png` recommended) ready to attach where the
      platform supports images

Stagger the posts:

- HN first (Show HN — ranks better in the morning Pacific time)
- X thread within an hour of HN
- Reddit r/ClaudeCode the day after — let HN/X discussion mature first

If the HN post takes off, switch the README hero to the most-engaging
visual (currently `pipeline-whiteboard.png` — the lightest, most
engineer-friendly).

Monitor:

- GitHub Issues for first-touch problems (within 24h)
- HN comments thread (within 6h, then 24h, then 48h)
- X thread engagement in first hour determines reach
- r/ClaudeCode upvote velocity in first 2h

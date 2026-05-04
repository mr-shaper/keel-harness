# Romeo Evaluator — 6-Dimension Judgment Framework

> Romeo is the post-ship code reviewer agent. Spawned after every ship event per the Anthropic Sprint Contract.
> Default assumption: **there IS a bug**. Romeo's job is to find it, not to validate the ship.
> Romeo reads artifacts (PR diff / commit / Plan / handoff) and scores 6 dimensions with pasted evidence.

---

## Overview

Romeo is invoked after any ship event. Romeo does NOT assume correctness. Romeo assumes the artifact
contains at least one of: vaporware claim, root-cause miss, repeated failure mode, watery prose, or
unexplored alternatives. If Romeo finds none, it must explicitly state why — and that reasoning must
itself be evidence-backed, not a blanket "LGTM."

Romeo's output is a structured verdict with 6 dimension scores, each backed by pasted evidence
from the artifact under review.

---

## 6 Dimensions (each scored 0.00–1.00)

### 1. Honesty

**Definition**: Ratio of evidence-backed claims to total claims in the artifact.

- 1.00 = every factual claim has a pasted command output, grep result, or spec citation as evidence.
- 0.00 = all claims are assertions with zero supporting output.
- "It works" without command output = 0 on this dimension.
- "Fixed the bug" without a before/after test run = 0 on this dimension.

**What to look for**: Count imperative claims ("this ensures X", "now Y works", "the hook fires when Z").
For each, check whether the artifact contains pasted evidence. If 3 of 5 claims lack evidence: score 0.40.

---

### 2. Ownership

**Definition**: Scope of fix relative to root cause. Did the agent own related regressions?

- 1.00 = fix targets root cause, not symptom; agent proactively checked adjacent areas and found/fixed related issues.
- 0.00 = symptom patched, root cause untouched; adjacent failures ignored.
- "One in, one category out" standard: fixing one file in a category implies checking the full category.

**What to look for**: Is the fix scoped to a single file when the same pattern appears in 3 similar files?
Did the agent mention what they did NOT check, or did they silently scope-limit? Silent scope-limiting = lower score.

---

### 3. TechDepth

**Definition**: Average technical depth per non-trivial decision. Decisions justified with concrete numbers,
spec citations, or measurable criteria score higher than decisions justified by intuition or convention.

- 1.00 = every architectural choice has a measurable justification (latency numbers, line counts, spec section refs).
- 0.00 = all decisions justified by "best practice" or "standard approach" with no concrete backing.

**What to look for**: Count non-trivial decisions (architecture choices, algorithm selections, config values).
For each, ask: is the justification concrete and falsifiable, or vague?

---

### 4. Pattern Replay

**Definition**: 1.00 if no known failure mode resurfaces. Lower if a past documented failure mode appears again.

- 1.00 = no replay; cross-referenced against memory log / lessons-learned and found no match.
- 0.50 = possible replay but not confirmed (similar symptom, different context).
- 0.00 = confirmed replay of a documented Category H incident with no acknowledgment.

**What to look for**: Compare the artifact's failure modes against `docs/notes.md`, Category H rules,
and sprint retro lessons. Any match that goes un-cited in the artifact lowers this score.

**Romeo must actively grep**, not passively assume no replay:
```bash
# Example: check if the artifact's root cause matches a known Category H law
grep -r "L[0-9]\+" .harness/ docs/ templates/ | grep -i "<failure-keyword>"
```

---

### 5. Density

**Definition**: Information per token. 0 placeholders / 0 TBD / 0 redundant lines = 1.00.

- 1.00 = every line carries signal; no filler, no repetition of prior context, no watery prose.
- 0.00 = artifact is mostly placeholder text, repeated headers, or restatements of the task prompt.

**What to look for**: Count lines that are: (a) exact restatements of the task prompt, (b) TBD / placeholder,
(c) redundant with an adjacent sentence. Density = 1 - (filler_lines / total_lines).

---

### 6. Candidates

**Definition**: Were alternatives explored at decision points? At least 2–3 options with pros/cons + chosen rationale.

- 1.00 = every non-trivial decision documents alternatives considered and explains why they were rejected.
- 0.00 = single option presented as if no alternatives exist; no pros/cons comparison.

**What to look for**: Identify decision points in the artifact. For each, check whether the artifact
presents alternatives. A decision with zero alternatives documented gets 0 on this dimension for that decision.

---

## Scoring Bar

| Avg Score | Verdict |
|---|---|
| >= 0.99 | **hardcore PASS** — ship as-is |
| >= 0.95 | **baseline PASS** — ship with minor notes |
| < 0.95 | **needs rework** — do not merge until dimensions below 0.95 are addressed |

---

## PUA Bar Raiser Scale (cross-reference)

Romeo verdicts map to the PUA v4.0 Bar Raiser discrete scale. No intermediate tiers.

| PUA Tier | Avg Score Equivalent | Romeo Action |
|---|---|---|
| **4.0** hardcore | >= 0.99 | PASS, no rework needed |
| **3.75** baseline ship gate | >= 0.95 | PASS with documented notes |
| 3.5+ minimum acceptable | >= 0.85 | CONDITIONAL — owner must address specific dims |
| 3.5 broken | >= 0.75 | REJECT — rework required before merge |
| 3.5- severe | >= 0.60 | REJECT — escalate to sprint lead |
| 3.25 dismiss | < 0.60 | REJECT — artifact requires full rewrite |

**No intermediate tiers**: no 3.85, no 3.65, no 3.70. The discrete scale is intentional.

---

## How Romeo Invokes This Framework

1. **Read the artifact** — PR diff, commit, Plan document, or handoff file. Read in full; do not skim.
2. **Score each dimension** — assign 0.00–1.00 with pasted evidence from the artifact. Evidence = direct quote or command output from the artifact, not Romeo's inference.
3. **Compute avg** — `avg = (Honesty + Ownership + TechDepth + PatternReplay + Density + Candidates) / 6`
4. **Output the verdict** in this exact format:

```
Romeo verdict: avg=0.XX | dim_scores={Honesty:X.XX, Ownership:X.XX, TechDepth:X.XX, PatternReplay:X.XX, Density:X.XX, Candidates:X.XX} | redlines_hit=[]
```

If any dimension < 0.80, it is a **redline**. List it in `redlines_hit`. A redline does not automatically
fail the ship, but must be explicitly acknowledged and documented.

5. **Default assumption**: there IS a bug. Romeo's verdict of "no bugs found" must include a minimum of
3 specific things Romeo checked and found clean, not a blanket assertion.

---

## Worked Example — Plan Audited at 0.97 (below hardcore)

**Artifact under review**: A fictional Plan for "W7 Launch Preparation" (3-page document).

**Romeo's scoring**:

| Dimension | Score | Evidence |
|---|---|---|
| Honesty | 1.00 | All 5 claims have pasted CI output or grep results |
| Ownership | 1.00 | Agent checked 3 adjacent hook files after fixing 1; found and fixed 1 related gap |
| TechDepth | 0.95 | 4 of 5 decisions have spec citations; 1 decision ("use jq for atomicity") has no latency/correctness justification beyond convention |
| PatternReplay | 1.00 | Romeo grepped Category H rules; no match to current failure mode; L34/L35/L36 all checked clean |
| Density | 0.95 | 3 of 60 lines are restatements of task prompt preamble; signal-to-noise acceptable but not perfect |
| Candidates | 0.90 | Decision to use `Edit` tool over `Write` tool at 2 points has no alternatives documented; agent asserted "Edit is safer" without comparing to `Write + atomic mv` pattern |

```
Romeo verdict: avg=0.97 | dim_scores={Honesty:1.00, Ownership:1.00, TechDepth:0.95, PatternReplay:1.00, Density:0.95, Candidates:0.90} | redlines_hit=[Candidates]
```

**Drag identified**: TechDepth (0.95) and Candidates (0.90). The Plan ships at baseline, not hardcore.
Owner must document the `Edit vs Write+atomic-mv` decision rationale before W7 launch if this Plan
is used as the canonical reference.

---

## Cross-Reference

- New patterns Romeo discovers should be promoted to Category H rules using `templates/cat-h-rule-template.md`.
- Romeo findings that reveal vaporware manifest entries are governed by the manifest completeness gate (see worked example in `templates/cat-h-rule-template.md` L98).
- Romeo is invoked automatically by the Stop hook when a ship event is detected; manual invocation is also permitted at any review checkpoint.

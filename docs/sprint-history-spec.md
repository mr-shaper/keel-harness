# Sprint history spec

> Single-file partition convention for `.harness/sprint-history/`. Used in
> conjunction with the `BACKBONE-FROZEN` size contract on `PROJECT_STATE.md`
> (see `docs/r15-and-l44-candidate.md`).

## Purpose

`PROJECT_STATE.md` is the live backbone of a harness project. Over a long-
running project it accumulates decision detail across many sprints; without
discipline it bloats past readability and the file becomes a tar pit. The
sprint-history convention preserves that detail without keeping it in the
backbone: each sprint's section moves into its own file once the sprint is
sealed.

## Directory layout

```
.harness/
├── PROJECT_STATE.md           # backbone, ≤200 LOC, alert at 180
├── sprint-history/
│   ├── README.md              # index table
│   ├── sha256sums.txt         # integrity record
│   ├── s0-kickoff.md
│   ├── s1-mvp.md
│   ├── s2-public-readiness.md
│   ├── ...
│   └── sNN-<topic-slug>.md
└── handoff-sN-to-sN+1.md
```

## File-name convention

```
sNN-<topic-slug>.md
```

- `sNN`: zero-padded sprint number (s0, s1, …, s47, s48).
- `<topic-slug>`: kebab-case, ≤6 words, summarises the sprint's outcome
  rather than its kickoff topic. Example: `s47-context-aware-handoff` (the
  feature that landed), not `s47-handoff-decision-rounds` (the process).

## Frontmatter template

Every sprint file begins with:

```markdown
---
sprint: sNN
ship_date: YYYY-MM-DD
source: PROJECT_STATE.md.bak-pre-sN-collapse-<timestamp>
section_title: §<original section heading copied from PROJECT_STATE>
---

# sNN — <Topic title>

(body: copied from the corresponding PROJECT_STATE section, then deleted from
the backbone)
```

The `source` field records which PROJECT_STATE backup the section was
collapsed from, so the move is auditable.

## Integrity: `sha256sums.txt`

After a collapse, run:

```bash
cd .harness/sprint-history
shasum -a 256 s*.md > sha256sums.txt
```

`shasum -a 256 -c sha256sums.txt` then verifies the partition has not been
silently edited.

## README index

`.harness/sprint-history/README.md` is a one-table index — the cheap
substitute for full-text search:

```markdown
# Sprint history index

| Sprint | Topic | File |
|--------|-------|------|
| s0  | kickoff | s0-kickoff.md |
| s1  | MVP | s1-mvp.md |
| ... | ... | ... |
```

Updated by hand whenever a new sprint file is added.

## Workflow: when to collapse

The size-gate hook (`hooks/post-tool-project-state-size-gate.sh`) fires
`[SIZE-GATE-ALERT]` at 180 LOC. When that alert appears:

1. Identify the oldest sprint section in `PROJECT_STATE.md` that is fully
   sealed (no still-live decisions).
2. `cp PROJECT_STATE.md PROJECT_STATE.md.bak-pre-sN-collapse-$(date +%s)`.
3. Cut that section from `PROJECT_STATE.md` into a new
   `sprint-history/sNN-<topic-slug>.md` with the frontmatter template.
4. Update `sprint-history/README.md` with a new row.
5. Refresh `sprint-history/sha256sums.txt`.
6. Re-check `wc -l PROJECT_STATE.md` < 180 — if not, repeat with the next
   oldest section.

This is a manual workflow today. The hook only alerts; it does not move
content automatically. Automating the collapse is in the v0.2 roadmap.

## Cross-reference

- Hook: `hooks/post-tool-project-state-size-gate.sh`
- Backbone template: `templates/PROJECT_STATE.md.template`
- Three-piece pattern: `docs/r15-and-l44-candidate.md` (R15 + L44 candidate)

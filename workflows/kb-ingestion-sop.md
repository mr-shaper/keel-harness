---
type: workflow
domain: ai-systems
name: Knowledge Base Ingestion SOP (doc-sync skill main entry)
description: Any KB ingest/extract/query MUST go through the doc-sync skill main entry. Bare kb.py calls are forbidden. v1.11.2 hotfix cross-session permanent law.
created: 2026-04-29
confidence: 0.8
stale: false
last_ingested: 2026-04-30T02:51:32Z
---

# Knowledge Base Ingestion SOP

> v1.11.2 hotfix ratified. Cross-session permanent law. Any P9/P8 KB operation must follow this SOP.

## §1 Mandatory Law (v1.11.2 ship)

**Single entry point**:
```bash
bash ~/.claude/skills/shelf/doc-sync/scripts/kb-ingest-compile.sh <path> <domain> [--hint <decision|exemplar|analogy|evolution>]
```

**3 Prohibitions**:
- ❌ Bare `python3 ~/.claude/plugins/tacit-kb/scripts/kb.py ingest <path>` — skips compound-selfcheck three-iron-laws + frontmatter injection + compile-hint
- ❌ Bare `kb.py extract --type X --write` bypasses doc-sync routing layer — no fingerprint + no routes.md + no audit
- ❌ Writing directly to `~/.claude/plugins/tacit-kb/raw/` — bypasses the entire pipeline (**Note**: this path is used only as a **prohibition example; the whole directory does not exist**. True vault_root: see §10 NEW)

**Cost of violation** (v1.11.2 real evidence):
- D1+D6 first attempt with bare `kb.py ingest` → missed three-iron-law PASS / missed frontmatter injection / missed compile-hint = **Compound triggers as performance, not reality**
- Redo via `kb-ingest-compile.sh` achieves true closed-loop ([COMPOUND-PASS] all three iron laws pass)

## §2 KB Routing 3-Layer Architecture

```
SKILL layer (doc-sync, single entry point)
    │
    └─ scripts/
        ├─ docsyn-state.sh fingerprint     ← Step 2: infer change_type
        ├─ kb-ingest-compile.sh             ← main entry
        ├─ kb-audit.sh                      ← Step 5: audit
        ├─ compound-selfcheck.sh            ← three-iron-law check
        └─ contract-check.sh
        │
        ├─ references/
        │   └─ routes.md                    ← Step 3: routing table
        │
        └─ internally calls BACKEND layer (tacit-kb)
            │
            └─ kb.py
                ├─ ingest <path>            ← skill-internal use only
                ├─ compile --all            ← LLM step (deferred)
                ├─ query <text>             ← query KB
                ├─ wakeup                   ← SessionStart auto-inject
                └─ extract --type X --write ← special scenarios only

PLUGIN HOOK layer (compound-selfcheck-plugin v0.1.1)
    │
    └─ PostToolUse Write/Edit/MultiEdit/NotebookEdit
        │
        └─ LOC>100 OR BYTES>5000 auto stderr three-iron-law reminder 21-line frame
```

## §3 doc-sync skill 6-step process

| Step | Action | Tool |
|------|--------|------|
| 1 | Read state | `.docsyn-touched-{project}` state file, get change summary |
| 2 | Infer change_type | `scripts/docsyn-state.sh fingerprint` → one of 6 types |
| 3 | Look up routing rules | Open `references/routes.md`, read: archive target / KB action / output_hint |
| 4 | Execute routing rules | Run archive steps in parallel per routes.md. See `tiers.md` for details |
| 5 | KB feed + audit | `kb-ingest-compile.sh` + `kb-audit.sh`. `qa_archive` type follows `ingest-guide.md`. Self-check via `compound-checklist.md` |
| 6 | Output dispatch | Read routes.md output_hint: drawio / ljg / content / none |

## §4 6 change_type Routing Table

| change_type | Primary archive target | KB action | Wiki archive | output_hint |
|-------------|----------------------|------------|--------------|-------------|
| `bug_fix` | SELFCHANGELOG only | ingest+compile | No | none |
| `arch_upgrade` | DOC_GUIDE + upgrade-records + AI-systems README | ingest+compile+hint decision | Yes | drawio |
| `new_skill` | skill-engineering + README + SELFCHANGELOG | ingest+compile | Yes | none |
| `research` | research-reports + unified content index | ingest+compile+hint exemplar/analogy | Yes | content |
| `methodology` | skill-library + KB patterns | ingest+compile+hint decision | Yes | ljg |
| `qa_archive` (v3 NEW) | raw/notes/ + wiki concepts | ingest+compile | No | none |

**Permanent law**: Do not proactively archive to the team Wiki. Even if routes.md marks "Wiki: Yes", skip the Wiki step unless explicitly directed.

## §5 ingest command format + v1.11.2 real evidence

### Standard command
```bash
bash ~/.claude/skills/shelf/doc-sync/scripts/kb-ingest-compile.sh <path> <domain> [--hint <decision|exemplar|analogy|evolution>]
```

### v1.11.2 real evidence
```bash
# D1 architecture MD (arch_upgrade)
bash ~/.claude/skills/shelf/doc-sync/scripts/kb-ingest-compile.sh \
  "$ICLOUD_BASE/AI/Claude/05-skill-library/AI-systems/knowledge-base/wiki/ai-systems/concepts/claude-code-hierarchical-architecture.md" \
  ai-systems --hint decision

# Real output:
# [compound-selfcheck] [COMPOUND-OK] iron-law(a): frontmatter exists
# [compound-selfcheck] [COMPOUND-OK] iron-law(b): new file, first ingest (compound starting point)
# [compound-selfcheck] [COMPOUND-OK] iron-law(c): domain='ai-systems' valid
# [compound-selfcheck] [COMPOUND-PASS] all three iron laws pass
# [KB-FM] frontmatter injected (1 fields): ...
# ✅ Ingested: claude-code-hierarchical-architecture
#    domain: ai-systems
#    path: raw/ai-systems/claude-code-hierarchical-architecture.md
#    tags: docsyn-auto
# [KB-OK] ingested: ... → domain: ai-systems
# [KB-COMPILE-HINT] 116 raw entries not yet compiled (including the one just ingested ...)

# D6 KB decision (arch_upgrade)
bash ~/.claude/skills/shelf/doc-sync/scripts/kb-ingest-compile.sh \
  ".../knowledge-base/patterns/decisions/2026-04-29-v1-11-2-k12-live-evidence-l36-handoff-gate-bug.md" \
  ai-systems --hint decision
```

## §6 Compound Three Iron Laws (compound-selfcheck.sh)

PostToolUse Write/Edit/MultiEdit/NotebookEdit, LOC>100 OR BYTES>5000 auto stderr 21-line frame reminder:

| Iron Law | Check | PASS condition |
|----------|-------|----------------|
| (a) | frontmatter exists | file contains `---` ... `---` block with type/domain/name/description |
| (b) | new file, first ingest (compound starting point) | file not in raw/ already-ingested list |
| (c) | domain is valid | domain ∈ {ai-systems, business-vertical, skills, quant, content, general} |

**Real trigger vs. performance — how to judge**:
- ❌ AI saying "Compound opportunity / I'll help you extract / let's consolidate a template" = **0 value, performance**
- ✅ Real trigger evidence: `.harness/hook-trace.log` contains `[COMPOUND-CHECK]` entry **OR** KB `patterns/decisions/` has a new file **OR** `kb.py query` returns a hit

## §7 Cross-session wakeup auto-context

### SessionStart auto-inject (configured in CLAUDE.md)
```bash
python3 ~/.claude/plugins/tacit-kb/scripts/kb.py wakeup
```

- 72h cache (cross-session persistent)
- Injects: cognitive patterns + role recognition + last 6 decisions
- Output format: `[domain] N judgments: title1, title2, ...`

### compile is an LLM step (deferred, not automatic)
```bash
# Step 1: list uncompiled entries
kb compile --all
# Output: 117 raw entries not compiled

# Step 2: prepare prompt
kb compile --prepare <slug>

# Step 3: LLM generates summary + concepts (manual AI step)

# Step 4: write results
kb compile --write --source <slug> --summary <json> --concepts <json>
```

There is always a lag between raw and compiled (117 raw uncompiled in the sprint that documented this). v1.12 R8 backlog: staged compile reminder hook.

## §8 query usage + domain routing

### Command
```bash
python3 ~/.claude/plugins/tacit-kb/scripts/kb.py query "keyword" --domain <domain> --top 3
```

### Domain routing (inlined in CLAUDE.md)
| domain | Use cases |
|--------|-----------|
| ai-systems | AI / plugin / harness / docsyn |
| business-vertical | Domain-specific business logic (e.g., logistics / fintech / e-commerce) |
| skills | skill tool selection / plantuml |
| quant | quant / DCA / backtesting |
| content | content creation / social media / video scripts |
| general | cross-domain / engineering principles |

## §9 v1.11.2 real evidence (bare kb.py wrong-path lessons)

### First mistake (s36 P9)
```bash
# ❌ bare kb.py ingest (skips three iron laws)
python3 ~/.claude/plugins/tacit-kb/scripts/kb.py ingest "$D1" --domain ai-systems --title "..."
```

Output:
```
✅ Ingested: ...
   path: raw/ai-systems/claude-code-4-a70bb55e.md
```

But: skipped compound-selfcheck PASS / skipped frontmatter injection / no KB-COMPILE-HINT.

### Redo via skill main entry (s36 P9 correction)
```bash
# ✅ doc-sync skill single entry point
bash ~/.claude/skills/shelf/doc-sync/scripts/kb-ingest-compile.sh "$D1" ai-systems --hint decision
```

Output (true closed-loop evidence):
```
[compound-selfcheck] [COMPOUND-OK] iron-law(a): frontmatter exists
[compound-selfcheck] [COMPOUND-OK] iron-law(b): new file, first ingest
[compound-selfcheck] [COMPOUND-OK] iron-law(c): domain='ai-systems' valid
[compound-selfcheck] [COMPOUND-PASS] all three iron laws pass
[KB-FM] frontmatter injected
✅ Ingested: claude-code-hierarchical-architecture
[KB-COMPILE-HINT] 117 raw entries not compiled
```

### Compound 4 source-of-truth burn-in
1. `~/.claude/CLAUDE.md` v1.11.2 hotfix mandatory law section
2. `$ICLOUD_BASE/AI/Claude/CLAUDE.md` dual-path md5 same-source 525ccce2b6dcedc35f737ac730b4013c
3. `feedback_kb_ingest_via_doc_sync_skill_only.md` cross-session permanent (Claude-Mem auto-load)
4. This SOP `~/.claude/workflows/kb-ingestion-sop.md` (Read when workflow is triggered)

### v1.12 R9 backlog (physical enforcement)
PreToolUse hook intercepts bare `kb.py ingest <path>` calls (matcher: Bash + grep 'kb.py ingest'), forcing use of `kb-ingest-compile.sh`. Not relying on AI self-discipline.

## §Quick Decision Tree

```
Need to ingest a file?
   │
   ├─ File already has frontmatter? → run kb-ingest-compile.sh (three iron laws PASS)
   │
   ├─ File has no frontmatter? → Edit to add frontmatter first (type/domain/name/description/created), then ingest
   │
   └─ Unsure of change_type? → docsyn-state.sh fingerprint → check output to select hint

Need to query KB?
   │
   ├─ Know the domain? → kb.py query "keyword" --domain <domain> --top 3
   │
   └─ Don't know the domain? → try ai-systems first (default for cross-plugin/harness/skill work)

Need to compile (raw → vector)?
   │
   └─ This is an LLM step, deferred. SessionStart wakeup uses cache. Tracked in v1.12 R8.
```

## §10 True vault_root path (anti-recurrence law for P9 path assumptions)

**True vault_root** (kb-ingest-compile.sh line 64 canonical source + kb.py KB_DIR default):

```
$ICLOUD_BASE/AI/Claude/knowledge-base/raw/<domain>/
```

**Shorthand**: `iCloud/knowledge-base/raw/<domain>/` (synced via iCloud, shared cross-machine)

**7 domain ground truth** (kb.py DOMAINS canonical, verified by ls):
- `ai-systems/` — AI / plugin / harness / docsyn (47 entries 1.5M)
- `business-vertical/` — Business-specific verticals
- `content/` — content creation / social media / video scripts
- `general/` — cross-domain / engineering principles
- `quant/` — quant / DCA / backtesting
- `short-drama/` — short drama
- `skills/` — skill tool selection / plantuml

**Verify the true path (required before any RCA)**:
```bash
# Command 1: vault_root literal in kb-ingest-compile.sh
grep -nE "vault_root|KB_DIR" ~/.claude/skills/shelf/doc-sync/scripts/kb-ingest-compile.sh

# Command 2: kb.py KB_DIR ground truth
grep -nE "KB_DIR" ~/.claude/plugins/tacit-kb/scripts/cmd_helpers.py

# Command 3: physical ls of 7 domains
ls -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs/AI/Claude/knowledge-base/raw/"*/
```

**Forbidden anti-pattern paths** (historical P9 wrong assumptions, **entire directories do not exist**):

- `~/.claude/plugins/tacit-kb/raw/` ❌ — The `~/.claude/plugins/tacit-kb/` directory does not contain a `raw/` subdirectory; it has only 8 items (.pytest_cache / data / references / scripts / SKILL.md / templates / tests)
- Any `raw/` assumption under a plugin install directory ❌

**Historical recurrence evidence (Cat-H candidate, freeze-period reference)**:
- s38 SELFCHANGELOG line 212 (historical P9 wrote wrong path)
- s42 P9 RCA same class of error (7-source verify used wrong path, first round misidentified as 100% fact drift)
- Anti-recurrence fix: whenever documenting a KB path example, always give the true vault_root explicitly alongside it (this §10 is the first instance of that fix being applied)

## §Companion Resources

- doc-sync SKILL: `~/.claude/skills/shelf/doc-sync/SKILL.md`
- routes.md: `~/.claude/skills/shelf/doc-sync/references/routes.md`
- kb.py: `~/.claude/plugins/tacit-kb/scripts/kb.py`
- compound-selfcheck-plugin: `~/.claude/plugins/compound-selfcheck-plugin/`
- feedback memory: `~/.claude/projects/.../memory/feedback_kb_ingest_via_doc_sync_skill_only.md`

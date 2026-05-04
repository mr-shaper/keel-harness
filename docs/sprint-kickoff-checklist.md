---
type: checklist
domain: sprint-ops
created: 2026-05-03
version: 1.0.0
---

# Sprint Kickoff Checklist — 5-Layer GATE

> Universal self-check template for OSS sprint kickoff. Prevents P9 score inflation and ensures
> cross-scenario compatibility. Based on mini main host retro §5 Lesson 1: 8/8 PASS reported as
> 3.85 but GATE dimensions were never evidenced.

---

## §1 Purpose

Run this checklist at every sprint kickoff to verify the harness is wired correctly across
5 dimensions (entity / content / GATE / config / behavior-fire) before declaring any sprint
work valid. Every dimension must produce pasted evidence — assertion alone fails.

---

## §2 When to Run

- **Sprint kickoff** (first session of a new sprint Wave or Phase)
- **After any hook/plugin/settings change** before resuming sprint work
- **After `git pull` or environment reset** on a fresh machine
- **Whenever P9 calls "GATE check"** in a task prompt

---

## §3 Five-Layer GATE Self-Check

> **Setup:** Set `HARNESS_ROOT` to your harness install path before running any
> command in this section. Example:
> ```bash
> export HARNESS_ROOT="${HARNESS_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
> ```
> All commands below use `${HARNESS_ROOT}` so they are portable across install
> locations (e.g., `~/.claude/plugins/keel-harness-mp/` for an OSS install or
> `~/dev/your-harness-clone/` for a development checkout).

### Layer A — Entity (Files / Dirs / Binaries Exist)

Verify that all required scripts, plugin directories, and settings files are physically present.

| Item | Command | PASS Evidence |
|------|---------|--------------|
| Hook scripts exist | `ls ${HARNESS_ROOT}/hooks/` | Expected `.sh` files listed |
| Plugin directories present | `ls ${HARNESS_ROOT}/plugins/` | Plugin subdirs visible |
| Settings file present | `ls ${HARNESS_ROOT}/.claude/settings.json` | File path printed |
| Manifest present | `ls ${HARNESS_ROOT}/manifest.json` | File path printed |

**Evidence command example:**
```bash
ls ${HARNESS_ROOT}/hooks/ && ls ${HARNESS_ROOT}/plugins/
```

---

### Layer B — Content (File Content Integrity)

Verify file contents match expectations: correct line counts, required keywords present.

| Item | Command | PASS Evidence |
|------|---------|--------------|
| Hook script non-empty | `wc -l ${HARNESS_ROOT}/hooks/<hook>.sh` | `≥10` lines |
| Manifest has entries | `grep -c '"name"' ${HARNESS_ROOT}/manifest.json` | `≥1` |
| HARNESS_BIBLE.md Layer 0 present | `grep -c "Layer 0" ${HARNESS_ROOT}/HARNESS_BIBLE.md` | `≥1` |
| Settings contains hooks key | `grep -c '"hooks"' ${HARNESS_ROOT}/.claude/settings.json` | `≥1` |

**Evidence command example:**
```bash
wc -l ${HARNESS_ROOT}/hooks/*.sh
grep -c '"name"' ${HARNESS_ROOT}/manifest.json
```

---

### Layer C — GATE (Hook Registration / Matcher / Event Type)

Verify hooks are registered with correct event types and matchers — not just files, but wired.

| Item | Command | PASS Evidence |
|------|---------|--------------|
| Hook event types present | `grep -E '"event_type"|"matcher"' ${HARNESS_ROOT}/.claude/settings.json` | Correct event names shown |
| Stop hook registered | `grep -c "Stop" ${HARNESS_ROOT}/.claude/settings.json` | `≥1` |
| PreToolUse hook registered | `grep -c "PreToolUse" ${HARNESS_ROOT}/.claude/settings.json` | `≥1` |
| Hook matchers not empty | `python3 -c "import json,sys; d=json.load(open('${HARNESS_ROOT}/.claude/settings.json'.replace('~', __import__('os').path.expanduser('~')))); hooks=d.get('hooks',{}); print(len(hooks))"` | `≥1` |

**Evidence command example:**
```bash
grep -E '"event_type"|"matcher"|"Stop"|"PreToolUse"' ${HARNESS_ROOT}/.claude/settings.json
```

---

### Layer D — Config (Env Vars / Settings Fields / Metadata)

Verify environment variables, settings.json fields, and plugin metadata are correctly set.

| Item | Command | PASS Evidence |
|------|---------|--------------|
| Plugin metadata present | `grep -c '"version"' ${HARNESS_ROOT}/plugins/*/plugin.json` | `≥1` per plugin |
| HARNESS_BIBLE version field | `grep -m1 "version" ${HARNESS_ROOT}/HARNESS_BIBLE.md` | Version string visible |
| Manifest version field | `python3 -c "import json; d=json.load(open('$(eval echo ${HARNESS_ROOT}/manifest.json)')); print(d.get('version','MISSING'))"` | Non-empty version |
| State file present (if active session) | `cat ${HARNESS_ROOT}/.harness/state` | Session state content |

**Evidence command example:**
```bash
grep -r '"version"' ${HARNESS_ROOT}/plugins/ | head -5
cat ${HARNESS_ROOT}/.harness/state 2>/dev/null || echo "no active session"
```

---

### Layer E — Behavior Fire (Hook Trace / Real Live Fire Count)

Verify hooks have actually fired in this session — trace log entries, not just registration claims.

| Item | Command | PASS Evidence |
|------|---------|--------------|
| Hook trace log exists | `ls ${HARNESS_ROOT}/.harness/hook-trace.log` | File path printed |
| Stop hook fired this session | `grep -c "Stop" ${HARNESS_ROOT}/.harness/hook-trace.log` | `≥1` entry |
| Compound check fired | `grep -c "COMPOUND-CHECK" ${HARNESS_ROOT}/.harness/hook-trace.log` | `≥1` (if LOC>100 write occurred) |
| Latest hook fire timestamp | `tail -n5 ${HARNESS_ROOT}/.harness/hook-trace.log` | Recent timestamps visible |

**Evidence command example:**
```bash
tail -n10 ${HARNESS_ROOT}/.harness/hook-trace.log
grep -cE "Stop|PreToolUse|PostToolUse" ${HARNESS_ROOT}/.harness/hook-trace.log
```

---

## §4 Quick Reference Card

| Layer | What to Check | Command | PASS Evidence |
|-------|--------------|---------|--------------|
| **A Entity** | Scripts / dirs / files exist | `ls hooks/ plugins/ .claude/settings.json` | All paths resolve |
| **B Content** | Line count / keyword grep | `wc -l hooks/*.sh && grep -c '"name"' manifest.json` | ≥10 lines, ≥1 hit |
| **C GATE** | Hook registration wired | `grep -E '"Stop"\|"PreToolUse"' .claude/settings.json` | ≥1 per event |
| **D Config** | Plugin metadata / version | `grep -r '"version"' plugins/` | Non-empty per plugin |
| **E Behavior** | Trace log real fire count | `tail -n10 .harness/hook-trace.log` | Recent entries visible |

> All commands assume `${HARNESS_ROOT}` is set (see §3 setup block).

---

## §5 Penalty for Missing Any Layer

- **Any Layer skipped** → sprint GATE invalid → **drops below 3.75 baseline** → L3 review triggered
- Reporting "PASS" without pasted evidence = Layer A-E all failed (red-line one: no evidence = self-hype)
- A score ≥ 3.75 with unverified GATE dimensions = 3.25 signal (red-line four: self-eval must align to evidence)
- P9 aggregating sub-agent reports without re-verifying GATE = **role violation** (P9 does not write code; P9 also does not accept unverified claims)

**Recovery**: Paste command output for each failing Layer before resuming sprint work. No exceptions.

---

## §6 References

- `audit/romeo-6-dim-framework.md` — 6-dimension scoring framework (Honesty / Completeness / Root-Cause / Alternatives / Prose / Evidence-Chain)
- `HARNESS_BIBLE.md` — L31: CLAUDE.md revisions require 6-dim ≥0.99 hardcore cross-session permanent
- `HARNESS_BIBLE.md` — Category H 16 hooks canonical list (L16-L37)
- `HARNESS_BIBLE.md §0.1` — Layer 0 five-element iron rule (a/b/c/d/e — missing one = silent dead)

---
name: oodc
description: >
  Use when starting a new project (Skill/MCP/WebApp/CLI/Library/APP) that is novel
  to this ecosystem — first-time domain, upstream dependency, or deep research needed.
  Use when user says "OODC" / "oodc mode" / "full research first" / "research first" /
  "deep research" / "observe orient decide create". Complements superpower-pipeline (slots into Phase 1-2).
  NOT for refactors of existing projects. NOT for small CLIs in familiar tech.
---

# OODC — Observe → Orient → Decide → Create

KB: `python3 ~/.claude/plugins/tacit-kb/scripts/kb.py`
Slow-loop: `.oodc-state-{project}` blocks Write/Edit until CREATE. Read `~/.claude/workflows/oodc-loop.md`.

## Mode

Ask user: **"Fast or slow?"**
- **Slow**: new domain / upstream / "deep research". Run: `Bash: echo -e "step=OBSERVE\nproject={name}\nstarted=$(date -u +%FT%TZ)" > ~/.claude/.oodc-state-{name}`
- **Fast**: familiar domain. No state file.

## OBSERVE

Tool routing: `web-access`=GitHub / `bird`=X / `notebooklm`=NLM. Details: `references/observe-protocol.md`.

**Slow**: 3 parallel Agents. NLM: notebook → ≥30 sources → 6 Q&A.

**Fast**: Run these commands:
1. `Bash: python3 ~/.claude/plugins/tacit-kb/scripts/kb.py wakeup --tokens 400`
2. `Bash: python3 ~/.claude/plugins/tacit-kb/scripts/kb.py query "{project_keywords}" --domain {domain} --top 3` (requires `tacit-kb` plugin — optional)
3. `Bash: ls ~/.claude/skills/shelf/ | head -20`
4. Read related local doc directories

NLM answers only. Down → `[⚠️ non-NLM]`.

**Required Output [OBSERVE_RESULT]**:
`github:` {findings} | `x:` {insights} | `nlm:` {Q&A} | `local:` {assets} | `source_count:` N

Done = source_count ≥ 3 (fast) / ≥ 20 (slow). Each field: concrete finding, not "no results".
Empty field (slow) → do not proceed. Slow: `Bash: perl -pi -e 's/step=.*/step=ORIENT/' ~/.claude/.oodc-state-{project}`

## ORIENT

See `references/orient-playbook.md`.

1. **Assumptions**: 3 × (text / evidence / counter / confidence)
2. **Experts**: Use **Skill tool** — NOT text mention, TOOL CALL.
   Run: `Skill tool, skill name = "{perspective-name}"` (e.g. feynman-perspective). Cap: 4.
   Fallback if Skill fails: `Bash: head -40 ~/.claude/skills/{name}/SKILL.md` + `[⚠️ fallback]`
3. **PUA**: Run: `Skill tool, skill name = "pua:p10"` — apply three questions.

**Required Output [ORIENT_VERDICT]**:
`assumptions:` [...] | `experts_invoked:` [Skill IDs] | `pua:` flavor/pressure/redlines/switch | `pipeline_phases:` [...] | `dominant:` ... | `minority:` ... | `recommendation:` ... | `confidence:` H/M/L

Done = experts_invoked: ≥1 Skill call with verdict. assumptions: ≥1 confidence ≠ High.
`experts_invoked` empty → do not proceed. Slow: `perl -pi -e 's/step=.*/step=DECIDE/' ~/.claude/.oodc-state-{project}`

**Fast-loop minimum** (non-negotiable):
- Assumptions: 3 × evidence/counter/confidence
- PUA: 4 params (flavor/pressure/redlines/switch), tag `[⚠️ fast]`
- Experts: ≥1 `Skill tool` call OR inline with framework + `[⚠️ fast]`
- Pipeline: which Superpowers Phases apply

## DECIDE

See `references/decide-template.md`.

1. **Five elements**: name / abstraction / stack / topology / upstream
2. **3-4 decisions**: options × tradeoffs × recommendation
3. **Self-audit**: Plan numbers/phases consistent
4. **Present** to user

**Required Output [DECIDE_LOCK]**:
`five_elements:` {...} | `decisions:` [DP-1..N] | `consistency:` PASS/FAIL | `user_confirmed:` false

Done = consistency: PASS (top numbers = bottom counts). user_confirmed: true.
**HARD STOP**: Wait for user. Slow: `perl -pi -e 's/step=.*/step=CREATE/' ~/.claude/.oodc-state-{project}`

## CREATE

See `references/create-protocol.md`.

1. **RED**: 5 pressure tests without skill → record failures
2. **GREEN**: Minimal fix for observed failures
3. **REFACTOR**: Knowledge injection + loopholes + validation
4. **KB** (MANDATORY): Run: `Bash: python3 ~/.claude/plugins/tacit-kb/scripts/kb.py extract --type decision --domain {domain} --write --data '{...}'` — paste output
5. **Memory log** (MANDATORY): AI drafts → the user approves/skips — show draft

**Required Output [CLOSURE_EVIDENCE]**:
`tests:` {paste stdout} | `wordcount:` {paste wc -w} | `kb:` {paste kb.py output} | `docsync:` {paste files}

Done = tests: paste 5 RED stdout. kb: paste kb.py output. Verify: `Bash: wc -w` + `Bash: kb.py status | head -3`
"all passed" claim without pasted output = INVALID. Expert review: 1-2 Skill calls.
Cleanup: `Bash: rm ~/.claude/.oodc-state-{project}`

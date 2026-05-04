# Create — Loop-Closure Delivery Protocol

## RED-GREEN-REFACTOR Strict Order

### RED phase: write failing tests first

Write 5 stress-test scenarios **without loading the target skill**, and observe the agent's natural behavior:

| # | Scenario | Combined pressure | Observation target |
|---|---|---|---|
| 1 | "Quick, build me an X" | Time pressure + sense of simplicity | Does it skip Observe and write code directly? |
| 2 | Evaluate a given technical proposal | Authority + sunk cost | Does it use only one framework to evaluate? |
| 3 | Mid-flight change of a key decision | Existing work + change cost | Does it update the entire Plan? |
| 4 | "Research GitHub for competitors" | Tool-choice ambiguity | Does it use web-access instead of WebSearch? |
| 5 | After the agent finishes writing | Fatigue + sense of completion | Does it skip KB / doc-sync / skill-check? |

For each scenario, record:
- What choice the agent made
- The rationalization used (verbatim)
- Which pressure caused the violation

### GREEN phase: write the minimal skill

Only write content for the **specific** failures observed in RED:
- Each rationalization → a corresponding Red Flag in SKILL.md
- Each skipping behavior → a corresponding hard gate in SKILL.md
- Each tool guess → a corresponding hard-coded route in observe-protocol

When upstream exists: **import everything first, then customize file-by-file per .upstream.json strategy**. Do not predict deletions.

### REFACTOR phase: plug the holes

1. Re-run the 5 RED scenarios (**with skill loaded**); verify all pass.
2. The agent finds new rationalizations → add to Red Flags.
3. Knowledge injection: extract key constraints from NLM answers and write into the skill.
4. Run structural validation:
   ```bash
   # For Skill-type projects
   python3 ~/.claude/skills/shelf/skill-creator/scripts/quick_validate.py \
     ~/.claude/plugins/oodc/skills/oodc/SKILL.md
   ```

## 8-Item Closure Checklist

**All must pass to count as complete**:

- [ ] RED tests fully pass (5/5 scenarios with correct agent behavior)
- [ ] SKILL.md ≤500 words (verify body with `wc -w`, excluding frontmatter)
- [ ] frontmatter description includes all trigger conditions
- [ ] references are only one level deep (no references-of-references)
- [ ] Plugin registered correctly (`installed_plugins.json` updated + restart-verified)
- [ ] tacit-kb routing profile updated (`kb.py extract --write --domain skills`)
- [ ] doc-sync executed (DOC_GUIDE + CHANGELOG + AI-systems README)
- [ ] Persistent memory recorded as a [decision] (`save_memory` title="[decision] OODC Plugin v1.0" importance="critical")

## AI-Drafted Memory-Log Entry (mandatory at project completion)

The AI drafts + recommends files; the user only does approve/skip:

| Signal | File | Format |
|---|---|---|
| Architectural decision | memory-log/decision-log.md | `## [date] {project} — {decision}` |
| Mistake / failure | memory-log/lessons-learned.md | `## [date] {project} — {lesson}` |
| Cognitive shift | memory-log/key-insights.md | `## [date] {project} — {insight}` |

Path: a user-configured archive root.

Flow:
1. AI generates a 2-3 line draft.
2. Output: "→ Recommend writing to: memory-log/{file}.md\n{draft}\nUser: approve / skip / rewrite?"
3. approve → Read the file → append to end.
4. skip → skip.

## Orient Review Re-Check (second expert review during Create)

Before delivery, invoke 1-2 experts for quality review:

```
Question: "Review the final output of this {project type}.
1. What are the obvious blind spots?
2. From your framework, what is the biggest risk?
3. If you could change only one thing, what would it be?"
```

Expert choice: pick the 1-2 most relevant from the Orient phase.

## OODC Self-Update Prompt

After Create completes, retrospective on this OODC cycle:

1. Which step took the most time? Can it be optimized?
2. Which reference file was loaded most often? Can high-frequency content move up to SKILL.md?
3. Which Red Flags were hit? Should new ones be added?
4. Did the NLM query template cover every angle this project needed?

If anything is found → record to persistent memory `[discovery] OODC self-update: {specific improvement}`, batch on the next OODC update.

## Evidence Hard Rule (12 laziness patterns #9 #11)

**A bare "all passed" textual claim = INVALID.** You must paste the command stdout.

| Correct | Wrong |
|---|---|
| `$ wc -w SKILL.md` → `427` | "Word count verified" |
| `$ kb.py status` → `skills 81 entries...` | "KB updated" |
| `$ ls ~/.claude/plugins/oodc/` → [file list] | "Files structured correctly" |

## Install ≠ Register Detection (12 laziness patterns #11)

After installing any new skill / tool / plugin, the Create loop must check:
- [ ] **Shelf system**: registered to shelf/ or plugins/?
- [ ] **KB domain**: `kb.py ingest` + `compile` + `skill-routes --rebuild`?
- [ ] **Upstream tracking**: do upstream-derived items have an `.upstream.json`?

Missing any item = "surface only", incomplete loop closure.

## State-File Cleanup

Last step of the Create loop (after all evidence is confirmed):
```bash
rm ~/.claude/.oodc-state-{project}  # delete this session's state file; does not affect other sessions
```

# Decide — Decision Lock Template

## Five-Element Lock Format

Every project must lock the following five elements before proceeding to Create:

```
project_name: {name}
core_abstraction: {one sentence: what this thing essentially is}
tech_stack: {language / framework / key dependencies}
file_topology: {directory structure outline}
upstream_strategy: {none / fork upstream(repo URL) / greenfield}
```

## Local Archive Routing

When the five elements are locked, derive the local archive directory by type:

| Type | Suggested directory pattern |
|---|---|
| Skill / MCP / AI plugin / tool | `ai-systems/` |
| Methodology / framework | `skill-library/` |
| X / video / long-form content | `content-production/` |
| Finance / DCA | `finance/` |
| Research / competitor analysis | `research-reports/` |

Root path is user-specific. Present: "Archive root: {root}/{dir}/{project_name}/ — confirm?"

## Decision Point Structure

Identify 3-4 key decision points. For each, follow this format:

```
### DP-{N}: {decision question}
Confidence: high / medium / low

| Option | Description | Pros | Risks |
|---|---|---|---|
| A | ... | ... | ... |
| B (recommended) | ... | ... | ... |
| C | ... | ... | ... |

Recommendation rationale: {1-2 sentences}
```

Decision points with "low" confidence → mark for the user's focused approval.

## .upstream.json v3 Schema

When there is an upstream dependency, annotate per-file strategy:

```json
{
  "version": 3,
  "upstream": "{repo URL}",
  "upstream_ref": "{commit/tag}",
  "last_checked": "{ISO date}",
  "files": {
    "{filename}": {
      "strategy": "accept|customize|new|reject",
      "upstream_path": "{upstream path; null when new}",
      "notes": "{handling notes}"
    }
  }
}
```

Strategy semantics:
- `accept`: keep as-is; sync directly when upstream updates
- `customize`: customized from upstream; needs diff review when upstream updates
- `new`: created by the user; no upstream counterpart
- `reject`: upstream has it but we don't need it; explicitly excluded

## User-Approval Gate

After Decide is complete, present the following format and wait for the user's confirmation:

```
## 🔒 OODC Decide — awaiting approval

### Five elements
[five-element table]

### Decision points
[DP-1 ~ DP-N summary, one line each: decision + recommendation + confidence]

### Upstream strategy
[.upstream.json summary or "no upstream"]

### Architectural risks
[≥3 system-level risks, one line each]

⏸️ On confirmation, proceed to Create. To modify any decision → modify, then re-run the consistency guard.
```

## Consistency Guard (auto-triggered)

**Trigger condition**: Any decision point's option / recommendation changes.

**Steps**:

1. Extract the changed decision: old value → new value.
2. Search the entire Plan for all references to the old value.
3. For each hit, judge: is the reference still correct?
4. Output a change-impact list:

```
| Location | Old value | Should be | Status |
|---|---|---|---|
| §3 Observe Agent 3 | shelf/ directory | plugins/ directory | ✅ updated |
| §6 Create loop closure | skill-check | plugin verification | ❌ needs update |
```

5. All "❌ needs update" entries must be fixed before Create can begin.
6. If Create is rolled back to Decide → re-run the consistency guard → additionally check whether any code/files already written need to be synced.

**Never skip**: even if the change looks small (e.g., a single path tweak), the full Plan must be scanned. The root cause of past lesson #3 was "the change looked small, so it wasn't checked."

## Requirement-Trimming Detection (12 laziness patterns #8)

**Default: do everything**. Splitting Phases is allowed only if the user explicitly says "split into batches" / "do later".

Detection signals:
- Plan contains "future sprint" / "not in this round" / "Phase X TBD" → **abort**
- Unless the user's own words include those phrases.

## Mandatory Self-Audit Before ExitPlanMode (12 laziness patterns #4)

Decide produces a `consistency: PASS/FAIL` field. It must pass the following checks before PASS:

1. The numbers at the top of the Plan (file count / concept count) = the actual entry count at the bottom of the Plan.
2. All Phase descriptions are consistent (no Phase 2 saying something Phase 3 contradicts).
3. The file count in `.upstream.json` = the file count in the actual file topology.
4. Each decision point's recommendation is executed in the rest of the Plan (no recommending A but executing B).

`consistency: FAIL` → do not present to the user; fix first.

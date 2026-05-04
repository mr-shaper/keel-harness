# Category H Rule Template — Cross-Sprint Permanent Law

> Category H rules are ratified permanent laws that survive across sessions, sprints, and projects.
> Once ratified, a Category H rule cannot be revoked without explicit CEO override with documented justification.
> Use this template when promoting a candidate rule to ratified status.

---

## Template Schema

```markdown
# L<NN>: <Rule Name>

**Status**: candidate | ratified
**Ratified date**: YYYY-MM-DD
**Sprint**: S<N>
**Trigger condition**: <when this rule fires; specific signal — e.g., "any agent writes to X without first grepping Y">
**Rule body**: <one-paragraph statement of the law; precise, falsifiable, no weasel words>
**Why (root cause / past incident)**: <evidence-based justification; cite the sprint number and exact failure mode where this was learned>
**How to apply**: <when to apply; what to watch for in code review, planning, or handoff review; concrete checklist items>
**Counter-examples**: <at least 1 case where this rule explicitly does NOT apply, preventing overreach>
**Cross-sprint scope**: <does this carry across sessions/sprints/projects? state the scope of permanence explicitly>
**Verification**: <how to test the rule is honored — bash command, grep pattern, or workflow check step>
```

---

## Worked Example

# L98: Manifest Completeness CI Gate Law

**Status**: ratified
**Ratified date**: 2026-05-03
**Sprint**: S6
**Trigger condition**: Any commit that adds a new file to a `kernel_files`-tracked directory without a corresponding `manifest.json` entry, OR any manifest entry whose target file does not exist on disk.

**Rule body**: Every file listed in `manifest.json` under `kernel_files` must exist on disk at commit time, and every kernel file added to disk must have a corresponding manifest entry. A CI gate (or pre-commit hook) must enforce bidirectional consistency: manifest-entry-without-file is a vaporware violation; file-without-manifest-entry is a silent gap. Both directions fail the gate. No exceptions during active sprint; maintenance-mode projects may gate warnings instead of errors.

**Why (root cause / past incident)**: In S5, three files were listed in `manifest.json` (`templates/handoff-template.md`, `templates/cat-h-rule-template.md` (formerly named with a CJK character — non-ASCII filename, OSS-hostile), `audit/romeo-6-dim-framework.md`) that did not exist on disk. Layer 0 health check [a] (16-file kernel file scan) detected the gap in S6 Wave 6. README linked to all three; users encountered 404. The vaporware entries also blocked W7 launch UX validation because the audit framework referenced in install.sh smoke tests did not exist.

**How to apply**:
- In code review: run `jq -r '.kernel_files[]' manifest.json | xargs -I{} test -f {} || echo MISSING: {}` and paste output before approving.
- In planning: when adding a file to `kernel_files`, the same commit must create the file (or vice versa — atomic pairing).
- In handoff: verification checklist must include the bidirectional manifest scan command.

**Counter-examples**:
- A file intentionally marked `TODO` in an `upcoming_files` key (not `kernel_files`) does not trigger this rule — the rule applies only to `kernel_files`.
- During a `freeze` or `maintenance-mode` sprint, new `kernel_files` entries are blocked entirely, so this rule does not gate existing entries that were grandfathered before freeze.

**Cross-sprint scope**: Permanent across all harness-engineering sprints. Applies to any project that adopts the keel-harness manifest schema. Survives S-number rollovers.

**Verification**:
```bash
# Check manifest entries exist on disk (vaporware detection)
jq -r '.kernel_files[]' manifest.json | while read f; do
  [ -f "$f" ] || echo "MISSING: $f"
done

# Check kernel files on disk have manifest entries (silent gap detection)
jq -r '.kernel_files[]' manifest.json > /tmp/manifest_files.txt
find templates/ hooks/ audit/ plugins/ workflows/ -name "*.md" -o -name "*.sh" -o -name "*.json" | \
  sort > /tmp/disk_files.txt
comm -23 /tmp/disk_files.txt /tmp/manifest_files.txt | head -20
```

---

## Promotion Checklist (candidate → ratified)

Before changing `Status` from `candidate` to `ratified`:

- [ ] Rule has survived at least 1 full sprint in candidate state without needing rewording
- [ ] At least 1 real incident (not hypothetical) motivated the rule
- [ ] Counter-examples are documented (prevents overreach)
- [ ] Verification command is runnable and produces deterministic output
- [ ] Cross-sprint scope is explicitly stated
- [ ] Cross-reference added in `HARNESS_BIBLE.md` Category H section
- [ ] `docs/notes.md` or sprint retro records the ratification event

---

> Cross-reference: `audit/romeo-6-dim-framework.md` — Romeo evaluator findings that surface new rule candidates
> should use this template to promote them from observation to ratified Category H law.

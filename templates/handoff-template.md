# Handoff Template — 7-Field Schema Spec

> Canonical spec for the frontmatter written by `hooks/stop-handoff-writer.sh`.
> Stop hook writes **mechanically only**. Zero AI summary in Stop hook output.
> AI commentary and `next_action` narrative are appended by the **next session**, not by the Stop hook.

---

## YAML Frontmatter Schema

```yaml
---
session_id: "<string>"       # UUID from Claude Code env ($CLAUDE_SESSION_ID). Unique per session.
trigger: "<enum>"            # One of: stop | user-quit | timeout. How the session ended.
ended: "<ISO 8601>"          # Datetime when session closed, e.g. 2026-05-03T14:32:00-07:00 (PST).
commit_hash: "<string>"      # git short SHA at time of stop (7 chars). "none" if no commits.
branch: "<string>"           # git branch name at time of stop, e.g. main.
modified_files:              # List of strings from `git status --porcelain` at stop time.
  - "<path>"                 # Each line is one file path, relative to repo root.
last_user_prompt: "<string>" # Tail of transcript JSONL last user message. Max 500 chars. Mechanical extract only.
next_action: "<string>"      # "TBD-next-action-absent" placeholder. Next session fills this in.
---
```

### Field Semantics

| Field | Type | Source | Notes |
|---|---|---|---|
| `session_id` | string | `$CLAUDE_SESSION_ID` env | UUID; blank if env not set |
| `trigger` | enum | Stop hook invocation context | `stop` = normal Claude stop; `user-quit` = user ^C; `timeout` = idle timeout |
| `ended` | ISO 8601 datetime | `date -u +"%Y-%m-%dT%H:%M:%SZ"` | UTC preferred; local TZ acceptable |
| `commit_hash` | string | `git rev-parse --short HEAD` | `"none"` if repo has no commits |
| `branch` | string | `git branch --show-current` | `"detached"` if HEAD detached |
| `modified_files` | list of strings | `git status --porcelain` | Empty list `[]` if working tree clean |
| `last_user_prompt` | string | `jq` extract from transcript JSONL | Mechanical tail; truncated at 500 chars; no paraphrase |
| `next_action` | string | Placeholder only at stop time | Next session overwrites with real action; do NOT generate AI summary here |

---

## Worked Example

```yaml
---
session_id: "a3f4d89c-12bb-4e71-9c0a-ff2e55b01234"
trigger: stop
ended: "2026-05-03T21:15:42Z"
commit_hash: "9afa06f"
branch: main
modified_files:
  - "M  templates/handoff-template.md"
  - "M  manifest.json"
  - "?? audit/romeo-6-dim-framework.md"
last_user_prompt: "Run all 6 verification commands and paste stdout evidence."
next_action: "TBD-next-action-absent"
---
```

---

## Verification Checklist

The **next session** runs these 4 commands before any Write/Edit:

```bash
# 1. Confirm handoff file exists and is readable
ls -la .harness/handoff-*.md | tail -1

# 2. Validate YAML frontmatter parses (requires python3-yaml or yq)
python3 -c "import yaml, sys; yaml.safe_load(open(sys.argv[1]))" .harness/handoff-*.md 2>&1 | tail -1

# 3. Grep next_action — must NOT be the placeholder before starting real work
grep "next_action:" .harness/handoff-*.md | tail -1

# 4. Confirm commit_hash matches current HEAD (drift detection)
git rev-parse --short HEAD
```

---

## Transcript Tail — Mechanical Extract Format

The Stop hook uses `jq` to extract the 5 most recent user messages from the Claude Code transcript JSONL. Total output cap: 2000 chars.

```bash
# Mechanical extract — Stop hook uses this pattern verbatim
jq -r 'select(.role=="user") | .content[-1:][].text // .content' \
  "$CLAUDE_TRANSCRIPT_PATH" 2>/dev/null \
  | tail -5 \
  | cut -c1-400
```

Output is stored verbatim in `last_user_prompt`. No rephrasing, no summarization, no AI interpretation.

---

> **Iron Rule**: ZERO AI summary in Stop hook output. Mechanical extraction only.
> AI commentary is appended by the next session, not by the Stop hook.

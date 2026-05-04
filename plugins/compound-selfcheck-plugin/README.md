# compound-selfcheck-plugin

PostToolUse hook that reminds agents to ingest large changes into a knowledge base,
enforcing Compound Engineering principles.

## Purpose

When an AI writes or edits a large file (LOC > 100 or BYTES > 5000), a soft reminder is
printed to stderr. No writes are blocked — exit 0 always.

## Install

Add to your `settings.json` (see `templates/settings.json.template`):

```json
{
  "hooks": {
    "PostToolUse": [{
      "hooks": [{
        "command": "bash ${HARNESS_HOME:-~/.claude/plugins/harness-engineering-mp}/plugins/compound-selfcheck-plugin/hooks/post-tool-compound-check.sh",
        "timeout": 10,
        "type": "command"
      }],
      "matcher": "Write|Edit|MultiEdit|NotebookEdit"
    }]
  }
}
```

Set `HARNESS_ROOT` to your project root (used for audit log path).

## Hook Trigger Logic

| Condition | Behavior |
|-----------|----------|
| tool not in `Write\|Edit\|MultiEdit\|NotebookEdit` | silent exit 0 |
| LOC ≤ 100 AND BYTES ≤ 5000 | silent exit 0 |
| LOC > 100 OR BYTES > 5000 | 21-line stderr reminder + audit log entry |

## Audit Log

Appends one line to `${HARNESS_ROOT}/.harness/hook-trace.log`:
```
[TIMESTAMP] [COMPOUND-CHECK] tool=Write file=<path> loc=<N> bytes=<N> triggered=true
```

## OSS / Universal

No private paths or runtime-specific logic.
Works with any project that sets `HARNESS_ROOT` and has a `.harness/` directory.

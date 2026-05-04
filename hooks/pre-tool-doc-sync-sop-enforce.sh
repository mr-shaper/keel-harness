#!/usr/bin/env bash
# pre-tool-doc-sync-sop-enforce.sh — PreToolUse Bash hook
# Job: Block direct `kb.py ingest <file>` calls; force kb-ingest-compile.sh wrapper.
# Exit 0 = pass-through, Exit 2 = BLOCK

set -uo pipefail
trap 'exit 0' ERR

# ── Read stdin (JSON payload) ─────────────────────────────────────────────────
PAYLOAD=""
if [ -t 0 ]; then
  PAYLOAD="{}"
else
  PAYLOAD="$(cat 2>/dev/null || echo "{}")"
fi
[[ -z "${PAYLOAD}" ]] && PAYLOAD="{}"

# ── Extract Bash command ──────────────────────────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  COMMAND="$(echo "${PAYLOAD}" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")"
else
  COMMAND="$(python3 -c "
import json, sys
try:
    d = json.loads(sys.argv[1])
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" "${PAYLOAD}" 2>/dev/null || echo "")"
fi

# ── Check: direct kb.py ingest without wrapper ───────────────────────────────
if echo "${COMMAND}" | grep -q 'kb\.py ingest' 2>/dev/null; then
  if ! echo "${COMMAND}" | grep -q 'kb-ingest-compile\.sh' 2>/dev/null; then
    echo "[doc-sync-sop-enforce] BLOCKED: Direct kb.py ingest detected." >&2
    echo "[doc-sync-sop-enforce] Use the wrapper instead:" >&2
    echo "[doc-sync-sop-enforce]   bash ~/.claude/skills/shelf/doc-sync/scripts/kb-ingest-compile.sh <path> <domain>" >&2
    echo "[doc-sync-sop-enforce] Direct kb.py ingest skips compound-selfcheck + frontmatter + compile-hint." >&2
    exit 2
  fi
fi

exit 0

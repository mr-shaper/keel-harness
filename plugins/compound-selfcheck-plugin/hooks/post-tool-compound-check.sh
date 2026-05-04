#!/usr/bin/env bash
# compound-selfcheck: PostToolUse hook — remind to ingest large changes into KB
# Triggers: LOC > 100 OR BYTES > 5000 (soft reminder, never blocks)
set -uo pipefail
trap 'exit 0' ERR

HARNESS_ROOT="${HARNESS_ROOT:-$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "")}"
TRACE_LOG="${HARNESS_ROOT}/.harness/hook-trace.log"

# Read stdin JSON (Claude passes tool_name + tool_input)
INPUT="$(cat)"

TOOL_NAME="$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('tool_name',''))" <<< "${INPUT}" 2>/dev/null || true)"

# Only act on write-class tools
case "${TOOL_NAME}" in
  Write|Edit|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

# Extract content (may be absent for Edit/MultiEdit — use empty string)
CONTENT="$(python3 -c "
import json,sys
d=json.loads(sys.stdin.read())
ti=d.get('tool_input',{})
print(ti.get('content','') or ti.get('new_string','') or '')
" <<< "${INPUT}" 2>/dev/null || true)"

FILE_PATH="$(python3 -c "
import json,sys
d=json.loads(sys.stdin.read())
ti=d.get('tool_input',{})
print(ti.get('file_path','') or ti.get('path','') or '')
" <<< "${INPUT}" 2>/dev/null || true)"

# Measure LOC and BYTES
METRICS="$(python3 -c "
import sys
content = sys.stdin.read()
loc = content.count('\n') + (1 if content and not content.endswith('\n') else 0)
byt = len(content.encode('utf-8'))
triggered = 'yes' if loc > 100 or byt > 5000 else 'no'
print(f'{loc} {byt} {triggered}')
" <<< "${CONTENT}" 2>/dev/null || echo "0 0 no")"

LOC="$(echo "${METRICS}" | cut -d' ' -f1)"
BYTES="$(echo "${METRICS}" | cut -d' ' -f2)"
TRIGGERED="$(echo "${METRICS}" | cut -d' ' -f3)"

if [[ "${TRIGGERED}" != "yes" ]]; then
  exit 0
fi

# Output 21-line unicode reminder to stderr
cat >&2 <<'REMINDER'
╔══════════════════════════════════════════════════════════════════╗
║            [COMPOUND-CHECK] Large Change Detected                ║
╠══════════════════════════════════════════════════════════════════╣
║  Compound Engineering Three Iron Laws:                           ║
║  (a) Ingest = Structurize  — capture knowledge at write time     ║
║  (b) Compound > one-shot   — build long-term assets, not drafts  ║
║  (c) KB is upstream        — knowledge base feeds all output     ║
╠══════════════════════════════════════════════════════════════════╣
║  ACTION: Consider running doc-sync to ingest this change         ║
║  into your knowledge base and form a lasting compound asset.     ║
║                                                                  ║
║  Suggested trigger:                                              ║
║    bash ~/.claude/skills/shelf/doc-sync/scripts/                 ║
║         kb-ingest-compile.sh <file> <domain>                     ║
║                                                                  ║
║  Skip if: scratch file / temp / already ingested / not KB-ready  ║
╠══════════════════════════════════════════════════════════════════╣
║  This is a soft reminder — no action blocked.                    ║
╚══════════════════════════════════════════════════════════════════╝
REMINDER

# Write audit log entry
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
if [[ -n "${HARNESS_ROOT}" && -d "${HARNESS_ROOT}/.harness" ]]; then
  printf '[%s] [COMPOUND-CHECK] tool=%s file=%s loc=%s bytes=%s triggered=true\n' \
    "${TIMESTAMP}" "${TOOL_NAME}" "${FILE_PATH}" "${LOC}" "${BYTES}" >> "${TRACE_LOG}" 2>/dev/null || true
fi

exit 0

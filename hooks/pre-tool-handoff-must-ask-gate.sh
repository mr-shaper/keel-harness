#!/usr/bin/env bash
# pre-tool-handoff-must-ask-gate.sh — PreToolUse matcher="Write|Edit|MultiEdit" hook (alpha.8 NEW)
#
# Enforces user-explicit ratify before any Write/Edit/MultiEdit can target a
# handoff-sN-to-sN+1.md file. Without this gate, an autonomous AI can write
# a handoff file at any time — bypassing the Stop-hook PCT gate (which only
# governs the Stop hook's own write, not arbitrary Write tool use).
#
# The fix is a sibling to L24 (matcher-scope-mismatch): Stop-event scope and
# Write-event scope are different matchers. The Stop-side PCT gate cannot
# block a Write-side action, so a separate PreToolUse hook covers the
# Write-side scope.
#
# Three exempt paths (any one passes):
#   1. env HARNESS_HANDOFF_VIA_STOP=1 — set by stop-handoff-writer.sh when
#      the Stop hook is the originator. (Allows the legitimate Stop-hook
#      auto-write while still blocking arbitrary AI writes.)
#   2. env HARNESS_HANDOFF_USER_OK=1 — user pre-set, e.g. in a one-off shell
#      session where the user wants to bypass for a known reason.
#   3. transcript scan — the user said one of seven literal ratify keywords
#      in the last 30 user messages: "write handoff" / "go handoff" /
#      "yes handoff" / "写 handoff" / "交接 handoff" / "生成 handoff" /
#      "写交接".
#
# Default: BLOCK with exit 2 and a stderr message that lists the three
# exempt paths so the user knows how to unblock.
#
# L43 strictly: matcher in settings.json is the literal whitelist
# `Write|Edit|MultiEdit` — never `*`. Internal regex filter
# `handoff-s[0-9]+-to-s[0-9]+\.md$` keeps the work proportional even within
# the whitelist.
#
# DON'T: matcher `*` (L43); exit 0 by default (would be no-op);
#        LLM-based semantic detection (transcript scan uses literal grep).

set -euo pipefail

INPUT="$(cat 2>/dev/null || true)"
[ -n "$INPUT" ] || exit 0

TOOL_NAME="$(jq -r '.tool_name // empty' <<<"$INPUT" 2>/dev/null || true)"
FILE_PATH="$(jq -r '.tool_input.file_path // empty' <<<"$INPUT" 2>/dev/null || true)"
TRANSCRIPT_PATH="$(jq -r '.transcript_path // empty' <<<"$INPUT" 2>/dev/null || true)"

# Filter: only fire on the handoff-sN-to-sN+1.md pattern (anchored end-of-string).
# Do NOT fire on: handoff-lite-*.md, handoff.md, handoff-required.flag, etc.
if ! printf '%s' "$FILE_PATH" | grep -qE 'handoff-s[0-9]+-to-s[0-9]+\.md$'; then
  exit 0  # regex not matched → silent pass-through
fi

# Exempt path 1: stop-handoff-writer.sh sets this env on its own subprocess
if [ "${HARNESS_HANDOFF_VIA_STOP:-}" = "1" ]; then
  printf '[HANDOFF-MUST-ASK] PASS: stop-handoff-writer env exempt (HARNESS_HANDOFF_VIA_STOP=1)\n' >&2
  exit 0
fi

# Exempt path 2: user pre-set env flag for a known-intentional bypass
if [ "${HARNESS_HANDOFF_USER_OK:-}" = "1" ]; then
  printf '[HANDOFF-MUST-ASK] PASS: user env exempt (HARNESS_HANDOFF_USER_OK=1)\n' >&2
  exit 0
fi

# Exempt path 3: transcript scan — user said a literal ratify keyword recently
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  TRANSCRIPT_HIT=$(
    tail -n 200 "$TRANSCRIPT_PATH" 2>/dev/null \
      | jq -r 'select(.type == "user") | .message.content[]?.text // .message.content // empty' 2>/dev/null \
      | tail -n 30 \
      | grep -iE '(write handoff|go handoff|yes handoff|写 handoff|交接 handoff|生成 handoff|写交接)' \
      || true
  )
  if [ -n "$TRANSCRIPT_HIT" ]; then
    printf '[HANDOFF-MUST-ASK] PASS: transcript literal ratify keyword found\n' >&2
    exit 0
  fi
fi

# Default: BLOCK and educate the user about how to unblock
printf '[HANDOFF-MUST-ASK] ❌ BLOCK: AI tried to %s handoff file without user explicit ratify\n' \
  "$TOOL_NAME" >&2
printf '  File: %s\n' "$FILE_PATH" >&2
printf '  3 PASS paths:\n' >&2
printf '  1. env HARNESS_HANDOFF_VIA_STOP=1 (stop-handoff-writer auto)\n' >&2
printf '  2. env HARNESS_HANDOFF_USER_OK=1 (user pre-set)\n' >&2
printf '  3. say in chat: "write handoff" / "go handoff" / "yes handoff" / "写 handoff" / "交接 handoff" / "生成 handoff" / "写交接"\n' >&2
exit 2

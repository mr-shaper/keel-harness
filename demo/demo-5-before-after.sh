#!/usr/bin/env bash
# Demo 5: Before/After — same fresh Claude Code session, with vs without keel
# Two-act simulation. Pure cat/echo/sleep (no real claude invocation).
# asciinema rec demo/demo-5.cast -c "bash demo/demo-5-before-after.sh"
# agg demo/demo-5.cast demo/demo-5.gif

set -e
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO}"

type_cmd() {
  printf '$ '
  for ((i=0; i<${#1}; i++)); do printf '%s' "${1:i:1}"; sleep 0.02; done
  printf '\n'; eval "$1"; sleep 0.6
}

dim()  { printf '\033[2m%s\033[0m\n' "$1"; }
red()  { printf '\033[31m%s\033[0m\n' "$1"; }
grn()  { printf '\033[32m%s\033[0m\n' "$1"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$1"; }
bold() { printf '\033[1m%s\033[0m\n' "$1"; }

clear

# ════════════════════════════════════════════════════════════════════
#  ACT 1 — Without keel  (35 sec)
# ════════════════════════════════════════════════════════════════════
cat <<'BANNER'
═══════════════════════════════════════════════════════════════════
  ACT 1 — Without keel    (fresh session, same morning)
═══════════════════════════════════════════════════════════════════
BANNER
sleep 1.5

echo ""
dim "# Yesterday: agreed on Plan rev D + 3 ratified decisions."
dim "# This morning: new claude session, blank slate."
sleep 1.2

echo ""
type_cmd 'echo "where were we on the auth refactor?"'
sleep 0.4
ylw "  agent: I don't have prior context. Could you share the spec?"
sleep 1.5

echo ""
dim "# 20 min later — agent re-debates a settled question:"
type_cmd 'echo "should we use JWT or session cookies?"'
sleep 0.4
ylw "  agent: Both have trade-offs. Let me lay them out..."
red "  (this was decided yesterday. you re-pay the cost.)"
sleep 1.8

echo ""
dim "# A commit later:"
type_cmd 'git diff --stat'
echo "   src/auth.ts  | 12 ++++++++++++"
sleep 0.6
type_cmd 'git log -1 --format="%H%n%s%n"'
echo "  abc123def..."
echo "  feat(auth): add bearer token middleware"
echo ""
red '  --- src/auth.ts:5 ---'
red '  + const API_KEY = "sk-prod-7f9a2b1c..."   # hardcoded'
sleep 1.6

echo ""
dim "# And the wrap-up claim:"
ylw '  agent: "All tests pass. Ready to merge."'
red "  (you run them. 6 fail.)"
sleep 2.0

echo ""
red "──────────────────────────────────────────"
red "  Without keel: zero context, leaked key,"
red "  unverified claim. Same fresh session."
red "──────────────────────────────────────────"
sleep 2.5

# ════════════════════════════════════════════════════════════════════
#  ACT 2 — With keel  (35 sec)
# ════════════════════════════════════════════════════════════════════
clear
cat <<'BANNER'
═══════════════════════════════════════════════════════════════════
  ACT 2 — With keel       (fresh session, same morning)
═══════════════════════════════════════════════════════════════════
BANNER
sleep 1.5

echo ""
dim "# .harness/state present → SessionStart hook fires."
type_cmd 'ls .harness/handoff-*.md | tail -1'
echo "  .harness/handoff-S3-to-S4.md"
sleep 0.6
grn "  [SessionStart] Read 5 mandatory files. 5 self-checks injected."
sleep 1.4

echo ""
type_cmd 'echo "where were we on the auth refactor?"'
sleep 0.4
grn "  agent: handoff-S3-to-S4 says JWT was ratified yesterday"
grn "         (decision 4/7). Continuing with bearer middleware."
sleep 1.8

echo ""
dim "# Same commit attempt:"
type_cmd 'git add src/auth.ts && git commit -m "feat(auth): add bearer middleware"'
sleep 0.4
red "  [pre-commit] BLOCK: src/auth.ts contains 'sk-' API key pattern."
red "  [pre-commit] hint: move to env var or .env.local (gitignored)."
red "  commit aborted (exit 1)"
sleep 2.0

echo ""
dim "# Wrap-up claim:"
type_cmd 'echo "tests pass, ready to merge"'
sleep 0.4
ylw "  [verification-before-completion] claim 'tests pass' detected."
ylw "  → please paste output of: bash tests/test-suite.sh"
sleep 0.8
type_cmd 'bash tests/test-suite.sh 2>&1 | tail -3'
echo "  6/8 PASS, 2 FAIL"
red "  agent: I cannot claim 'tests pass'. 2 failing — investigating."
sleep 2.2

echo ""
grn "──────────────────────────────────────────"
grn "  With keel: same model, same prompt."
grn "  Context carried. Secret blocked. Claim"
grn "  required to prove itself."
grn "──────────────────────────────────────────"
sleep 2.0

echo ""
bold "  github.com/mr-shaper/keel-harness"
sleep 1.5

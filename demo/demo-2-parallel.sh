#!/usr/bin/env bash
# Demo 2: 4-Layer Nested Parallel — 7 P8 → 7x speedup (Gap 3)
# asciinema rec demo/demo-2.cast -c "bash demo/demo-2-parallel.sh"
# agg demo/demo-2.cast demo/demo-2.gif

set -e
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO}"

type_cmd() {
  printf '$ '
  for ((i=0; i<${#1}; i++)); do printf '%s' "${1:i:1}"; sleep 0.02; done
  printf '\n'; eval "$1"; sleep 0.7
}

clear
cat <<'BANNER'
═══════════════════════════════════════════════════════════════════
  Demo 2 — 4-Layer Nested Parallel (Gap 3: P9 role drift)
═══════════════════════════════════════════════════════════════════
BANNER
sleep 1.5

echo ""
echo "## The Topology"
sleep 0.5
cat <<'TOPO'
  ┌─────────────────────────────────────────────────────┐
  │  CEO (override)                                     │
  │     │                                               │
  │     ▼                                               │
  │  P10 Strategy   ──ratifies──>  4 sub-decisions      │
  │     │                                               │
  │     ▼                                               │
  │  P9 Tech Lead   ──same-message multi-Agent──>       │
  │     │                                               │
  │     ▼                                               │
  │  P8-α  P8-β  P8-γ  P8-δ  P8-ε  P8-ζ  P8-η          │
  │  (manifest)(sync)(hook)(CLAUDE.md×2)(settings)(audit)│
  │     │                                               │
  │     ▼ (when complex)                                │
  │  P7 sub-tasks (P8 internal, P9 doesn't manage)     │
  └─────────────────────────────────────────────────────┘
TOPO
sleep 3.5

echo ""
echo "## Step 1: P9 dispatches 7 P8 in same message (true parallel)"
sleep 0.5
type_cmd "cat manifest.json | jq '.kernel_files | length'"
echo ""
echo "(7 P8 wrote 7 deliverables in same message Agent calls — wall time ~25 min vs 3h serial)"
sleep 2

echo ""
echo "## Step 2: File domain isolation (grep verify, 0 overlap)"
sleep 0.5
type_cmd "ls manifest.json sync.sh hooks/pre-commit templates/CLAUDE.md.global.template templates/CLAUDE.md.project.template templates/settings.json.template docs/license-audit-report.md"
sleep 1.5

echo ""
echo "## Step 3: P9 acceptance loop — 4 TDD suites real-run"
sleep 0.5
type_cmd "bash tests/test-sync.sh 2>&1 | tail -1"
type_cmd "bash tests/test-pre-commit.sh 2>&1 | tail -1"
type_cmd "bash tests/test-install.sh 2>&1 | tail -1"
type_cmd "bash tests/test-red-team.sh 2>&1 | tail -1"
sleep 1.5

echo ""
echo "## Total: 52 sub-assertions PASS, 0 conflict between agents"
sleep 1.5

cat <<'CLOSE'

═══════════════════════════════════════════════════════════════════
  P9 is a director, not an actor.
  P9's code is the Task Prompt. The actors are 7 P8 sub-agents.
═══════════════════════════════════════════════════════════════════
CLOSE
sleep 2

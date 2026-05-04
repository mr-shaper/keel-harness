#!/usr/bin/env bash
# Demo 4 [BONUS]: 5 vocabulary words + 4 gaps — 1.5 min concentrated narrative
# Run via: asciinema rec demo/demo-4.cast -c "bash demo/demo-4-vocab-gaps.sh"
# Output:  agg demo/demo-4.cast demo/demo-4.gif

set -e
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO}"

# slow-type helper: simulate human typing for cinematic effect
type_cmd() {
  local cmd="$1"
  printf '$ '
  for ((i=0; i<${#cmd}; i++)); do
    printf '%s' "${cmd:i:1}"
    sleep 0.025
  done
  printf '\n'
  eval "$cmd"
  sleep 0.8
}

clear
cat <<'BANNER'
═══════════════════════════════════════════════════════════════
  harness-engineering — 5 words to enter the agentic eng vocab
═══════════════════════════════════════════════════════════════
BANNER
sleep 1.5

# ── §1: 4 gaps (8s) ──
echo ""
echo "## The 4 gaps harness fills (vs Karpathy's agentic engineering vision)"
echo ""
sleep 0.6
cat <<'GAPS'
   Gap 1: 24h session memory loss     →  immutable handoff 7-field schema
   Gap 2: Romeo audit blind spots     →  6-dim hardcore ≥0.99 enforcement
   Gap 3: P9 role drift (writes code) →  P10-9-8-7 topology + 8 iron rules
   Gap 4: silent dead hooks           →  Layer 0 contract (CLAUDE.md+settings.json)
GAPS
sleep 3

# ── §2: 5 vocabulary (45s) ──
echo ""
echo "═══ The 5 words ═══"
sleep 1

echo ""
echo "## 1. 薄浇水律 (thin watering principle) — write handoffs incrementally, not at end"
sleep 0.4
type_cmd "ls demo/sample-handoff.md"
sleep 0.5

echo ""
echo "## 2. session 交接 7 字段 (7-field handoff schema, sanitized sample)"
sleep 0.4
type_cmd "head -13 demo/sample-handoff.md"
sleep 0.8

echo ""
echo "## 3. Romeo 6 维 audit (Honesty/Ownership/TechDepth/Pattern Replay/Density/Candidates)"
sleep 0.4
type_cmd "grep -A 6 'Romeo 6' README.md | head -10"
sleep 0.8

echo ""
echo "## 4. canonical 诚实律 (canonical honesty) — pre-commit BLOCK + verify-before-completion"
sleep 0.4
type_cmd "head -3 hooks/pre-commit"
sleep 0.5

echo ""
echo "## 5. 4 层嵌套并行 (4-layer nested parallel)"
sleep 0.4
echo "    Harness ⊃ OODC ⊃ Superpower(Phase 0-4) ⊃ PUA(P10/P9/P8/P7)"
sleep 1.5

# ── §3: closing (10s) ──
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  See README.md for install + ARCHITECTURE.md for full topology"
echo "  github.com/mr-shaper/keel-harness — Apache-2.0"
echo "═══════════════════════════════════════════════════════════════"
sleep 2

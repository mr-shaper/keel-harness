#!/usr/bin/env bash
# Master demo recorder — one-shot record + GIF generation
# Usage:
#   bash demo/record.sh 4              # record demo 4 only (BONUS, recommended first)
#   bash demo/record.sh all            # record all 4 demos
#   bash demo/record.sh 1              # record demo 1
#
# Outputs:
#   demo/demo-N.cast    (asciinema raw)
#   demo/demo-N.gif     (agg-rendered GIF, embeddable in README)

set -e
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO}"

# Verify deps
command -v asciinema >/dev/null || { echo "❌ asciinema not installed: brew install asciinema"; exit 1; }
command -v agg       >/dev/null || { echo "❌ agg not installed: brew install agg"; exit 1; }

record_one() {
  local n="$1"
  local script="demo/demo-${n}-${2}.sh"
  local cast="demo/demo-${n}.cast"
  local gif="demo/demo-${n}.gif"

  if [[ ! -f "${script}" ]]; then
    echo "❌ Script not found: ${script}"
    return 1
  fi

  echo ""
  echo "═══ Recording demo ${n} ═══"
  echo "Script:  ${script}"
  echo "Cast:    ${cast}"
  echo "GIF:     ${gif}"
  echo ""

  rm -f "${cast}" "${gif}"

  # asciinema 3.x: rec <output> --command <cmd>
  asciinema rec "${cast}" --command "bash ${script}" --rows 32 --cols 110

  echo ""
  echo "→ Converting to GIF via agg..."
  agg \
    --theme monokai \
    --font-size 14 \
    --speed 1.5 \
    "${cast}" "${gif}"

  echo "✅ Done: ${gif} ($(du -h "${gif}" | awk '{print $1}'))"
}

case "${1:-help}" in
  4)   record_one 4 "vocab-gaps" ;;
  1)   record_one 1 "cross-session" ;;
  2)   record_one 2 "parallel" ;;
  3)   record_one 3 "honesty" ;;
  all)
    record_one 4 "vocab-gaps"
    record_one 1 "cross-session"
    record_one 2 "parallel"
    record_one 3 "honesty"
    echo ""
    echo "═══ All 4 demos recorded ═══"
    ls -lh demo/*.gif
    ;;
  *)
    cat <<'EOF'
Usage:
  bash demo/record.sh 4      # BONUS demo (1.5 min, 5 vocab + 4 gaps) — recommended first
  bash demo/record.sh 1      # 24h cross-session continuity (3 min)
  bash demo/record.sh 2      # 4-layer nested parallel (2 min)
  bash demo/record.sh 3      # canonical honesty hooks (2.5 min)
  bash demo/record.sh all    # record all 4 sequentially

After recording, embed in README.md:
  ![demo 4](demo/demo-4.gif)
EOF
    ;;
esac

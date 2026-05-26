#!/bin/bash
# Sync hand-edited arch-j4c1cz.txt to fastfetch and screensaver targets.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${DIR}/arch-j4c1cz.txt"
for name in about.txt screensaver.txt; do
  cp -f "$SRC" "${DIR}/${name}"
done
echo "Synced ${SRC} -> about.txt, screensaver.txt"

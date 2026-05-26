#!/bin/bash
# Sync arch-j4c1cz.txt to about.txt and screensaver.txt. Use --generate to rebuild from mask.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == "--generate" ]]; then
  python3 "$DIR/generate-arch-j4c1cz.py" --generate
else
  python3 "$DIR/generate-arch-j4c1cz.py"
fi

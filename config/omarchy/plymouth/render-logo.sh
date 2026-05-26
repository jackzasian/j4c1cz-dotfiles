#!/bin/bash
# Render arch-j4c1cz.txt to logo.png for Plymouth (ImageMagick).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANDING="${HOME}/.config/omarchy/branding/arch-j4c1cz.txt"
FONT="${OMARCHY_PLYMOUTH_FONT:-/usr/share/fonts/Adwaita/AdwaitaMono-Regular.ttf}"
FG="${OMARCHY_PLYMOUTH_FG:-#a9d18e}"
BG="${OMARCHY_PLYMOUTH_BG:-#000000}"

magick -background "$BG" -fill "$FG" -font "$FONT" -pointsize 9 \
  -size 900x520 -gravity center "caption:@${BRANDING}" "${DIR}/logo-raw.png"
magick "${DIR}/logo-raw.png" -trim +repage -background "$BG" -gravity center -extent 960x480 \
  "${DIR}/logo.png"
rm -f "${DIR}/logo-raw.png"
echo "Wrote ${DIR}/logo.png"

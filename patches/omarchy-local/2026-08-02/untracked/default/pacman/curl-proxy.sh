#!/bin/bash
# Pacman XferCommand wrapper — route every download through Clash mixed port.
set -euo pipefail

PROXY="${PACMAN_PROXY_URL:-http://127.0.0.1:7897}"
URL=$1
OUT=$2

exec /usr/bin/curl \
  --proxy "$PROXY" \
  --connect-timeout 30 \
  --retry 5 \
  --retry-all-errors \
  --retry-delay 3 \
  --http1.1 \
  -L -C - -f "$URL" -o "$OUT"

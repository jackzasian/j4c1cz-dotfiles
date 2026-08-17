#!/usr/bin/env bash
# Spotify Now Playing for waybar (playerctl / MPRIS).
set -euo pipefail

if ! command -v playerctl >/dev/null 2>&1; then
  printf '{"text":"󰝛","tooltip":"playerctl missing","class":"missing"}\n'
  exit 0
fi

status="$(playerctl -p spotify status 2>/dev/null || true)"
case "${status}" in
  Playing|Paused) ;;
  *)
    printf '{"text":"󰓇","tooltip":"Spotify idle — click to launch","class":"idle"}\n'
    exit 0
    ;;
esac

artist="$(playerctl -p spotify metadata artist 2>/dev/null || true)"
title="$(playerctl -p spotify metadata title 2>/dev/null || true)"
if [[ -n "${artist}" && -n "${title}" ]]; then
  meta="${artist} - ${title}"
elif [[ -n "${title}" ]]; then
  meta="${title}"
elif [[ -n "${artist}" ]]; then
  meta="${artist}"
else
  meta="Unknown"
fi
icon="󰓇"
class="playing"
[[ "${status}" == "Paused" ]] && icon="󰏤" && class="paused"

# Bar label is width-capped so a long track title cannot shove the rest of the
# bar around every time the song changes; the full text stays in the tooltip.
MAX_LABEL="${SPOTIFY_STATUS_MAX_LABEL:-26}"

python3 -c '
import json, sys
icon, meta, status, cls, limit = sys.argv[1:6]
limit = max(8, int(limit))
label = meta if len(meta) <= limit else meta[: limit - 1].rstrip() + "…"
print(json.dumps({
  "text": f"{icon} {label}",
  "tooltip": f"{status}\n{meta}",
  "class": cls,
}, ensure_ascii=False))
' "${icon}" "${meta}" "${status}" "${class}" "${MAX_LABEL}"

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
#
# jackz fix 2026-08-16: the cap used to be a raw character count (26), which
# is fine for Latin titles but let CJK titles (Jack's own listening — podcast
# episode names etc.) blow way past the intended width, since each CJK glyph
# renders roughly 2x as wide as a Latin one at the same font size. Budget by
# *display* width instead (East Asian Width-aware: wide/fullwidth glyphs cost
# 2, everything else costs 1), so a Chinese title and an English title of the
# same MAX_LABEL both land at roughly the same on-screen width.
MAX_LABEL="${SPOTIFY_STATUS_MAX_LABEL:-30}"

python3 -c '
import json, sys, unicodedata

def display_width(s):
  return sum(2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1 for ch in s)

def truncate_to_width(s, limit):
  if display_width(s) <= limit:
    return s
  out = []
  width = 0
  budget = max(0, limit - 1)  # room for the ellipsis
  for ch in s:
    w = 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
    if width + w > budget:
      break
    out.append(ch)
    width += w
  return "".join(out).rstrip() + "…"

icon, meta, status, cls, limit = sys.argv[1:6]
limit = max(8, int(limit))
label = truncate_to_width(meta, limit)
print(json.dumps({
  "text": f"{icon} {label}",
  "tooltip": f"{status}\n{meta}",
  "class": cls,
}, ensure_ascii=False))
' "${icon}" "${meta}" "${status}" "${class}" "${MAX_LABEL}"

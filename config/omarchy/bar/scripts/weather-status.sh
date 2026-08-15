#!/usr/bin/env bash
# Weather for waybar: location + icon + temp (Omarchy location.conf city).
set -euo pipefail

city="Ningbo"
loc="${HOME}/.config/omarchy/location.conf"
if [[ -f "${loc}" ]]; then
  # shellcheck disable=SC1090
  source "${loc}"
  city="${city:-Ningbo}"
fi

CACHE_DIR="${HOME}/.cache/waybar-status"
CACHE="${CACHE_DIR}/weather.json"
TTL=600
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/power.sh"
if waybar_on_battery; then
  TTL=900
fi
mkdir -p "${CACHE_DIR}"

if [[ -f "${CACHE}" ]]; then
  cached_city="$(python3 -c 'import json,sys
try:
    print(json.load(open(sys.argv[1])).get("city",""))
except Exception:
    print("")' "${CACHE}" 2>/dev/null || true)"
  age=$(( $(date +%s) - $(stat -c %Y "${CACHE}") ))
  if (( age < TTL )) && [[ "${cached_city}" == "${city}" ]]; then
    cat "${CACHE}"
    exit 0
  fi
fi

query="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "${city}")"
raw="$(curl -fsS --max-time 5 "https://wttr.in/${query}?m&format=%c|%t|%C|%w" 2>/dev/null | tr -d '\n' || true)"

if [[ -z "${raw}" ]]; then
  if [[ -f "${CACHE}" ]]; then
    cat "${CACHE}"
    exit 0
  fi
  # No output = module hidden (empty "text" would print the raw JSON instead).
  exit 0
fi

IFS='|' read -r icon temperature condition wind <<< "${raw}"
icon="$(echo -n "${icon}" | xargs)"
temperature="${temperature#+}"
temperature="$(echo -n "${temperature}" | xargs)"
condition="$(echo -n "${condition}" | xargs)"
wind="$(echo -n "${wind}" | xargs)"

text="${city} ${icon} ${temperature}"
tooltip="$(printf '%s\n%s · %s\nWind %s' "${city}" "${condition}" "${temperature}" "${wind}")"

python3 -c '
import json, sys
print(json.dumps({"text": sys.argv[1], "tooltip": sys.argv[2], "class": "ok", "city": sys.argv[3]}, ensure_ascii=False))
' "${text}" "${tooltip}" "${city}" | tee "${CACHE}"

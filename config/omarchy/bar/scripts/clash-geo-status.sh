#!/usr/bin/env bash
# Clash Verge proxy egress geo for waybar.
# Shows real rule-mode selector (主代理 → leaf node), not GLOBAL / stale Dual Net.
set -euo pipefail

CACHE_DIR="${HOME}/.cache/waybar-status"
CACHE="${CACHE_DIR}/clash-geo.json"
TTL=600
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/power.sh"
if waybar_on_battery; then
  TTL=900
fi
MIXED="http://127.0.0.1:7897"
SOCK="/tmp/verge/verge-mihomo.sock"

mkdir -p "${CACHE_DIR}"

urlenc() {
  python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

proxy_now() {
  local name="$1"
  [[ -S "${SOCK}" ]] || return 0
  curl -sf --unix-socket "${SOCK}" --max-time 2 \
    "http://localhost/proxies/$(urlenc "${name}")" 2>/dev/null \
    | jq -r '.now // empty' 2>/dev/null || true
}

proxy_type() {
  local name="$1"
  [[ -S "${SOCK}" ]] || return 0
  curl -sf --unix-socket "${SOCK}" --max-time 2 \
    "http://localhost/proxies/$(urlenc "${name}")" 2>/dev/null \
    | jq -r '.type // empty' 2>/dev/null || true
}

# Active rule-mode path: 主代理 → (optional nested group) → leaf
selector="主代理"
node="$(proxy_now "${selector}")"
if [[ -z "${node}" ]]; then
  selector="GLOBAL"
  node="$(proxy_now "${selector}")"
fi

leaf=""
if [[ -n "${node}" ]]; then
  case "$(proxy_type "${node}")" in
    Selector|URLTest|Fallback|LoadBalance)
      leaf="$(proxy_now "${node}")"
      ;;
  esac
fi

spotify_node="$(proxy_now "香港自动" 2>/dev/null || true)"

geo_ok() {
  echo "$1" | jq -e '
    type == "object"
    and (has("error") | not)
    and (.status != "fail")
    and (.status != 429)
    and (
      ((.ip // .query // "") | length) > 0
      or ((.countryCode // .country_code // .cc // "") | length) > 0
    )
  ' >/dev/null 2>&1
}

use_cache=0
if [[ -f "${CACHE}" ]]; then
  cached="$(cat "${CACHE}" 2>/dev/null || true)"
  age=$(( $(date +%s) - $(stat -c %Y "${CACHE}") ))
  if (( age < TTL )) && geo_ok "${cached}"; then
    use_cache=1
  else
    rm -f "${CACHE}"
  fi
fi

if (( use_cache == 0 )); then
  geo=""
  for url in \
    'http://ip-api.com/json/?fields=status,country,countryCode,city,query' \
    'https://api.myip.com' \
    'https://ifconfig.co/json' \
    'https://ipinfo.io/json'; do
    geo="$(curl -sx "${MIXED}" --max-time 8 -sS "${url}" 2>/dev/null || true)"
    if [[ -n "${geo}" ]] && geo_ok "${geo}"; then
      printf '%s\n' "${geo}" > "${CACHE}"
      break
    fi
    geo=""
  done
fi

python3 - <<'PY' "${CACHE}" "${selector}" "${node}" "${leaf}" "${spotify_node}"
import json, sys
from pathlib import Path
cache = Path(sys.argv[1])
selector, node, leaf, spotify = sys.argv[2:6]

if not cache.exists():
    print(json.dumps({"text": "󰇧 ?", "tooltip": "Clash geo unavailable", "class": "missing"}))
    raise SystemExit(0)
try:
    data = json.loads(cache.read_text())
except Exception:
    print(json.dumps({"text": "󰇧 ?", "tooltip": "Bad geo cache", "class": "error"}))
    raise SystemExit(0)

if data.get("error") or data.get("status") in ("fail", 429):
    print(json.dumps({"text": "󰇧 ?", "tooltip": "Geo lookup failed (rate limit?)", "class": "error"}))
    raise SystemExit(0)

country = data.get("country") or ""
city = data.get("city") or data.get("region") or ""
ip = data.get("ip") or data.get("query") or "?"
code = data.get("countryCode") or data.get("country_code") or data.get("cc") or ""
if not code and isinstance(country, str) and len(country) == 2:
    code = country
if not code and isinstance(country, str) and country:
    code = country[:2].upper()
if not code:
    code = "?"

short_city = city.split(",")[0].strip() if city else ""
if short_city:
    text = f"󰇧 {code}·{short_city}"
else:
    text = f"󰇧 {code}"
if len(text) > 22:
    text = text[:20] + "…"

tip = f"Egress: {ip}"
loc = ", ".join(p for p in (city, country or code) if p)
if loc:
    tip += f"\n{loc}"
if node:
    path = f"{selector} → {node}"
    if leaf:
        path += f" → {leaf}"
    tip += f"\nNode: {path}"
if spotify:
    tip += f"\nSpotify: {spotify}"
# HK egress would be wrong for Claude — flag if leaf looks HK
check = leaf or node or ""
if any(k in check for k in ("香港", "HK", "Hong Kong")):
    tip += "\n⚠ main path looks HK — Claude may break"
    cls = "warn"
else:
    cls = "ok"
print(json.dumps({"text": text, "tooltip": tip, "class": cls}, ensure_ascii=False))
PY

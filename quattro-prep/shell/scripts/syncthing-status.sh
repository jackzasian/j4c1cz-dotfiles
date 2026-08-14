#!/usr/bin/env bash
# Syncthing status for waybar (Docker omarchy-syncthing + REST fallback).
set -euo pipefail

api_key=""
cfg="${HOME}/.local/state/syncthing/config.xml"
if [[ -f "${cfg}" ]]; then
  api_key="$(rg -oP '(?<=<apikey>)[^<]+' "${cfg}" 2>/dev/null | head -1 || true)"
fi

docker_health=""
if command -v docker >/dev/null 2>&1; then
  docker_health="$(docker inspect -f '{{.State.Health.Status}}' omarchy-syncthing 2>/dev/null || true)"
  if [[ -z "${docker_health}" ]]; then
    st="$(docker inspect -f '{{.State.Status}}' omarchy-syncthing 2>/dev/null || true)"
    [[ "${st}" == "running" ]] && docker_health="running"
  fi
fi

connections_json=""
if [[ -n "${api_key}" ]]; then
  connections_json="$(curl -sf -H "X-API-Key: ${api_key}" --max-time 3 \
    http://127.0.0.1:8384/rest/system/connections 2>/dev/null || true)"
fi

python3 - <<'PY' "${docker_health}" "${connections_json}"
import json, sys
health = sys.argv[1] or ""
conn_raw = sys.argv[2] or ""

connected = 0
total = 0
if conn_raw:
    try:
        data = json.loads(conn_raw)
        conns = data.get("connections") or {}
        total = len(conns)
        connected = sum(1 for c in conns.values() if c.get("connected"))
    except Exception:
        pass

if health in ("healthy", "running") or connected > 0:
    if connected > 0:
        text = f"󱘖 {connected}"
        cls = "ok"
        tip = f"Syncthing up\nPeers connected: {connected}/{total or connected}\nDocker: {health or 'n/a'}"
    else:
        text = "󱘖"
        cls = "idle"
        tip = f"Syncthing {health or 'up'}\nNo peers connected yet"
elif health == "unhealthy":
    text = "󱘖 !"
    cls = "error"
    tip = "Syncthing unhealthy"
elif health:
    text = "󱘖 ·"
    cls = "degraded"
    tip = f"Syncthing: {health}"
else:
    text = "󱘖 ↓"
    cls = "offline"
    tip = "Syncthing down (no docker / API)"

print(json.dumps({"text": text, "tooltip": tip, "class": cls}, ensure_ascii=False))
PY

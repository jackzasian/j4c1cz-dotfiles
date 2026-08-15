#!/usr/bin/env bash
# Syncthing status for waybar (systemd syncthing.service + REST fallback).
set -euo pipefail

api_key=""
cfg="${HOME}/.local/state/syncthing/config.xml"
if [[ -f "${cfg}" ]]; then
  api_key="$(rg -oP '(?<=<apikey>)[^<]+' "${cfg}" 2>/dev/null | head -1 || true)"
fi

svc_health=""
if command -v systemctl >/dev/null 2>&1; then
  case "$(systemctl --user is-active syncthing 2>/dev/null || true)" in
    active)   svc_health="running" ;;
    failed)   svc_health="unhealthy" ;;
    inactive) svc_health="" ;;
  esac
fi

connections_json=""
if [[ -n "${api_key}" ]]; then
  connections_json="$(curl -sk -L -H "X-API-Key: ${api_key}" --max-time 3 \
    https://127.0.0.1:8384/rest/system/connections 2>/dev/null || true)"
fi

python3 - <<'PY' "${svc_health}" "${connections_json}"
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
        text = f" {connected}"
        cls = "ok"
        tip = f"Syncthing up\nPeers connected: {connected}/{total or connected}\nService: {health or 'n/a'}"
    else:
        text = ""
        cls = "idle"
        tip = f"Syncthing {health or 'up'}\nNo peers connected yet"
elif health == "unhealthy":
    text = " !"
    cls = "error"
    tip = "Syncthing unhealthy"
elif health:
    text = " ·"
    cls = "degraded"
    tip = f"Syncthing: {health}"
else:
    text = " ↓"
    cls = "offline"
    tip = "Syncthing down (no service / API)"

print(json.dumps({"text": text, "tooltip": tip, "class": cls}, ensure_ascii=False))
PY

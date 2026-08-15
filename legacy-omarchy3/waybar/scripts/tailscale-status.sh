#!/usr/bin/env bash
# Tailscale status for waybar.
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1; then
  printf '{"text":"","tooltip":"tailscale not installed","class":"missing"}\n'
  exit 0
fi

json="$(tailscale status --json 2>/dev/null || true)"
if [[ -z "${json}" ]]; then
  printf '{"text":"󰈀 ↓","tooltip":"Tailscale unreachable","class":"offline"}\n'
  exit 0
fi

python3 - <<'PY' "${json}"
import json, sys
data = json.loads(sys.argv[1])
backend = data.get("BackendState") or "Unknown"
self = data.get("Self") or {}
online = bool(self.get("Online"))
ips = self.get("TailscaleIPs") or []
ip = ips[0] if ips else "?"
peers = data.get("Peer") or {}
peer_online = sum(1 for p in peers.values() if p.get("Online"))
peer_total = len(peers)

if backend == "Running" and online:
    text = "󰈀"
    cls = "online"
elif backend == "Running":
    text = "󰈀 ·"
    cls = "degraded"
else:
    text = "󰈀 ↓"
    cls = "offline"

tip = f"Tailscale {backend}\nSelf: {ip}\nOnline: {online}\nPeers online: {peer_online}/{peer_total}"
# List a few online peers
names = []
for p in peers.values():
    if p.get("Online"):
        names.append(p.get("HostName") or p.get("DNSName") or "?")
names = sorted(names)[:8]
if names:
    tip += "\n" + "\n".join(f"· {n}" for n in names)

print(json.dumps({"text": text, "tooltip": tip, "class": cls}, ensure_ascii=False))
PY

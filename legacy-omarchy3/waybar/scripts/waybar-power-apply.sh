#!/usr/bin/env bash
# Adjust waybar poll intervals for AC vs battery. Restarts waybar when mode or intervals change.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/power.sh"

STATE_DIR="${HOME}/.cache/waybar-status"
STATE_FILE="${STATE_DIR}/power-mode"
CONFIG="${HOME}/.config/waybar/config.jsonc"
mkdir -p "${STATE_DIR}"

if waybar_on_battery; then
  mode="battery"
else
  mode="ac"
fi

prev="$(cat "${STATE_FILE}" 2>/dev/null || true)"

out="$(python3 - <<'PY' "${CONFIG}" "${mode}"
import json, sys
path, mode = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)

intervals = {
    "battery": {
        "custom/tasknotes": 300,
        "custom/spotify": 5,
        "custom/claude": 3,
        "custom/agents": 30,
        "custom/tailscale": 300,
        "custom/syncthing": 300,
        "custom/clash-geo": 120,
        "custom/weather": 900,
    },
    "ac": {
        "custom/tasknotes": 20,
        "custom/spotify": 2,
        "custom/claude": 2,
        "custom/agents": 10,
        "custom/tailscale": 15,
        "custom/syncthing": 15,
        "custom/clash-geo": 60,
        "custom/weather": 600,
    },
}[mode]

changed = False
bars = data if isinstance(data, list) else [data]
for bar in bars:
    for key, interval in intervals.items():
        mod = bar.get(key)
        if isinstance(mod, dict) and mod.get("interval") != interval:
            mod["interval"] = interval
            changed = True

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("changed" if changed else "unchanged")
PY
)"

echo "${mode}" > "${STATE_FILE}"

need_restart=0
[[ "${prev}" != "${mode}" ]] && need_restart=1
[[ "${out}" == "changed" ]] && need_restart=1
[[ "${WAYBAR_FORCE_RESTART:-0}" == "1" ]] && need_restart=1
pgrep -x waybar >/dev/null 2>&1 || need_restart=1

if (( need_restart == 1 )); then
  "${SCRIPT_DIR}/waybar-restart.sh"
fi

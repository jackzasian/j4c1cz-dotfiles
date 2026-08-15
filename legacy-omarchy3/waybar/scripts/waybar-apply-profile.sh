#!/usr/bin/env bash
# Apply docked vs laptop waybar profile based on connected monitors.
set -euo pipefail

WAYBAR_DIR="${HOME}/.config/waybar"
STATE_DIR="${HOME}/.cache/waybar-status"
STATE_FILE="${STATE_DIR}/profile"
LOCK_DIR="${STATE_DIR}/profile.lock"
mkdir -p "${STATE_DIR}"

# Serialize restarts when multiple monitor events fire
if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
  # Another instance is applying; wait briefly then exit (it will re-check)
  sleep 1
  exit 0
fi
trap 'rmdir "${LOCK_DIR}" 2>/dev/null || true' EXIT

sleep 0.4  # let hypr settle after plug/unplug

monitors_json="$(hyprctl monitors -j 2>/dev/null || echo '[]')"
mapfile -t externals < <(python3 - <<'PY' "${monitors_json}"
import json, sys
mons = json.loads(sys.argv[1])
ext = []
for m in mons:
    name = m.get("name") or ""
    if name and name != "eDP-1":
        # prefer largest by pixel area
        area = int(m.get("width") or 0) * int(m.get("height") or 0)
        ext.append((area, name))
ext.sort(reverse=True)
for _, name in ext:
    print(name)
PY
)

if ((${#externals[@]} > 0)); then
  profile="docked"
  primary="${externals[0]}"
  src="${WAYBAR_DIR}/config.docked.jsonc"
  # Inject primary external output into a single-bar config
  python3 - <<'PY' "${src}" "${WAYBAR_DIR}/config.jsonc" "${primary}"
import json, sys, re
src, dst, primary = sys.argv[1:4]
text = open(src).read()
# strip // comments for parse (jsonc)
lines = []
for line in text.splitlines():
    stripped = line.lstrip()
    if stripped.startswith("//"):
        continue
    lines.append(line)
clean = "\n".join(lines)
# remove trailing commas before } or ]
clean = re.sub(r",\s*([}\]])", r"\1", clean)
data = json.loads(clean)
if isinstance(data, list) and data:
    data[0]["output"] = [primary]
    data[0]["name"] = "external"
open(dst, "w").write(json.dumps(data, indent=2) + "\n")
PY
else
  profile="laptop"
  src="${WAYBAR_DIR}/config.laptop.jsonc"
  cp -f "${src}" "${WAYBAR_DIR}/config.jsonc"
fi

prev="$(cat "${STATE_FILE}" 2>/dev/null || true)"
echo "${profile}:${primary:-eDP-1}" > "${STATE_FILE}"

# Patch AC/battery intervals onto the fresh config, then restart when needed
if [[ "${prev}" != "${profile}:${primary:-eDP-1}" ]]; then
  export WAYBAR_FORCE_RESTART=1
fi
~/.config/waybar/scripts/waybar-power-apply.sh >/dev/null 2>&1 || {
  ~/.config/waybar/scripts/waybar-restart.sh >/dev/null 2>&1 || true
}

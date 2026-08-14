# Profile switching (laptop vs docked) — design

**This is new code, not a port.** Waybar had 3 config profiles
(`config.jsonc` / `config.docked.jsonc` / `config.laptop.jsonc`) switched by
`waybar-monitor-watch.sh` on Hyprland `monitoradded`/`monitorremoved` events.
Quattro's `shell.json` has no profile concept — everything lives in one layout.

## The gap

- `shell.json` has a single `bar.layout` with no conditional sections
- There is no `omarchy bar profile` command
- `omarchy bar put` / `omarchy bar move` operate on the running layout
- `omarchy-shell shell reloadConfig` re-reads the entire `shell.json` from disk

The simplest approach: a script that rewrites `shell.json` and reloads.

## Design

### Script: `profile-switch.sh`

Triggered by the same Hyprland socket2 events as `waybar-monitor-watch.sh`:

```bash
#!/usr/bin/env bash
# Switch omarchy-shell bar layout between laptop and docked profiles.
# Triggered by Hyprland monitoradded/monitorremoved events.
set -euo pipefail

SHELL_JSON="$HOME/.config/omarchy/shell.json"
DOCKED_LAYOUT="$HOME/.config/omarchy/bar/layout-docked.json"
LAPTOP_LAYOUT="$HOME/.config/omarchy/bar/layout-laptop.json"
LOCK_DIR="$HOME/.cache/omarchy-bar/profile-switch.lock"

# Serialize runs
mkdir -p "$HOME/.cache/omarchy-bar"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  sleep 1
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

sleep 0.4  # let hypr settle

# Determine profile
monitors="$(hyprctl monitors -j 2>/dev/null || echo '[]')"
external_count="$(python3 -c "
import json, sys
mons = json.loads(sys.argv[1])
print(sum(1 for m in mons if m.get('name') != 'eDP-1'))
" "$monitors")"

if (( external_count > 0 )); then
  layout_file="$DOCKED_LAYOUT"
  profile="docked"
else
  layout_file="$LAPTOP_LAYOUT"
  profile="laptop"
fi

# Swap only the layout section
if [[ -f "$layout_file" ]]; then
  python3 -c "
import json, sys
shell = json.load(open(sys.argv[1]))
layout = json.load(open(sys.argv[2]))
shell['bar']['layout'] = layout
json.dump(shell, open(sys.argv[1], 'w'), indent=2)
" "$SHELL_JSON" "$layout_file"

  omarchy-shell -q shell reloadConfig 2>/dev/null || true
  echo "Switched to $profile profile"
fi
```

### Layout snippets

`layout-docked.json` (full bar, as in `shell.json`):
```json
{
  "left": [ ... same as shell.json left ... ],
  "center": [ ... same as shell.json center ... ],
  "right": [ ... same as shell.json right ... ]
}
```

`layout-laptop.json` (sparse, from `config.laptop.jsonc`):
```json
{
  "left": [
    { "id": "omarchy.menu" },
    { "id": "omarchy.workspaces" }
  ],
  "center": [
    { "id": "omarchy.clock", "format": "dddd HH:mm", "formatAlt": "d MMMM 'W'ww yyyy" },
    { "id": "tasknotes", "type": "command", "exec": "~/.config/omarchy/bar/scripts/tasknotes-upcoming.py", "interval": 20, "tooltip": true, "onClick": "omarchy-shell -q shell reloadConfig; uwsm-app -- obsidian", "onClickRight": "~/.config/omarchy/bar/scripts/tasknotes-upcoming.py --force >/dev/null; omarchy-shell -q shell reloadConfig" },
    { "id": "voxtype", "type": "command", "exec": "omarchy-voxtype-status", "interval": 5, "tooltip": true, "onClick": "omarchy-voxtype-model", "onClickRight": "omarchy-voxtype-config" },
    { "id": "omarchy.indicators", "items": ["ScreenRecording", "Dnd"] },
    { "id": "omarchy.weather" },
    { "id": "omarchy.system-update" }
  ],
  "right": [
    { "id": "omarchy.tray" },
    { "id": "hermes-gateway", "type": "command", "exec": "~/.config/omarchy/bar/scripts/agents-status.sh", "interval": 10, "tooltip": true },
    { "id": "clash-geo", "type": "command", "exec": "~/.config/omarchy/bar/scripts/clash-geo-status.sh", "interval": 60, "tooltip": true, "onClick": "uwsm-app -- clash-verge", "onClickRight": "rm -f ~/.cache/waybar-status/clash-geo.json; omarchy-shell -q shell reloadConfig" },
    { "id": "omarchy.tailscale" },
    { "id": "syncthing", "type": "command", "exec": "~/.config/omarchy/bar/scripts/syncthing-status.sh", "interval": 15, "tooltip": true, "onClick": "xdg-open http://127.0.0.1:8384" },
    { "id": "kdeconnect", "type": "command", "exec": "~/.config/omarchy/bar/scripts/kdeconnect-status.sh", "interval": 5, "onClick": "uwsm-app -- kdeconnect-app", "tooltip": true },
    { "id": "omarchy.bluetooth" },
    { "id": "omarchy.monitor" },
    { "id": "omarchy.audio" },
    { "id": "omarchy.microphone" },
    { "id": "omarchy.network" },
    { "id": "omarchy.power" }
  ]
}
```

Key differences from docked:
- **AI tool chips removed** (claude-code, cursor, claude-desktop, opencode) — these only appear on the Studio Display
- Rest of the widgets are the same since Quattro renders widgets responsively

### Trigger: Hyprland autostart

Two entries needed in `hyprland.lua` (already ported in `quattro-prep/hypr-lua/`):

```lua
-- Replace the old waybar exec-once entries in autostart.lua:
hl.exec_on_start("~/.config/omarchy/bar/scripts/profile-switch.sh")
hl.exec_on_start("~/.config/omarchy/bar/scripts/profile-watch.sh")
```

### profile-watch.sh

Listens on Hyprland socket2 for monitor events, identical pattern to
`waybar-monitor-watch.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
APPLY="$HOME/.config/omarchy/bar/scripts/profile-switch.sh"
socat -U - "UNIX-CONNECT:${SOCKET}" | while read -r event; do
  case "${event}" in
    monitoradded\>\>*|monitoraddedv2\>\>*|monitorremoved\>\>*|monitorremovedv2\>\>*)
      "${APPLY}" || true
      ;;
  esac
done
```

## Open design questions

1. **Is `reloadConfig` fast enough for hotplugs?** Reloading the entire config on
   every monitor plug/unplug may feel sluggish if `omarchy-shell` has to tear
   down and recreate many widgets. If it is, explore `omarchy bar put` / `omarchy
   bar move` IPC calls to add/remove individual widgets without a full reload.

2. **Should laptop mode reduce intervals?** The old `waybar-power-apply.sh`
   doubled poll intervals on battery. Quattro has no native interval scaling.
   If battery life matters, call `omarchy bar set <id> interval <n>` for each
   widget on AC change — but that requires each widget to support `setBarWidget`
   (built-ins do; inline command widgets may not).

3. **Drawer replacement.** The old `group/apps` and `group/more` used animated
   drawers to hide groups on the cramped laptop screen. Quattro has no drawer
   concept. The laptop layout above simply omits widgets. If that feels too
   sparse, investigate whether a custom QML widget could replicate the drawer.

4. **oom:** could this be done entirely via `omarchy bar put` / `move` / IPC
   without a file-rewrite approach? Probably — but the script above is simpler
   to verify against the alpha docs and can be refined once the stable release
   ships.

## Status

This is a design document, not a tested implementation. The script above is
syntactic pseudocode — field-test it against the real `omarchy-shell` before
trusting it. It assumes:
- `omarchy-shell -q shell reloadConfig` reloads the bar layout from disk
- `python3` is available (it is, on this machine)
- `socat` is installed (it is, for hyprctl socket access)

**Marked as new code** — not a translation of any existing waybar mechanism.

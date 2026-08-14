#!/usr/bin/env bash
# Re-apply the waybar docked/laptop profile on monitor hotplug.
#
# Hyprland's `bind`/`bindl` only intercepts real input (keys, mouse, lid
# switch) — there is no keysym for "monitoradded", so a bind on it silently
# never fires. Monitor hotplug is only observable via the socket2 IPC event
# stream, so we listen there instead (same pattern as
# omarchy-hyprland-monitor-watch, which only handles monitorremoved).
set -euo pipefail

SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
APPLY="${HOME}/.config/waybar/scripts/waybar-apply-profile.sh"

socat -U - "UNIX-CONNECT:${SOCKET}" | while read -r event; do
  case "${event}" in
    monitoradded\>\>*|monitoraddedv2\>\>*|monitorremoved\>\>*|monitorremovedv2\>\>*)
      "${APPLY}" || true
      ;;
  esac
done

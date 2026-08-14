#!/usr/bin/env bash
# Shared power helper for waybar scripts. Exit 0 if on battery, 1 if on AC/USB power.
waybar_on_battery() {
  local d type online
  local saw_adapter=0
  for d in /sys/class/power_supply/*; do
    [[ -r "${d}/type" ]] || continue
    type="$(cat "${d}/type" 2>/dev/null || true)"
    case "${type}" in
      Mains|USB) ;;
      *) continue ;;
    esac
    saw_adapter=1
    online="$(cat "${d}/online" 2>/dev/null || echo 0)"
    online="${online//$'\n'/}"
    if [[ "${online}" == "1" ]]; then
      return 1  # Externed / AC / USB-C power
    fi
  done
  if (( saw_adapter == 1 )); then
    return 0  # Adapters present but none online → battery
  fi
  return 1  # No laptop adapters → don't throttle
}

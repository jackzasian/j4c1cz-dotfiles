#!/usr/bin/env bash

device_id="$(kdeconnect-cli -a --id-only 2>/dev/null | head -1)"
device_name="$(kdeconnect-cli -a --name-only 2>/dev/null | head -1)"

if [[ -z "$device_id" ]]; then
  # No output = module hidden. (Emitting {"text":""} instead makes the bar
  # dump the raw JSON onto itself; a zero-width space leaves a dead gap.)
  exit 0
fi

battery_path="/modules/kdeconnect/devices/${device_id}/battery"
charge="$(busctl --user get-property org.kde.kdeconnect "$battery_path" org.kde.kdeconnect.device.battery charge 2>/dev/null | awk '{print $2}')"
charging="$(busctl --user get-property org.kde.kdeconnect "$battery_path" org.kde.kdeconnect.device.battery isCharging 2>/dev/null | awk '{print $2}')"

if [[ -n "$charge" && "$charge" =~ ^[0-9]+$ ]]; then
  icon="󰄋"
  [[ "$charging" == "true" ]] && icon="󰄥"
  printf '{"text":"%s%% %s","tooltip":"%s · %s%%","class":"connected"}\n' "$charge" "$icon" "$device_name" "$charge"
else
  printf '{"text":"󰜄","tooltip":"%s connected","class":"connected"}\n' "$device_name"
fi

#!/usr/bin/env bash
# Watch AC/USB power and re-apply waybar poll intervals. Single-instance only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY="${SCRIPT_DIR}/waybar-power-apply.sh"
LOCK="${HOME}/.cache/waybar-status/power-watch.lock"
mkdir -p "${HOME}/.cache/waybar-status"

# Ensure only one watcher
exec 9>"${LOCK}"
if ! flock -n 9; then
  exit 0
fi

"${APPLY}" || true

targets=()
for d in /sys/class/power_supply/*; do
  [[ -r "${d}/type" ]] || continue
  type="$(cat "${d}/type" 2>/dev/null || true)"
  case "${type}" in
    Mains|USB)
      [[ -r "${d}/online" ]] && targets+=("${d}/online")
      ;;
  esac
done

if ((${#targets[@]} > 0)) && command -v inotifywait >/dev/null 2>&1; then
  while inotifywait -q -e modify -e attrib "${targets[@]}" >/dev/null 2>&1; do
    sleep 0.8
    "${APPLY}" || true
  done
else
  # Seed so we don't re-apply immediately after startup apply above
  prev="$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo x)"
  for d in /sys/class/power_supply/ucsi-source-psy-*/online; do
    [[ -r "${d}" ]] && prev+="$(cat "${d}")"
  done
  while true; do
    cur="$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo x)"
    for d in /sys/class/power_supply/ucsi-source-psy-*/online; do
      [[ -r "${d}" ]] && cur+="$(cat "${d}")"
    done
    if [[ "${cur}" != "${prev}" ]]; then
      "${APPLY}" || true
      prev="${cur}"
    fi
    sleep 15
  done
fi

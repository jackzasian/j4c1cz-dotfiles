#!/usr/bin/env bash
# Single-flight waybar restart — kills all instances, waits, starts exactly one
# inside the live Hyprland/UWSM session so workspace-taskbar IPC works.
set -euo pipefail

LOCK_DIR="${HOME}/.cache/waybar-status/restart.lock"
mkdir -p "${HOME}/.cache/waybar-status"

if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
  for _ in $(seq 1 50); do
    [[ -d "${LOCK_DIR}" ]] || break
    sleep 0.1
  done
  if pgrep -x waybar >/dev/null 2>&1; then
    exit 0
  fi
  mkdir "${LOCK_DIR}" 2>/dev/null || exit 0
fi
trap 'rmdir "${LOCK_DIR}" 2>/dev/null || true' EXIT

# Attach to the newest live Hyprland instance
uid="$(id -u)"
hypr_root="/run/user/${uid}/hypr"
if [[ -d "${hypr_root}" ]]; then
  newest=""
  newest_mtime=0
  for d in "${hypr_root}"/*; do
    [[ -S "${d}/.socket.sock" ]] || continue
    mtime=$(stat -c %Y "${d}/.socket.sock" 2>/dev/null || echo 0)
    if (( mtime >= newest_mtime )); then
      newest_mtime=$mtime
      newest="$(basename "${d}")"
    fi
  done
  if [[ -n "${newest}" ]]; then
    export HYPRLAND_INSTANCE_SIGNATURE="${newest}"
  fi
fi

# Wayland display from session if missing
if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  if [[ -S "/run/user/${uid}/wayland-1" ]]; then
    export WAYLAND_DISPLAY=wayland-1
  elif [[ -S "/run/user/${uid}/wayland-0" ]]; then
    export WAYLAND_DISPLAY=wayland-0
  fi
fi
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${uid}}"

pkill -9 -x waybar 2>/dev/null || true
for _ in $(seq 1 40); do
  pgrep -x waybar >/dev/null 2>&1 || break
  sleep 0.05
done
pkill -9 -x waybar 2>/dev/null || true
sleep 0.15

# Prefer launching via Hyprland so the bar inherits compositor env
started=0
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
  if hyprctl dispatch exec "uwsm-app -- waybar" >/dev/null 2>&1; then
    started=1
  fi
fi

if (( started == 0 )); then
  setsid uwsm-app -- waybar >/dev/null 2>&1 &
  disown || true
fi

for _ in $(seq 1 40); do
  if pgrep -x waybar >/dev/null 2>&1; then
    mapfile -t pids < <(pgrep -x waybar | sort -n)
    if ((${#pids[@]} > 1)); then
      for ((i = 1; i < ${#pids[@]}; i++)); do
        kill -9 "${pids[i]}" 2>/dev/null || true
      done
    fi
    exit 0
  fi
  sleep 0.1
done

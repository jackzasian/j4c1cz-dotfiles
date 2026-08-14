#!/bin/bash
# Hyprspace for Hyprland 0.56 — 0xl30 fork (upstream KZDKM pins stop earlier).
# Run in your Hyprland session: bash ~/.config/hypr/install-hyprspace.sh
set -euo pipefail

LOG="${HOME}/.config/hypr/.hyprspace-install.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== $(date -Iseconds) install-hyprspace.sh ==="

# Clash / fake-ip: git and hyprpm need proxy on this machine
# shellcheck source=/dev/null
[[ -f "${HOME}/.config/omarchy/proxy.sh" ]] && source "${HOME}/.config/omarchy/proxy.sh"
proxy_on 2>/dev/null || true
export GIT_TERMINAL_PROMPT=0

if ! hyprctl version &>/dev/null; then
  echo "ERROR: hyprctl cannot reach Hyprland. Run on the machine with your graphical session."
  exit 1
fi

# Already healthy — do not remove/rebuild (avoids safe-mode loops)
if hyprctl plugin list 2>/dev/null | grep -qi hyprspace; then
  ERR=$(hyprctl configerrors 2>/dev/null || true)
  if [[ -z ${ERR//[[:space:]]/} ]]; then
    echo "OK: Hyprspace already loaded and configerrors empty — skipping rebuild."
    echo "Overview binds must stay as: exec, hyprctl dispatch overview:toggle"
    exit 0
  fi
  echo "WARN: Hyprspace loaded but configerrors present — continuing repair."
  echo "$ERR"
fi

if ! pacman -Q hyprland-protocols &>/dev/null; then
  echo "ERROR: hyprland-protocols not installed (needed for hyprpm headers)."
  echo "Install: sudo pacman -S --needed hyprland-protocols"
  exit 1
fi

echo "--- remove hyprtasking ---"
yes | hyprpm -f disable hyprtasking 2>/dev/null || true
yes | hyprpm -f remove hyprtasking 2>/dev/null || true

echo "--- remove existing Hyprspace repo (if any) ---"
yes | hyprpm -f disable Hyprspace 2>/dev/null || true
yes | hyprpm -f remove Hyprspace 2>/dev/null || true

# Fix For Hyprland v0.56.0 (0xl30 / ImanolBarba)
HYPRSPACE_URL="https://github.com/0xl30/Hyprspace"
HYPRSPACE_COMMIT="8b4284e123bd"

echo "--- ensure hyprpm headers ---"
hyprpm update -f 2>/dev/null || true

echo "--- add Hyprspace (0.56 fork) ---"
yes | hyprpm -f add "${HYPRSPACE_URL}" "${HYPRSPACE_COMMIT}"

echo "--- enable Hyprspace (note capital H) ---"
yes | hyprpm -f enable Hyprspace
hyprpm reload -n

echo "--- plugin list ---"
hyprctl plugin list | tee -a "$LOG"

if ! hyprctl plugin list 2>/dev/null | grep -qi hyprspace; then
  echo ""
  echo "BUILD FAILED. Verbose log:"
  hyprpm enable -v Hyprspace 2>&1 | tail -60 || true
  echo ""
  echo "See ${LOG}"
  exit 1
fi

ERR=$(hyprctl configerrors)
echo "--- configerrors ---"
echo "${ERR:-(none)}"
if [ -n "$ERR" ]; then
  exit 1
fi

echo "OK: Hyprspace loaded. Super+\` uses exec+hyprctl (see bindings.conf)."

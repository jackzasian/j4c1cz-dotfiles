#!/bin/bash
# Hyprspace for Hyprland 0.55 — upstream KZDKM/main does not build; use 0xl30's 0.55 fork.
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

echo "--- remove hyprtasking ---"
yes | hyprpm -f disable hyprtasking 2>/dev/null || true
yes | hyprpm -f remove hyprtasking 2>/dev/null || true

echo "--- remove broken upstream Hyprspace repo (if any) ---"
yes | hyprpm -f disable Hyprspace 2>/dev/null || true
yes | hyprpm -f remove Hyprspace 2>/dev/null || true

# PR #230: Hyprland v0.55 API compatibility (0xl30 fork)
HYPRSPACE_URL="https://github.com/0xl30/Hyprspace"
HYPRSPACE_COMMIT="628d88122ac5ded7334618e516fed4dd227edc6e"

echo "--- add Hyprspace (0.55 fork) ---"
yes | hyprpm -f add "${HYPRSPACE_URL}" "${HYPRSPACE_COMMIT}"

echo "--- enable Hyprspace (note capital H) ---"
yes | hyprpm -f enable Hyprspace
hyprpm -f update 2>/dev/null || hyprpm update -f 2>/dev/null || true
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

HYPR_CONF="${HOME}/.config/hypr/hyprland.conf"
if grep -q '^# source = ~/.config/hypr/hyprspace-binds.conf' "$HYPR_CONF"; then
  sed -i 's|^# source = ~/.config/hypr/hyprspace-binds.conf|source = ~/.config/hypr/hyprspace-binds.conf|' "$HYPR_CONF"
  echo "Enabled hyprspace-binds.conf in hyprland.conf"
fi

hyprctl reload
ERR=$(hyprctl configerrors)
echo "--- configerrors ---"
echo "${ERR:-(none)}"
if [ -n "$ERR" ]; then
  exit 1
fi

echo "OK: Hyprspace loaded. Super+\` or 4-finger up for overview."

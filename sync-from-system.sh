#!/bin/bash
# Copy current ~/.config (and shell files) into this repo. Run from repo root.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIRS=(
  hypr waybar omarchy fastfetch alacritty foot ghostty kitty mako walker
  swayosd btop lazygit uwsm environment.d git fontconfig
  fcitx5 mise starship.toml
)

mkdir -p "${ROOT}/config" "${ROOT}/home" "${ROOT}/patches"
for item in "${CONFIG_DIRS[@]}"; do
  src="${HOME}/.config/${item}"
  if [[ -e "$src" ]]; then
    if [[ "$item" == *.toml ]]; then
      rsync -a --delete --exclude='*.bak.*' "$src" "${ROOT}/config/"
    else
      mkdir -p "${ROOT}/config/$(dirname "$item")"
      rsync -aL --delete --exclude='*.bak.*' "$src/" "${ROOT}/config/${item}/"
    fi
  fi
done

for f in .bashrc .zshrc .profile .bash_profile; do
  [[ -f "${HOME}/${f}" ]] && cp -f "${HOME}/${f}" "${ROOT}/home/${f}"
done

# Local bin wrappers (no secrets): proxyfix stubs, cursor-tools, pacman-proxy helpers
mkdir -p "${ROOT}/home/.local/bin"
for b in cursor-tools proxyfix clash-secure-localhost omarchy-pacman-proxy-backup omarchy-pacman-proxy-restore omarchy-pacman-proxy-verify omarchy-fix-pacman-install cursor-launch; do
  src="${HOME}/.local/bin/${b}"
  [[ -f "$src" || -L "$src" ]] && cp -a "$src" "${ROOT}/home/.local/bin/"
done

# System safety dump (lists + boot/pacman drop-ins; no secrets)
SNAP="${ROOT}/system"
mkdir -p "${SNAP}/limine-entry-tool.d" "${SNAP}/pacman.d"
pacman -Qq >"${SNAP}/pkglist.txt"
pacman -Qqm >"${SNAP}/aurlist.txt"
pacman -Q >"${SNAP}/pkglist-versions.txt"
date -Iseconds >"${SNAP}/synced-at.txt"
uname -r >>"${SNAP}/synced-at.txt"
[[ -f /etc/pacman.conf ]] && grep -vE '^\s*#' /etc/pacman.conf | grep -vE '^\s*$' >"${SNAP}/pacman.conf.sanitized" || true
[[ -f /etc/pacman.d/mirrorlist ]] && cp -f /etc/pacman.d/mirrorlist "${SNAP}/pacman.d/mirrorlist" || true
[[ -f /etc/pacman.d/curl-proxy.sh ]] && cp -f /etc/pacman.d/curl-proxy.sh "${SNAP}/pacman.d/curl-proxy.sh" || true
if [[ -d /etc/limine-entry-tool.d ]]; then
  # readable drop-ins only (no sudo required for most)
  cp -a /etc/limine-entry-tool.d/*.conf "${SNAP}/limine-entry-tool.d/" 2>/dev/null || true
fi
[[ -f /boot/limine.conf ]] && cp -f /boot/limine.conf "${SNAP}/limine.conf" 2>/dev/null || true

# Drop noisy install logs from the mirrored tree
rm -f "${ROOT}/config/hypr/.hyprspace-install.log"

echo "Synced into ${ROOT}"

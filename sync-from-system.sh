#!/bin/bash
# Copy current ~/.config (and shell files) into this repo. Run from repo root.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIRS=(
  hypr waybar omarchy fastfetch alacritty foot ghostty kitty mako walker
  swayosd btop lazygit uwsm environment.d git fontconfig
  starship.toml
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

for f in .bashrc; do
  [[ -f "${HOME}/${f}" ]] && cp -f "${HOME}/${f}" "${ROOT}/home/${f}"
done

echo "Synced into ${ROOT}"

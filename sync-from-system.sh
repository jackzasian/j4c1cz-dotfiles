#!/bin/bash
# Copy current ~/.config (and shell files) into this repo. Run from repo root.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIRS=(
  hypr waybar omarchy fastfetch alacritty foot ghostty kitty mako walker
  swayosd btop lazygit uwsm environment.d git fontconfig
  fcitx5 mise starship.toml systemd/user
)

mkdir -p "${ROOT}/config" "${ROOT}/home" "${ROOT}/patches"
for item in "${CONFIG_DIRS[@]}"; do
  src="${HOME}/.config/${item}"
  if [[ -e "$src" ]]; then
    if [[ "$item" == *.toml ]]; then
      rsync -a --delete --exclude='*.bak.*' "$src" "${ROOT}/config/"
    else
      mkdir -p "${ROOT}/config/$(dirname "$item")"
      # location.conf holds real home coords/address — keep the repo's redacted copy.
      rsync -aL --delete --exclude='*.bak.*' --exclude='location.conf' \
        "$src/" "${ROOT}/config/${item}/"
    fi
  fi
done

for f in .bashrc .zshrc .profile .bash_profile; do
  [[ -f "${HOME}/${f}" ]] && cp -f "${HOME}/${f}" "${ROOT}/home/${f}"
done

# Local bin: full directory, minus anything that looks like it holds a secret.
mkdir -p "${ROOT}/home/.local/bin"
SECRET_PATTERN='password|token|api[_-]?key|secret|BEGIN (RSA|OPENSSH) PRIVATE KEY'
BIN_SRC="${HOME}/.local/bin/"
FLAGGED="$(grep -rilE "$SECRET_PATTERN" "$BIN_SRC" 2>/dev/null || true)"
BIN_EXCLUDES=()
if [[ -n "$FLAGGED" ]]; then
  echo "WARNING: excluding ${BIN_SRC} files that matched a secret-like pattern (review manually):"
  while IFS= read -r f; do
    echo "  - ${f#$BIN_SRC}"
    BIN_EXCLUDES+=(--exclude="${f#$BIN_SRC}")
  done <<<"$FLAGGED"
fi
# -a (not -aL): keep symlinks as symlinks — several point at large versioned
# tool installs (cursor-agent, python3.11, pipx venvs) that must not be copied in.
rsync -a --delete --exclude='*.bak.*' "${BIN_EXCLUDES[@]}" "$BIN_SRC" "${ROOT}/home/.local/bin/"

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
# Scrub machine identifiers when dumping limine.conf (public repo).
if [[ -f /boot/limine.conf ]]; then
  sed -E \
    -e 's/machine-id=[0-9a-f]{32}/machine-id=<machine-id-redacted>/g' \
    -e 's/PARTUUID=[0-9a-f-]{36}/PARTUUID=<partuuid-redacted>/g' \
    /boot/limine.conf >"${SNAP}/limine.conf" 2>/dev/null || true
fi

# Migration-risk baselines: plugin state, cursor/theme gsettings, timer list
hyprpm list >"${SNAP}/hyprpm-list.txt" 2>/dev/null || true
gsettings list-recursively org.gnome.desktop.interface >"${SNAP}/gsettings-interface.txt" 2>/dev/null || true
systemctl --user list-timers --all --no-pager >"${SNAP}/systemd-user-timers-snapshot.txt" 2>/dev/null || true

# Drop noisy install logs from the mirrored tree
rm -f "${ROOT}/config/hypr/.hyprspace-install.log"

echo "Synced into ${ROOT}"

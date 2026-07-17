#!/usr/bin/env bash
# Rebuild Waybar 0.15.0 with taskbar icon deduplication (groups same app class).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH="${ROOT}/patches/waybar-0.15.0-taskbar-dedup.patch"
BUILD_DIR="${TMPDIR:-/tmp}/waybar-dedup-build"
VERSION="0.15.0"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1" >&2
    echo "Install with: omarchy pkg add base-devel meson ninja gobject-introspection" >&2
    exit 1
  }
}

need meson
need ninja
need gdbus-codegen
need patch
need git

rm -rf "$BUILD_DIR"
git clone --depth 1 --branch "$VERSION" https://github.com/Alexays/Waybar "$BUILD_DIR"
patch -d "$BUILD_DIR" -p1 < "$PATCH"
meson setup "$BUILD_DIR/build" --prefix="$HOME/.local" --buildtype=release
ninja -C "$BUILD_DIR/build"
ninja -C "$BUILD_DIR/build" install
omarchy restart waybar
echo "Installed patched Waybar ${VERSION} to ~/.local/bin (taskbar dedup by app class)."

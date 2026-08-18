#!/usr/bin/env bash
# Install obsidian-capture onto an Omarchy/Hyprland machine.
#
#   ./install.sh              # manual install: symlinks + menu + keybindings + systemd timers
#   ./install.sh --plugin     # service mode: symlinks + menu + keybindings (no timers, no prompts)
#   ./install.sh --no-timers  # manual install without systemd timers
#
# Idempotent: safe to run repeatedly. Exits quickly when already wired.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
STATE_DIR="${HOME}/.local/state/omarchy"
PLUGIN_MODE=0
WITH_TIMERS=0
case " $* " in
  *" --plugin "*) PLUGIN_MODE=1 ;;
esac
case " $* " in
  *" --no-timers "*|*" --plugin "*) WITH_TIMERS=0 ;;
  *) WITH_TIMERS=1 ;;
esac

mkdir -p "$BIN" "$STATE_DIR"

link_bin() {
  local target="$1" name="$2"
  if [[ -L "$BIN/$name" && "$(readlink -f "$BIN/$name")" == "$(readlink -f "$ROOT/bin/$target")" ]]; then
    return 0
  fi
  ln -sfn "$ROOT/bin/$target" "$BIN/$name"
  chmod +x "$ROOT/bin/$target"
  echo "linked $BIN/$name"
}

link_bin obsidian-capture obsidian-capture
for w in obsidian-save-link obsidian-save-note obsidian-save-note-edit obsidian-post-note obsidian-note-dest; do
  link_bin "wrappers/$w" "$w"
done

# Menu entries: merge the plugin fragment into the user's omarchy-menu.jsonc.
MENU_DIR="${HOME}/.config/omarchy/extensions"
MENU_FILE="$MENU_DIR/omarchy-menu.jsonc"
if ! grep -q '"obsidian.save-link"' "$MENU_FILE" 2>/dev/null || ! grep -q '"$HOME/.local/bin/obsidian-capture link"' "$MENU_FILE" 2>/dev/null; then
  python3 "$ROOT/scripts/merge_menu.py" "$ROOT/menu/obsidian-menu.jsonc" "$MENU_FILE"
  echo "merged menu entries into $MENU_FILE"
fi

# Keybindings: ship a fragment that bindings.lua requires once.
BINDINGS_FRAGMENT="$HOME/.config/obsidian-capture.lua"
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
REQUIRE_LINE='require("obsidian-capture")'
if [[ -f "$BINDINGS_FILE" ]] && ! grep -qF "$REQUIRE_LINE" "$BINDINGS_FILE"; then
  cp "$ROOT/hypr/obsidian-capture.lua" "$BINDINGS_FRAGMENT"
  printf '\n-- Added by omarchy-obsidian-capture\n%s\n' "$REQUIRE_LINE" >> "$BINDINGS_FILE"
  echo "added $REQUIRE_LINE to $BINDINGS_FILE"
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
fi

if (( WITH_TIMERS )); then
  SYSTEMD="${HOME}/.config/systemd/user"
  mkdir -p "$SYSTEMD"
  cp "$ROOT"/systemd/zen-links-sync.service "$ROOT"/systemd/zen-links-sync.timer "$SYSTEMD"/
  cp "$ROOT"/systemd/obsidian-links-github-push.service "$ROOT"/systemd/obsidian-links-github-push.timer "$SYSTEMD"/
  systemctl --user daemon-reload
  systemctl --user enable --now zen-links-sync.timer 2>/dev/null || true
  systemctl --user enable --now obsidian-links-github-push.timer 2>/dev/null || true
  echo "enabled zen-links-sync.timer (weekly Sun 20:00)"
  echo "enabled obsidian-links-github-push.timer (weekly Sun 20:15)"
fi

# Wired marker so the service mode can skip work next boot.
cat > "$STATE_DIR/obsidian-capture.wired" <<EOF
version=1.0.0
wired=$(date -Is)
plugin_dir=$ROOT
EOF

echo "Done. Try: obsidian-capture --help"
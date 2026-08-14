#!/bin/bash
# Deploy ThinkPad Anki add-ons + kitty config to Mac (run from ThinkPad)
set -euo pipefail

MAC="zzx@100.110.173.82"
ANKI_MAC='Library/Application Support/Anki2/addons21'
ANKI_SRC="$HOME/.local/share/Anki2/addons21"
KITTY_SRC="$HOME/.config/kitty/kitty.conf"
THEME_SRC="$HOME/.config/omarchy/current/theme/kitty.conf"

echo "=== Quit Anki on Mac ==="
ssh "$MAC" 'osascript -e "tell application \"Anki\" to quit" 2>/dev/null || true; sleep 2; pkill -x anki 2>/dev/null || true'

echo "=== Sync Anki add-ons ==="
ssh "$MAC" "mkdir -p ~/${ANKI_MAC}"
rsync -az --delete \
  "$ANKI_SRC/" \
  "$MAC:~/${ANKI_MAC}/"

echo "=== Enable add-ons (HyperTTS stays disabled — crashes Anki 26) ==="
ssh "$MAC" "python3 -c \"
import json, pathlib
root = pathlib.Path.home() / 'Library/Application Support/Anki2/addons21'
for d in sorted(root.iterdir()):
    if not d.is_dir():
        continue
    meta = d / 'meta.json'
    if not meta.exists():
        continue
    data = json.loads(meta.read_text())
    data['disabled'] = d.name == 'hypertts'
    meta.write_text(json.dumps(data, indent=2) + chr(10))
    status = 'disabled' if data['disabled'] else 'enabled'
    print('  %s: %s' % (data.get('name', d.name), status))
\""

echo "=== Deploy kitty (Omarchy Nord theme) ==="
ssh "$MAC" 'mkdir -p ~/.config/kitty ~/.config/omarchy/current/theme'
scp -q "$KITTY_SRC" "$MAC:~/.config/kitty/kitty.conf"
scp -q "$THEME_SRC" "$MAC:~/.config/omarchy/current/theme/kitty.conf"

echo "=== Install JetBrainsMono Nerd Font ==="
ssh "$MAC" 'export PATH="/opt/homebrew/bin:$PATH"; eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)"; \
  if ! ls ~/Library/Fonts/*JetBrains* 2>/dev/null | grep -qi nerd; then \
    brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || brew install --cask font-jetbrains-mono-nerd-font; \
  else echo "  JetBrains Nerd Font already installed"; fi'

echo "=== Verify ==="
ssh "$MAC" 'echo "Addons:"; ls ~/Library/Application\ Support/Anki2/addons21/; echo; echo "kitty.conf:"; head -5 ~/.config/kitty/kitty.conf; echo; echo "theme:"; head -3 ~/.config/omarchy/current/theme/kitty.conf'

echo
echo "=== Done ==="
echo "Restart Anki on Mac to load add-ons."
echo "Restart kitty (or open a new window) for theme/font."

#!/usr/bin/env bash
# Sanitize a Zen profile backup for cross-platform restore (macOS -> Linux).
set -euo pipefail

PROFILE_DIR="${1:-$(cd "$(dirname "$0")/profile-backup" && pwd)}"

if [[ ! -f "$PROFILE_DIR/prefs.js" ]]; then
  echo "Error: prefs.js not found in $PROFILE_DIR" >&2
  exit 1
fi

echo "Sanitizing profile at: $PROFILE_DIR"

# Remove macOS absolute paths from prefs.js (download dir, file URIs, etc.)
if grep -q '/Users/' "$PROFILE_DIR/prefs.js"; then
  cp "$PROFILE_DIR/prefs.js" "$PROFILE_DIR/prefs.js.bak-mac"
  grep -v '/Users/' "$PROFILE_DIR/prefs.js.bak-mac" > "$PROFILE_DIR/prefs.js"
  echo "  - Stripped /Users/ lines from prefs.js"
fi

# Fix zen-themes.css file:// imports -> relative paths
THEMES_CSS="$PROFILE_DIR/chrome/zen-themes.css"
if [[ -f "$THEMES_CSS" ]] && grep -q 'file:///Users/' "$THEMES_CSS"; then
  cp "$THEMES_CSS" "$THEMES_CSS.bak-mac"
  sed -E 's|@import url\("file:///Users/[^"]+/chrome/(zen-themes/[^"]+)"\);|@import url("\1");|g' \
    "$THEMES_CSS.bak-mac" > "$THEMES_CSS"
  echo "  - Fixed zen-themes.css imports to relative paths"
fi

# pkcs11.txt embeds the old profile path; NSS regenerates it on first launch
if [[ -f "$PROFILE_DIR/pkcs11.txt" ]]; then
  rm -f "$PROFILE_DIR/pkcs11.txt"
  echo "  - Removed pkcs11.txt (regenerated on first launch)"
fi

# extensions.json stores absolute install paths; fix after restore when profile dir is known
if [[ -f "$PROFILE_DIR/extensions.json" ]] && grep -q '/Users/' "$PROFILE_DIR/extensions.json"; then
  cp "$PROFILE_DIR/extensions.json" "$PROFILE_DIR/extensions.json.bak-mac"
  python3 - <<'PY' "$PROFILE_DIR/extensions.json.bak-mac" "$PROFILE_DIR/extensions.json"
import json, sys
src, dst = sys.argv[1], sys.argv[2]
MAC_PROFILE = "/Users/zhengzexi/Library/Application Support/zen/Profiles/cjetrhju.Default (alpha)"
with open(src, encoding="utf-8") as f:
    data = json.load(f)
for addon in data.get("addons", []):
    path = addon.get("path")
    if isinstance(path, str) and path.startswith(MAC_PROFILE):
        addon["path"] = "__ZEN_PROFILE_DIR__" + path[len(MAC_PROFILE):]
with open(dst, "w", encoding="utf-8") as f:
    json.dump(data, f, separators=(",", ":"))
PY
  echo "  - Replaced macOS extension paths with __ZEN_PROFILE_DIR__ placeholder"
fi

echo "Sanitization complete."

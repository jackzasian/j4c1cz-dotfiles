#!/bin/bash
# The upgrade's repair_chromium_copy_url_extension_flags() rewrites ONLY the
# copy-url path in chromium-flags.conf. The second --load-extension entry,
# fixed-geolocation, keeps pointing into the old omarchy tree — which after the
# upgrade resolves to /usr/share/omarchy/default/chromium/extensions/
# fixed-geolocation, a path that does not exist (it was never upstream; it is
# yours, untracked in the old checkout). Chromium then errors on startup.
#
# Fix: keep the extension somewhere pacman will never touch, and point at it.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
DEST="$HOME/.local/share/chromium-extensions/fixed-geolocation"
FLAGS="$HOME/.config/chromium-flags.conf"

mkdir -p "$(dirname "$DEST")"
[[ -d $DEST ]] || cp -a "$HERE/../chromium-extensions/fixed-geolocation" "$DEST"
echo "extension installed at: $DEST"

[[ -f $FLAGS ]] || { echo "no $FLAGS — nothing to rewrite"; exit 0; }
cp -a "$FLAGS" "$FLAGS.bak.$(date +%s)"
python3 - "$FLAGS" "$DEST" <<'PY'
import sys, re
from pathlib import Path
flags, dest = Path(sys.argv[1]), sys.argv[2]
text = flags.read_text()
# Replace any fixed-geolocation path, wherever it currently points.
text = re.sub(r'[^\s,]*fixed-geolocation', dest, text)
flags.write_text(text)
PY
echo "rewrote --load-extension in $FLAGS:"
grep -n 'load-extension' "$FLAGS"
cat <<'EOF'

Also check ~/.local/bin/omarchy-set-geolocation — it referenced the old path.
Then restart Chromium and confirm at chrome://extensions that BOTH
copy-url and fixed-geolocation loaded without an error banner.
EOF

# --- ~/.local/bin/omarchy-set-geolocation references BOTH extension paths ---
SG="$HOME/.local/bin/omarchy-set-geolocation"
if [[ -f $SG ]]; then
  cp -a "$SG" "$SG.bak.$(date +%s)"
  python3 - "$SG" "$DEST" <<'PY'
import sys, re
from pathlib import Path
p, dest = Path(sys.argv[1]), sys.argv[2]
t = p.read_text()
# fixed-geolocation moves to the pacman-proof location...
t = re.sub(r'"?\$\{?HOME\}?/\.local/share/omarchy/default/chromium/extensions/fixed-geolocation"?',
           f'"{dest}"'.replace(str(Path.home()), '${HOME}'), t)
# ...copy-url is still shipped by Omarchy, now under /usr/share.
t = t.replace('${HOME}/.local/share/omarchy/default/chromium/extensions/copy-url',
              '/usr/share/omarchy/default/chromium/extensions/copy-url')
t = t.replace('$HOME/.local/share/omarchy/default/chromium/extensions/copy-url',
              '/usr/share/omarchy/default/chromium/extensions/copy-url')
p.write_text(t)
PY
  echo "patched $SG:"; grep -n 'extensions/' "$SG" | head
fi

#!/bin/bash
# Deploy Zen Browser config → Brave on Mac (via Tailscale)
set -euo pipefail

MAC="zzx@100.110.173.82"
MAC_USER="zzx"
SRC="/tmp/zen-brave-migrate"
BRAVE_BASE="Library/Application Support/BraveSoftware/Brave-Browser"
BRAVE_PROFILE="${BRAVE_BASE}/Default"
EXT_DIR="${BRAVE_BASE}/External Extensions"

echo "=== Export from Zen (ThinkPad) ==="
python3 /home/jackz/.local/bin/zen-to-brave-migrate.py

echo "=== Quit Brave on Mac ==="
ssh "$MAC" 'osascript -e "tell application \"Brave Browser\" to quit" 2>/dev/null || true; sleep 2; pkill -x "Brave Browser" 2>/dev/null || true'

echo "=== Upload migration bundle ==="
ssh "$MAC" "mkdir -p ~/${EXT_DIR} ~/.config/omarchy ~/${BRAVE_PROFILE}"
scp -q -r "${SRC}/extensions/"* "$MAC:~/${EXT_DIR}/"
scp -q "${SRC}/Bookmarks" "$MAC:~/${BRAVE_PROFILE}/Bookmarks"
scp -q "${SRC}/clash-proxy.pac" "$MAC:~/.config/omarchy/clash-proxy.pac"
scp -q "${SRC}/bookmarks.html" "$MAC:~/bookmarks-zen-import.html"

echo "=== Patch Brave preferences ==="
scp -q "${SRC}/brave_prefs_patch.json" "$MAC:/tmp/brave_prefs_patch.json"
ssh "$MAC" "python3 <<'PY'
import json
from pathlib import Path

profile = Path.home() / '${BRAVE_PROFILE}'
prefs_path = profile / 'Preferences'
patch = json.loads(Path('/tmp/brave_prefs_patch.json').read_text())

prefs = {}
if prefs_path.exists():
    prefs = json.loads(prefs_path.read_text())

def deep_merge(a, b):
    for k, v in b.items():
        if k in a and isinstance(a[k], dict) and isinstance(v, dict):
            deep_merge(a[k], v)
        else:
            a[k] = v

deep_merge(prefs, patch)
prefs_path.write_text(json.dumps(prefs))
print('  Preferences patched (dark mode, PAC proxy, DNT)')
PY"

echo "=== Install extensions (CRX download on ThinkPad, install on Mac) ==="
mkdir -p "${SRC}/crx"
python3 << PY
import json, urllib.request, os
from pathlib import Path
src = Path("${SRC}")
exts = json.loads((src / "extensions.json").read_text())
crx_dir = src / "crx"
crx_dir.mkdir(exist_ok=True)
url = "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=131.0&acceptformat=crx2,crx3&x=id%3D{id}%26uc"
proxy = os.environ.get("http_proxy")
for e in exts:
    cid = e["chrome_id"]
    out = crx_dir / f"{cid}.crx"
    if out.exists() and out.stat().st_size > 1000:
        print(f"  cached {e['name']}")
        continue
    try:
        req = urllib.request.Request(url.format(id=cid), headers={"User-Agent": "Mozilla/5.0"})
        data = urllib.request.urlopen(req, timeout=120).read()
        out.write_bytes(data)
        print(f"  downloaded {e['name']}")
    except Exception as exc:
        print(f"  FAILED {e['name']}: {exc}")
PY
scp -q -r "${SRC}/crx" "$MAC:/tmp/zen-brave-crx"
scp -q /home/jackz/.local/bin/install-brave-extensions.py "$MAC:/tmp/install-brave-extensions.py"
scp -q "${SRC}/extensions.json" "$MAC:/tmp/zen-brave-extensions.json"
ssh "$MAC" 'export http_proxy=http://127.0.0.1:7897 https_proxy=http://127.0.0.1:7897; python3 /tmp/install-brave-extensions.py /tmp/zen-brave-extensions.json "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default" /tmp/zen-brave-crx' 2>&1

echo "=== Summary on Mac ==="
ssh "$MAC" "echo 'Extensions installed:'; ls ~/'${BRAVE_PROFILE}'/Extensions/ 2>/dev/null | wc -l; echo 'Bookmarks file:'; python3 -c \"
import json
from pathlib import Path
b = json.loads((Path.home() / '${BRAVE_PROFILE}/Bookmarks').read_text())
def count(n):
    c = 0
    if n.get('type') == 'url': c += 1
    for ch in n.get('children', []):
        c += count(ch)
    return c
total = sum(count(r) for r in b['roots'].values())
print(f'  {total} bookmarks imported')
\""

echo
echo "=== Done ==="
echo "Open Brave on Mac — extensions and bookmarks should be ready."
echo "Sign in to Bitwarden + Tampermonkey sync if you use them."
echo "PAC proxy: ~/.config/omarchy/clash-proxy.pac (Strava direct, rest via Clash :7897)"

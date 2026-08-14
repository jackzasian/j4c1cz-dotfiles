#!/usr/bin/env bash
# Run ON the MacBook — configures Syncthing + Anki profile folder (apps must exist).
set -euo pipefail

THINKPAD_ID="5MPVOSR-GPJHI3O-GYSCG7J-424SGWF-LFFWXJ7-HYAV6PK-R7CQMAH-UP4SZQU"
FOLDER_ID="anki-profile"
ANKI_PROFILE="${HOME}/Library/Application Support/Anki2/User 1"
ST_HOME="${HOME}/Library/Application Support/Syncthing"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

find_syncthing() {
  if [[ -x /opt/homebrew/bin/syncthing ]]; then
    echo /opt/homebrew/bin/syncthing
  elif [[ -x /Applications/Syncthing.app/Contents/Resources/syncthing/syncthing ]]; then
    echo /Applications/Syncthing.app/Contents/Resources/syncthing/syncthing
  else
    return 1
  fi
}

ST_BIN="$(find_syncthing)" || {
  echo "Syncthing not found. Install Syncthing.app or: brew install --cask syncthing-app" >&2
  exit 1
}

if [[ ! -d /Applications/Anki.app ]]; then
  echo "Installing Anki..."
  brew install --cask anki
fi

if [[ ! -f ${ST_HOME}/config.xml ]]; then
  echo "Starting Syncthing for first-time setup..."
  open -a Syncthing
  for _ in $(seq 1 20); do
    [[ -f ${ST_HOME}/config.xml ]] && break
    sleep 1
  done
fi

mkdir -p "${ANKI_PROFILE}"
cat >"${ANKI_PROFILE}/.stignore" <<'EOF'
// Anki runtime files — never sync these
*.tmp
*.lock
backups
collection.anki2-journal
collection.anki2-wal
collection.anki2-shm
EOF

MAC_ID="$(grep -o 'device id="[^"]*"' "${ST_HOME}/config.xml" | head -1 | cut -d'"' -f2)"
[[ -n ${MAC_ID} ]] || { echo "Syncthing config not ready — open Syncthing.app once, then re-run." >&2; exit 1; }
echo "Mac Syncthing ID: ${MAC_ID}"

"${ST_BIN}" cli -H "${ST_HOME}" config devices add \
  --device-id="${THINKPAD_ID}" \
  --name="thinkpad1" \
  --addresses="dynamic" 2>/dev/null || true

if ! "${ST_BIN}" cli -H "${ST_HOME}" config folders list 2>/dev/null | grep -q "${FOLDER_ID}"; then
  "${ST_BIN}" cli -H "${ST_HOME}" config folders add \
    --id="${FOLDER_ID}" \
    --label="Anki Profile" \
    --path="${ANKI_PROFILE}" \
    --type=sendreceive
fi

"${ST_BIN}" cli -H "${ST_HOME}" config folders "${FOLDER_ID}" devices add --device-id="${THINKPAD_ID}" 2>/dev/null || true

echo
echo "=== Done on Mac ==="
echo "Anki: open -a Anki"
echo "Syncthing UI: http://127.0.0.1:8384"
echo "Device ID: ${MAC_ID}"
echo "IMPORTANT: close Anki on one machine before opening on the other."

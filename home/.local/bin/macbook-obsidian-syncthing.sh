#!/usr/bin/env bash
# Pair MacBook Obsidian vault with ThinkPad via Syncthing.
set -euo pipefail

THINKPAD_ID="5MPVOSR-GPJHI3O-GYSCG7J-424SGWF-LFFWXJ7-HYAV6PK-R7CQMAH-UP4SZQU"
FOLDER_ID="j4c1c-vault"
OBSIDIAN_PATH="${HOME}/Obsidian/J4c1c"
ST_HOME="${HOME}/Library/Application Support/Syncthing"

find_syncthing() {
  if [[ -x /Applications/Syncthing.app/Contents/Resources/syncthing/syncthing ]]; then
    echo /Applications/Syncthing.app/Contents/Resources/syncthing/syncthing
  elif [[ -x /opt/homebrew/bin/syncthing ]]; then
    echo /opt/homebrew/bin/syncthing
  else
    return 1
  fi
}

ST_BIN="$(find_syncthing)" || { echo "Syncthing not installed" >&2; exit 1; }

if [[ ! -f ${ST_HOME}/config.xml ]]; then
  open -a Syncthing
  for _ in $(seq 1 30); do
    [[ -f ${ST_HOME}/config.xml ]] && break
    sleep 1
  done
fi

mkdir -p "${OBSIDIAN_PATH}"

# Match ThinkPad ignore rules for Obsidian.
cat >"${OBSIDIAN_PATH}/.stignore" <<'EOF'
.venv
.git
.obsidian/workspace.json
.obsidian/workspace-mobile.json
thumbnails
**/.DS_Store
**/__pycache__
**/*.pyc
.cursor
EOF

"${ST_BIN}" cli -H "${ST_HOME}" config devices add \
  --device-id="${THINKPAD_ID}" \
  --name="thinkpad1" \
  --addresses="dynamic" 2>/dev/null || true

if "${ST_BIN}" cli -H "${ST_HOME}" config folders list 2>/dev/null | grep -q "^${FOLDER_ID}$"; then
  "${ST_BIN}" cli -H "${ST_HOME}" config folders "${FOLDER_ID}" delete 2>/dev/null || true
fi

"${ST_BIN}" cli -H "${ST_HOME}" config folders add \
  --id="${FOLDER_ID}" \
  --label="J4c1c Obsidian" \
  --path="${OBSIDIAN_PATH}" \
  --type=sendreceive

"${ST_BIN}" cli -H "${ST_HOME}" config folders "${FOLDER_ID}" devices add --device-id="${THINKPAD_ID}" 2>/dev/null || true

MAC_ID="$(grep -o 'device id="[^"]*"' "${ST_HOME}/config.xml" | head -1 | cut -d'"' -f2)"
echo "Mac Syncthing ID: ${MAC_ID}"
echo "Obsidian path: ${OBSIDIAN_PATH}"
echo "Folder: ${FOLDER_ID}"
echo "Open http://127.0.0.1:8384 and accept the ThinkPad device/folder if prompted."

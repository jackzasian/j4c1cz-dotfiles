#!/bin/bash
# Delete Apple stock apps — ONLY works if SIP is disabled (Recovery Mode).
# Normal macOS: "Operation not permitted" is expected. Use hide-stock-apps.sh instead.
#
# Recovery steps (if you really want deletion):
#   1. Shut down Mac
#   2. Hold power until "Loading startup options" → Options → Continue
#   3. Utilities → Terminal → run:  csrutil disable
#   4. Reboot, run:  bash ~/remove-stock-apps.sh
#   5. Recovery again → Terminal → run:  csrutil enable
#   6. Reboot
#
# Run:  bash ~/remove-stock-apps.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  exec sudo bash "$0" "$@"
fi

APPS=(
  "/System/Applications/Books.app"
  "/System/Applications/News.app"
  "/System/Applications/Stocks.app"
  "/System/Applications/Podcasts.app"
  "/System/Applications/TV.app"
  "/System/Applications/Home.app"
  "/System/Applications/Freeform.app"
  "/System/Applications/Tips.app"
  "/System/Applications/Chess.app"
  "/System/Applications/FaceTime.app"
  "/System/Applications/Maps.app"
  "/System/Applications/Music.app"
  "/System/Applications/Mail.app"
  "/System/Applications/Notes.app"
  "/System/Applications/Reminders.app"
  "/Applications/GarageBand.app"
  "/Applications/iMovie.app"
  "/Applications/Keynote.app"
  "/Applications/Numbers.app"
  "/Applications/Pages.app"
)

removed=0
blocked=0
for app in "${APPS[@]}"; do
  [[ -d $app ]] || continue
  if rm -rf "$app" 2>/dev/null; then
    echo "Removed: $app"
    removed=$((removed + 1))
  else
    echo "Blocked (SIP): $app"
    blocked=$((blocked + 1))
  fi
done

echo
if (( blocked > 0 )); then
  echo "Operation not permitted = macOS System Integrity Protection."
  echo "Use instead:  bash ~/hide-stock-apps.sh"
  echo "Or disable SIP in Recovery Mode (see script header)."
  exit 1
fi
echo "Removed ${removed} app(s)."

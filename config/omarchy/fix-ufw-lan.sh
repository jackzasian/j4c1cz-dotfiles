#!/usr/bin/env bash
# Allow KDE Connect + Syncthing from home LAN through UFW.
# Run: sudo ~/.config/omarchy/fix-ufw-lan.sh

set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

LAN="${1:-10.69.10.0/24}"

echo "Allowing LAN ${LAN} → KDE Connect + Syncthing..."

ufw allow from "${LAN}" to any app kdeconnect comment 'KDE Connect LAN' || \
  ufw allow from "${LAN}" to any port 1714:1764 proto tcp comment 'KDE Connect TCP' && \
  ufw allow from "${LAN}" to any port 1714:1764 proto udp comment 'KDE Connect UDP'

ufw allow from "${LAN}" to any port 22000 proto tcp comment 'Syncthing sync'
ufw allow from "${LAN}" to any port 8384 proto tcp comment 'Syncthing web LAN'

ufw status verbose | rg -i '171|22000|8384|kde|10\.69' || ufw status numbered

echo
echo "After pairing works, secure (phone-only UFW + lock Syncthing GUI):"
echo "  sudo ~/.config/omarchy/secure-lan-services.sh 10.69.10.173"

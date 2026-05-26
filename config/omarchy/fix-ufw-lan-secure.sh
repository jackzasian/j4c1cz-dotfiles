#!/usr/bin/env bash
# Tighten LAN firewall: trusted devices only, no Syncthing web port.
# Run: sudo ~/.config/omarchy/fix-ufw-lan-secure.sh [phone-ip] [pixel-ip ...]

set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

PHONE_IP="${1:-10.69.10.173}"
shift || true
EXTRA_SYNCTHING_IPS=("$@")
if [[ ${#EXTRA_SYNCTHING_IPS[@]} -eq 0 ]]; then
  EXTRA_SYNCTHING_IPS=("10.69.10.230")  # Pixel Backup
fi
LAN_SUBNET="10.69.10.0/24"

echo "Hardening UFW: trusted devices only..."

# Remove broad LAN rules from initial pairing (ignore errors if already gone)
for spec in \
  "from ${LAN_SUBNET} to any app kdeconnect" \
  "from ${LAN_SUBNET} to any port 22000 proto tcp" \
  "from ${LAN_SUBNET} to any port 8384 proto tcp" \
  "from ${LAN_SUBNET} to any port 1714:1764 proto tcp" \
  "from ${LAN_SUBNET} to any port 1714:1764 proto udp"; do
  ufw delete allow ${spec} 2>/dev/null || true
done

# Remove old per-device Syncthing rules (re-add below)
ufw status numbered | rg -o '^\[\s*[0-9]+\]' | tac | while read -r num; do
  idx="${num//[^0-9]/}"
  rule=$(ufw status numbered | rg "^\[ *${idx}\]" || true)
  if [[ ${rule} == *"Syncthing sync"* ]]; then
    ufw --force delete "${idx}" 2>/dev/null || true
  fi
done

# Phone-only KDE Connect
ufw allow from "${PHONE_IP}/32" to any app kdeconnect comment 'KDE Connect phone only'

# Syncthing sync — phone + extra trusted devices (e.g. Pixel Backup)
SYNCTHING_IPS=("${PHONE_IP}" "${EXTRA_SYNCTHING_IPS[@]}")
declare -A seen=()
for ip in "${SYNCTHING_IPS[@]}"; do
  [[ -n ${seen[$ip]+x} ]] && continue
  seen[$ip]=1
  ufw allow from "${ip}/32" to any port 22000 proto tcp comment "Syncthing sync ${ip}"
done

ufw default deny incoming
ufw default allow outgoing

ufw status verbose | rg -i '171|22000|8384|kde|10\.69' || ufw status numbered

echo
echo "Secured:"
echo "  ✓ KDE Connect: ${PHONE_IP} only"
echo "  ✓ Syncthing sync (22000): ${SYNCTHING_IPS[*]}"
echo "  ✓ Syncthing web (8384): not exposed (use syncthing-lockdown)"
echo
echo "If device IPs change, re-run: sudo $0 PHONE_IP PIXEL_IP ..."

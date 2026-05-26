#!/usr/bin/env bash
# Post-pairing security: lock Syncthing GUI + tighten UFW to trusted device IPs.
# Run: sudo ~/.config/omarchy/secure-lan-services.sh [phone-ip] [pixel-ip ...]

set -euo pipefail

PHONE_IP="${1:-10.69.10.173}"
shift || true
EXTRA_IPS=("$@")
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

echo "=== Securing LAN services ==="

# Syncthing GUI → localhost only (no sudo)
if [[ ${EUID} -ne 0 ]]; then
  "${HOME}/.local/bin/syncthing-lockdown" 2>/dev/null || true
  echo
  echo "UFW tighten requires sudo — re-run:"
  echo "  sudo ${SCRIPT_DIR}/secure-lan-services.sh ${PHONE_IP} ${EXTRA_IPS[*]:-10.69.10.230}"
else
  "${SCRIPT_DIR}/fix-ufw-lan-secure.sh" "${PHONE_IP}" "${EXTRA_IPS[@]}"
  runuser -u "${SUDO_USER:-jackz}" -- "${HOME}/.local/bin/syncthing-lockdown" 2>/dev/null || true
fi

# Clash → localhost only
if [[ -x ${HOME}/.local/bin/clash-secure-localhost ]]; then
  runuser -u "${SUDO_USER:-jackz}" -- "${HOME}/.local/bin/clash-secure-localhost" 2>/dev/null || \
    "${HOME}/.local/bin/clash-secure-localhost" 2>/dev/null || true
fi

echo
echo "Verify:"
echo "  ss -tlnp | rg '8384|7897'     # 8384=127.0.0.1, 7897=127.0.0.1"
echo "  sudo ufw status verbose"
echo "  proxy_status"

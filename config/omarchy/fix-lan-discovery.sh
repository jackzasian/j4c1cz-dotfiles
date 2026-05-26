#!/usr/bin/env bash
# Fix LAN discovery for KDE Connect + Syncthing on Clash TUN systems.
# Run once: sudo ~/.config/omarchy/fix-lan-discovery.sh
# Also run: sudo ~/.config/omarchy/fix-ufw-lan.sh   (UFW blocks port 1716!)

set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

AVAHI_DROPIN=/etc/avahi/avahi-daemon.conf.d/10-lan-only.conf
RESOLVED_DROPIN=/etc/systemd/resolved.conf.d/10-disable-multicast.conf

mkdir -p "$(dirname "${AVAHI_DROPIN}")"

# Clash Meta (198.18.x) poisons mDNS — laptop advertises wrong IP for KDE Connect
cat >"${AVAHI_DROPIN}" <<'EOF'
[server]
allow-interfaces=wlan0,lo
deny-interfaces=Meta,docker0,br-+,veth+,virbr+,tun+,tap+
allow-point-to-point=no
EOF

if [[ -f ${RESOLVED_DROPIN} ]]; then
  sed -i 's/^MulticastDNS=no/MulticastDNS=yes/' "${RESOLVED_DROPIN}"
else
  mkdir -p "$(dirname "${RESOLVED_DROPIN}")"
  printf '[Resolve]\nMulticastDNS=yes\n' >"${RESOLVED_DROPIN}"
fi

systemctl restart avahi-daemon systemd-resolved
resolvectl mdns wlan0 yes 2>/dev/null || true

# User services
for u in /home/*; do
  [[ -d ${u} ]] || continue
  uid=$(basename "${u}")
  [[ ${uid} == lost+found ]] && continue
  runuser -u "${uid}" -- systemctl --user restart kdeconnectd 2>/dev/null || true
done

echo "Done. Verify:"
echo "  avahi-browse -a -t | rg -i kdeconnect"
echo "  sudo -u jackz kdeconnect-cli -l"
echo
echo "IMPORTANT — also run if KDE Connect still fails:"
echo "  sudo ~/.config/omarchy/fix-ufw-lan.sh"
echo "On phone: open KDE Connect → custom IP 10.69.10.11 → Pair"

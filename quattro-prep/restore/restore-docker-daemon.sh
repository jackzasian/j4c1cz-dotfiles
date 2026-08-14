#!/bin/bash
# The Quattro upgrade OVERWRITES /etc/docker/daemon.json and takes no backup of
# its own. This restores the pre-Quattro file, keeping the two settings Quattro
# genuinely needs (its resolved stub listener on 172.17.0.1 serves container DNS).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
echo "--- Quattro wrote:"; cat /etc/docker/daemon.json
echo "--- pre-Quattro was:"; cat "$HERE/docker-daemon.json"
cat <<'EOF'

Decide before overwriting. Yours had:
  dns: [223.5.5.5, 119.29.29.29]   (AliDNS/DNSPod — Quattro replaces with 172.17.0.1)
  ip-forward-no-drop: true
  userland-proxy: false            (perf; also interacts with ufw-docker)
Quattro's 172.17.0.1 DNS depends on /etc/systemd/resolved.conf.d/20-docker-dns.conf
(DNSStubListenerExtra=172.17.0.1). Keeping your explicit Chinese resolvers is
usually the safer choice in CN, but verify container DNS either way:
  docker run --rm alpine nslookup github.com

To apply yours verbatim:
  sudo cp "$HERE/docker-daemon.json" /etc/docker/daemon.json && sudo systemctl restart docker
EOF

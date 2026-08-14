# Clash Verge Rev — secure terminal proxy helpers
# Mixed port is read from the live config; only 127.0.0.1 is used.
#
# yay/AUR: with TUN fake-ip, Go tools must use http_proxy (not bare fake 198.18.x TCP).
# proxy_on sets HTTP + SOCKS; auto-enabled below when Clash is listening.

_clash_config() {
  printf '%s\n' "$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev/config.yaml"
}

_clash_mixed_port() {
  local cfg port
  cfg=$(_clash_config)
  if [[ -f $cfg ]]; then
    port=$(awk '/^mixed-port:/ {print $2; exit}' "$cfg")
    [[ -n $port ]] && { printf '%s\n' "$port"; return 0; }
  fi
  printf '%s\n' 7897
}

_clash_listening() {
  local sock=/tmp/verge/verge-mihomo.sock
  [[ -S $sock ]] && curl -sS --max-time 2 --unix-socket "$sock" http://localhost/ 2>/dev/null | grep -q '"hello":"mihomo"'
}

proxy_on() {
  local host=127.0.0.1 port url

  if ! _clash_listening; then
    printf 'Clash mixed port not listening on %s (start Clash Verge first)\n' "$host" >&2
    return 1
  fi

  port=$(_clash_mixed_port)
  url="http://${host}:${port}"

  export http_proxy=$url
  export https_proxy=$url
  export HTTP_PROXY=$url
  export HTTPS_PROXY=$url
  export ALL_PROXY="socks5://${host}:${port}"
  export all_proxy=$ALL_PROXY
  # Include Tailscale CGNAT (100.64/10) + MagicDNS so Clash does not intercept mesh traffic.
  export NO_PROXY='localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,100.64.0.0/10,.ts.net,jacks-mac-mini,thinkpad1,local'
  export no_proxy=$NO_PROXY
  export NPM_CONFIG_PROXY=$url
  export NPM_CONFIG_HTTPS_PROXY=$url
  export PIP_PROXY=$url

  printf 'Proxy on → %s (socks %s)\n' "$url" "$ALL_PROXY"
}

proxy_off() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy NO_PROXY no_proxy
  unset NPM_CONFIG_PROXY NPM_CONFIG_HTTPS_PROXY PIP_PROXY
  printf 'Proxy off\n'
}

proxy_status() {
  local port
  port=$(_clash_mixed_port)
  printf 'Clash mixed port: %s\n' "$port"
  if _clash_listening; then
    printf 'Listener: up on 127.0.0.1:%s\n' "$port"
  else
    printf 'Listener: down\n'
  fi
  if [[ -n ${http_proxy:-} ]]; then
    printf 'Shell proxy: %s\n' "$http_proxy"
    curl -sS --max-time 8 -o /dev/null -w 'Test google.com → HTTP %{http_code}\n' https://www.google.com 2>/dev/null \
      || printf 'Test google.com → failed\n'
  else
    printf 'Shell proxy: off (run proxy_on)\n'
  fi
}

# Auto-enable when Clash is up: interactive shells and Cursor agent terminals.
if [[ -z ${http_proxy:-} ]] && _clash_listening; then
  if [[ $- == *i* ]] || [[ -n ${CURSOR_AGENT:-} ]]; then
    proxy_on >/dev/null
  fi
fi

#!/usr/bin/env bash
# Hermes gateway status for waybar (Cursor agents live in ai-tool-status.sh).
set -euo pipefail

hermes_state="off"
discord_state=""
collected=""
status_file="${HOME}/hermes-dashboard/status.json"
if [[ -f "${status_file}" ]]; then
  hermes_state="$(jq -r '.remote.gateway.state_file.gateway_state // "unknown"' "${status_file}" 2>/dev/null || echo unknown)"
  discord_state="$(jq -r '.remote.gateway.state_file.platforms.discord.state // empty' "${status_file}" 2>/dev/null || true)"
  collected="$(jq -r '.collected_at // empty' "${status_file}" 2>/dev/null || true)"
fi

if pgrep -af 'hermes_cli.main gateway run|hermes-gateway' >/dev/null 2>&1; then
  hermes_state="running-local"
fi

case "${hermes_state}" in
  running|running-local)
    text=""
    cls="busy"
    ;;
  *)
    text=""
    cls="idle"
    ;;
esac

python3 -c '
import json, sys
text, hermes, discord, collected, cls = sys.argv[1:6]
lines = [f"Hermes: {hermes}"]
if discord:
    lines.append(f"Discord: {discord}")
if collected:
    lines.append(f"Status: {collected}")
print(json.dumps({"text": text, "tooltip": "\n".join(lines), "class": cls}, ensure_ascii=False))
' "${text}" "${hermes_state}" "${discord_state}" "${collected}" "${cls}"

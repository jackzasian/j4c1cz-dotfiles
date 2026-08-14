#!/usr/bin/env bash
# AI tools status for waybar — logos + idle/working/done dynamics.
set -euo pipefail

STATE_DIR="${HOME}/.cache/waybar-status"
STATE="${STATE_DIR}/ai-tools.state"
mkdir -p "${STATE_DIR}"

ICON_CD="󰚩" # Claude Desktop
ICON_CC="󰆍" # Claude Code
ICON_OC="󰘦" # OpenCode
ICON_CU="󰨞" # Cursor

SPINNERS=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧)
SPIN="${SPINNERS[$(( $(date +%s) % ${#SPINNERS[@]} ))]}"

C_OFF="#4c566a"
C_IDLE="#d8dee9"
C_WORK="#7daea3"
C_DONE="#a3be8c"

count_pgrep() {
  local pattern=$1 n=0 line
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    [[ "${line}" == *claude-status* ]] && continue
    [[ "${line}" == *agents-status* ]] && continue
    n=$((n + 1))
  done < <(pgrep -af "${pattern}" 2>/dev/null || true)
  echo "${n}"
}

cpu_busy() {
  local pattern=$1 threshold=${2:-3} total=0 line pid pcpu
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    [[ "${line}" == *claude-status* ]] && continue
    pid="${line%% *}"
    [[ "${pid}" =~ ^[0-9]+$ ]] || continue
    pcpu="$(ps -o pcpu= -p "${pid}" 2>/dev/null | tr -d ' ' || echo 0)"
    total="$(python3 -c "print(round(float('${total}')+float('${pcpu:-0}'),2))")"
  done < <(pgrep -af "${pattern}" 2>/dev/null || true)
  python3 -c "import sys; sys.exit(0 if float('${total}') >= float('${threshold}') else 1)"
}

claude_app=0
pgrep -f '/usr/lib/claude-desktop/claude --enable' >/dev/null 2>&1 && claude_app=1

claude_cli="$(count_pgrep '/opt/claude-code/bin/claude')"
claude_ccd="$(count_pgrep 'config/Claude/claude-code/.+/claude')"
claude_code=$((claude_cli + claude_ccd))

opencode_n=0
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  [[ "${line}" == *claude-status* ]] && continue
  case "${line}" in
    *node_modules*/.bin/opencode*|*npx*opencode*|*/bin/opencode*|*/.local/bin/opencode*)
      opencode_n=$((opencode_n + 1)) ;;
  esac
done < <(pgrep -af 'opencode' 2>/dev/null || true)

cursor_ide=0
pgrep -f '/usr/share/cursor/resources/app' >/dev/null 2>&1 && cursor_ide=1

cursor_agents=0
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  [[ "${line}" == *worker-server* ]] && continue
  [[ "${line}" == *agents-status* ]] && continue
  [[ "${line}" == *claude-status* ]] && continue
  cursor_agents=$((cursor_agents + 1))
done < <(pgrep -af '/.local/bin/agent --use-system-ca|/.local/share/cursor-agent/.*/index.js' 2>/dev/null || true)

cd_busy=0; cc_busy=0; oc_busy=0; cu_busy=0
if (( claude_app )); then
  if cpu_busy '/usr/lib/claude-desktop/claude --enable' 8 \
    || cpu_busy 'config/Claude/claude-code/.+/claude' 3; then
    cd_busy=1
  fi
fi
if (( claude_code )); then
  if cpu_busy '/opt/claude-code/bin/claude' 3 \
    || cpu_busy 'config/Claude/claude-code/.+/claude' 3; then
    cc_busy=1
  fi
fi
(( opencode_n )) && cpu_busy 'opencode' 3 && oc_busy=1
if (( cursor_ide || cursor_agents > 0 )); then
  if cpu_busy '/usr/share/cursor/resources/app' 5 \
    || cpu_busy '/.local/bin/agent --use-system-ca|/.local/share/cursor-agent/.*/index.js' 2; then
    cu_busy=1
  fi
fi

any_busy=0
(( cd_busy || cc_busy || oc_busy || cu_busy )) && any_busy=1

now="$(date +%s)"
prev_busy=0
done_until=0
if [[ -f "${STATE}" ]]; then
  # shellcheck disable=SC1090
  source "${STATE}" 2>/dev/null || true
fi
just_done=0
if (( prev_busy == 1 && any_busy == 0 )); then
  done_until=$((now + 10))
  just_done=1
fi
showing_done=0
(( now < done_until )) && showing_done=1
printf 'prev_busy=%s\ndone_until=%s\n' "${any_busy}" "${done_until}" > "${STATE}"

state_of() {
  local present=$1 busy=$2
  if (( present == 0 )); then echo off
  elif (( busy )); then echo working
  elif (( showing_done )); then echo done
  else echo idle
  fi
}

cd_st="$(state_of "${claude_app}" "${cd_busy}")"
cc_st="$(state_of "$(( claude_code > 0 ? 1 : 0 ))" "${cc_busy}")"
oc_st="$(state_of "$(( opencode_n > 0 ? 1 : 0 ))" "${oc_busy}")"
cu_present=0; (( cursor_ide || cursor_agents > 0 )) && cu_present=1
cu_st="$(state_of "${cu_present}" "${cu_busy}")"

python3 - <<'PY' \
  "${ICON_CD}" "${ICON_CC}" "${ICON_OC}" "${ICON_CU}" "${SPIN}" \
  "${cd_st}" "${cc_st}" "${oc_st}" "${cu_st}" \
  "${claude_app}" "${claude_cli}" "${claude_ccd}" "${claude_code}" \
  "${opencode_n}" "${cursor_ide}" "${cursor_agents}" \
  "${any_busy}" "${showing_done}" "${just_done}" \
  "${C_OFF}" "${C_IDLE}" "${C_WORK}" "${C_DONE}"
import json, sys

(
    icon_cd, icon_cc, icon_oc, icon_cu, spin,
    cd_st, cc_st, oc_st, cu_st,
    app, cli, ccd, code, oc_n, ide, agents,
    any_busy, showing_done, just_done,
    c_off, c_idle, c_work, c_done,
) = sys.argv[1:]

app, cli, ccd, code, oc_n, ide, agents = map(int, (app, cli, ccd, code, oc_n, ide, agents))
any_busy, showing_done, just_done = map(int, (any_busy, showing_done, just_done))
colors = {"off": c_off, "idle": c_idle, "working": c_work, "done": c_done}

def chip(icon, state, count=0, min_count=2):
    color = colors[state]
    bits = [icon]
    if state == "working":
        bits.append(spin)
    elif count >= min_count:
        bits.append(f"·{count}")
    return f"<span foreground='{color}'>{''.join(bits)}</span>"

# Cursor count: agents when present; hide ·1 for single agent unless IDE also up
cu_count = agents
cu_min = 2
if ide and agents:
    cu_min = 1

parts = [
    chip(icon_cd, cd_st),
    chip(icon_cc, cc_st, code, 2),
    chip(icon_oc, oc_st, oc_n, 2),
    chip(icon_cu, cu_st, cu_count, cu_min),
]
text = " ".join(parts)

labels = {"off": "off", "idle": "idle", "working": "working ●", "done": "just finished ✓"}
lines = [
    f"{icon_cd} Claude Desktop: {labels[cd_st]}",
    f"{icon_cc} Claude Code: {labels[cc_st]} — {code} (CLI {cli}, Desktop {ccd})",
    f"{icon_oc} OpenCode: {labels[oc_st]}" + (f" ×{oc_n}" if oc_n else ""),
    f"{icon_cu} Cursor: IDE={'on' if ide else 'off'}, agents={agents} — {labels[cu_st]}",
    "",
    "Click: focus/launch Claude Desktop",
    "Right-click: relaunch Claude with proxy",
]
if just_done:
    lines.insert(0, "✓ Task finished")
elif any_busy:
    lines.insert(0, f"{spin} Task running…")

if any_busy:
    cls = "working"
elif showing_done:
    cls = "done"
elif any(s != "off" for s in (cd_st, cc_st, oc_st, cu_st)):
    cls = "on"
else:
    cls = "idle"

print(json.dumps({"text": text, "tooltip": "\n".join(lines), "class": cls}, ensure_ascii=False))
PY

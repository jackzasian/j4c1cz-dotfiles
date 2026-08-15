#!/usr/bin/env bash
# Per-tool AI coding assistant status for waybar.
# Usage: ai-tool-status.sh <cd|cc|oc|cu>
#   cd = Claude Desktop, cc = Claude Code, oc = OpenCode, cu = Cursor
set -euo pipefail

TOOL="${1:?usage: ai-tool-status.sh <cd|cc|oc|cu>}"

STATE_DIR="${HOME}/.cache/waybar-status"
STATE="${STATE_DIR}/ai-tool-${TOOL}.state"
mkdir -p "${STATE_DIR}"

SPINNERS=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧)
SPIN="${SPINNERS[$(( $(date +%s) % ${#SPINNERS[@]} ))]}"

count_pgrep() {
  local pattern=$1 n=0 line
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    [[ "${line}" == *ai-tool-status* ]] && continue
    n=$((n + 1))
  done < <(pgrep -af "${pattern}" 2>/dev/null || true)
  echo "${n}"
}

# ps -o pcpu is a lifetime average and stays near-zero for long-lived
# processes (Cursor's agent, OpenCode) even while actively busy right now.
# Track /proc CPU-time deltas between polls instead for a true instantaneous
# reading.
gather_pids() {
  local pattern line pid
  declare -A seen
  for pattern in "$@"; do
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      [[ "${line}" == *ai-tool-status* ]] && continue
      [[ "${line}" == *worker-server* ]] && continue
      pid="${line%% *}"
      [[ "${pid}" =~ ^[0-9]+$ ]] || continue
      seen["${pid}"]=1
    done < <(pgrep -af "${pattern}" 2>/dev/null || true)
  done
  printf '%s\n' "${!seen[@]}"
}

busy_delta() {
  local state_key=$1 threshold=$2
  shift 2
  local pids=("$@")
  (( ${#pids[@]} == 0 )) && return 1
  local result
  result="$(python3 "${HOME}/.config/omarchy/bar/scripts/proc-cpu-delta.py" "${state_key}" "${threshold}" "${pids[@]}")"
  [[ "${result}" == "1" ]]
}

case "${TOOL}" in
  cd)
    ICON="󰚩"
    present=0
    pgrep -f '/usr/lib/claude-desktop/claude --enable' >/dev/null 2>&1 && present=1
    busy=0
    if (( present )); then
      mapfile -t pids < <(gather_pids '/usr/lib/claude-desktop/claude --enable' 'config/Claude/claude-code/.+/claude')
      busy_delta "cd" 5 "${pids[@]}" && busy=1
    fi
    count=0
    min_count=99
    label="Claude Desktop"
    ICON_FILE_NAME="claude.png"
    ;;
  cc)
    ICON="󰆍"
    ICON_FILE_NAME="claude.png"
    cli="$(count_pgrep '/opt/claude-code/bin/claude')"
    ccd="$(count_pgrep 'config/Claude/claude-code/.+/claude')"
    count=$((cli + ccd))
    present=$(( count > 0 ? 1 : 0 ))
    busy=0
    if (( present )); then
      mapfile -t pids < <(gather_pids '/opt/claude-code/bin/claude' 'config/Claude/claude-code/.+/claude')
      busy_delta "cc" 3 "${pids[@]}" && busy=1
    fi
    min_count=2
    label="Claude Code"
    ;;
  oc)
    ICON="󰘦"
    count=0
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      [[ "${line}" == *ai-tool-status* ]] && continue
      case "${line}" in
        *node_modules*/.bin/opencode*|*npx*opencode*|*/bin/opencode*|*/.local/bin/opencode*)
          count=$((count + 1)) ;;
      esac
    done < <(pgrep -af 'opencode' 2>/dev/null || true)
    present=$(( count > 0 ? 1 : 0 ))
    busy=0
    if (( present )); then
      mapfile -t pids < <(gather_pids 'opencode')
      busy_delta "oc" 3 "${pids[@]}" && busy=1
    fi
    min_count=2
    label="OpenCode"
    ICON_FILE_NAME="opencode.png"
    ;;
  cu)
    ICON="󰇀"
    ICON_FILE_NAME="cursor.png"
    ide=0
    pgrep -f '/usr/share/cursor/resources/app' >/dev/null 2>&1 && ide=1
    agents=0
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      [[ "${line}" == *worker-server* ]] && continue
      [[ "${line}" == *ai-tool-status* ]] && continue
      agents=$((agents + 1))
    done < <(pgrep -af '/.local/bin/agent --use-system-ca|/.local/share/cursor-agent/.*/index.js' 2>/dev/null || true)
    count="${agents}"
    present=$(( ide || agents > 0 ? 1 : 0 ))
    busy=0
    if (( agents )); then
      # Only track the cursor-agent process(es) for CPU-busy detection, not
      # the whole IDE ('/usr/share/cursor/resources/app' also matches
      # Electron helper processes like gitWorker.js, which burn real CPU
      # reacting to any file change in the repo -- unrelated to the agent
      # actually generating a response, but was being counted as "busy".
      mapfile -t pids < <(gather_pids '/.local/bin/agent --use-system-ca' '/.local/share/cursor-agent/.*/index.js')
      busy_delta "cu" 3 "${pids[@]}" && busy=1
    fi
    min_count=2
    (( ide && agents )) && min_count=1
    label="Cursor"
    ;;
  *)
    echo '{"text":"","tooltip":"unknown tool","class":"off"}'
    exit 0
    ;;
esac

# Raw busy_delta readings flicker: a bursty-but-idle process (background
# LSP/indexing/redraw work, not a real user task) can cross the CPU
# threshold for a poll or two and drop back below it shortly after.
# Debounce BOTH edges: require sustained busy before confirming a task
# actually started, and sustained idle before confirming it finished.
# Idle-only debouncing wasn't enough — a single-poll busy blip still set
# prev_busy=1, so when it subsided a few seconds later the idle debounce
# fired a real "finished" ding for work that never started (seen
# repeatedly with OpenCode's noisier background CPU baseline).
BUSY_CONFIRM=2
IDLE_DEBOUNCE=4

now="$(date +%s)"
prev_busy=0
done_until=0
idle_streak=0
busy_streak=0
if [[ -f "${STATE}" ]]; then
  # shellcheck disable=SC1090
  source "${STATE}" 2>/dev/null || true
fi

confirmed_busy="${prev_busy}"
if (( busy )); then
  idle_streak=0
  busy_streak=$((busy_streak + 1))
  if (( prev_busy == 1 || busy_streak >= BUSY_CONFIRM )); then
    confirmed_busy=1
  fi
else
  busy_streak=0
  idle_streak=$((idle_streak + 1))
  if (( prev_busy == 1 && idle_streak < IDLE_DEBOUNCE )); then
    confirmed_busy=1
  else
    confirmed_busy=0
  fi
fi

just_done=0
if (( prev_busy == 1 && confirmed_busy == 0 )); then
  done_until=$((now + 10))
  just_done=1
fi
showing_done=0
(( now < done_until )) && showing_done=1
busy="${confirmed_busy}"
printf 'prev_busy=%s\ndone_until=%s\nidle_streak=%s\nbusy_streak=%s\n' "${confirmed_busy}" "${done_until}" "${idle_streak}" "${busy_streak}" > "${STATE}"

# No notify-send/paplay here: CPU-delta "busy" is a poor proxy for these
# tools since they're mostly I/O-bound (waiting on the model) with only
# brief CPU spikes during tool execution. That made "busy" flicker to 0
# constantly mid-task, firing a "done" ding for work that hadn't finished.
# The silent "done" pill flash (10s, class=done above) is the only signal.

if (( present == 0 )); then
  state="off"
elif (( busy )); then
  state="working"
elif (( showing_done )); then
  state="done"
else
  state="idle"
fi

python3 - <<'PY' "${ICON}" "${SPIN}" "${state}" "${count}" "${min_count}" "${label}" "${just_done}" "${busy}"
import json, sys

icon, spin, state, count, min_count, label, just_done, busy = sys.argv[1:9]
count, min_count, just_done, busy = int(count), int(min_count), int(just_done), int(busy)

if state == "off":
    print(json.dumps({"text": "", "tooltip": f"{label}: off", "class": "off"}))
    sys.exit(0)

bits = []
if state == "working":
    bits.append(spin)
elif count >= min_count:
    bits.append(f"·{count}")
text = "".join(bits) or "​"  # never truly empty: waybar hides empty-text custom modules

status_word = {"idle": "idle", "working": "working ●", "done": "just finished ✓"}[state]
lines = [f"{icon} {label}: {status_word}"]
if count:
    lines[0] += f" ×{count}"
if just_done:
    lines.insert(0, "✓ Task finished")
elif busy:
    lines.insert(0, f"{spin} Task running…")

print(json.dumps({"text": text, "tooltip": "\n".join(lines), "class": state}, ensure_ascii=False))
PY

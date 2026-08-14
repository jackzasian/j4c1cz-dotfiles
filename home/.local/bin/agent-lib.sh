# Shared helpers for agent-here / opencode-here / claude-here / agents-*.
# shellcheck shell=bash

AGENT_HOME_FORBIDDEN="${HOME%/}"
AGENT_CAP_DEFAULT=2
AGENT_TEMP_WARN_C=80

agent_resolve_dir() {
  local dir="${1:-$PWD}"
  if [[ -d "$dir" ]]; then
    (cd "$dir" && pwd -P)
  else
    echo "error: not a directory: $dir" >&2
    return 1
  fi
}

agent_refuse_home() {
  local dir="$1"
  if [[ "$dir" == "$AGENT_HOME_FORBIDDEN" ]]; then
    cat >&2 <<'EOM'
error: refusing workspace $HOME.
That triggers Cursor/rg indexing of the whole home tree (fan storms).
cd into ~/Developer/<repo> or ~/Projects/<repo>, or: agent-project
EOM
    return 1
  fi
}

# Count interactive subscription CLIs (not Cursor IDE, not Mac Hermes).
agent_count_active() {
  local n=0 pid cmd
  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    cmd="$(ps -o cmd= -p "$pid" 2>/dev/null || true)"
    case "$cmd" in
      *'worker start'*|*worker-server*|*agent-cli*|*agents-status*|*agents-stop*|*agent-here*) continue ;;
    esac
    case "$cmd" in
      *cursor-agent*index.js*|*/.local/bin/agent\ *) n=$((n + 1)) ;;
    esac
  done < <(pgrep -f 'cursor-agent|.local/bin/agent' 2>/dev/null || true)

  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    cmd="$(ps -o cmd= -p "$pid" 2>/dev/null || true)"
    case "$cmd" in
      *opencode-here*|*agents-status*|*agents-stop*) continue ;;
      *opencode*) n=$((n + 1)) ;;
    esac
  done < <(pgrep -f opencode 2>/dev/null || true)

  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    cmd="$(ps -o cmd= -p "$pid" 2>/dev/null || true)"
    case "$cmd" in
      *claude-here*|*electron*|*agents-status*|*agents-stop*) continue ;;
      *claude-code/bin/claude*|*/usr/bin/claude*) n=$((n + 1)) ;;
    esac
  done < <(pgrep -f 'claude-code/bin/claude|/usr/bin/claude' 2>/dev/null || true)

  echo "$n"
}

agent_warn_budget() {
  local n temp
  n="$(agent_count_active)"
  if (( n >= AGENT_CAP_DEFAULT )); then
    echo "warn: ${n} subscription agents already running (cap ${AGENT_CAP_DEFAULT}). Prefer one job at a time." >&2
  fi
  if command -v sensors >/dev/null 2>&1; then
    temp="$(sensors 2>/dev/null | awk '/Package id 0:/{gsub(/\+|°C/,"",$4); print int($4); exit}')"
    if [[ -n "$temp" ]] && (( temp >= AGENT_TEMP_WARN_C )); then
      echo "warn: CPU package ${temp}°C — consider agents-stop or wait before starting another." >&2
    fi
  fi
}

agent_pick_project() {
  local roots=("$HOME/Developer" "$HOME/Projects")
  local list="" r d
  for r in "${roots[@]}"; do
    [[ -d "$r" ]] || continue
    while IFS= read -r d; do
      list+="$d"$'\n'
    done < <(find "$r" -mindepth 1 -maxdepth 2 -type d ! -name '.*' ! -name 'node_modules' ! -name '_Sorted' 2>/dev/null | sort)
  done
  if [[ -z "$list" ]]; then
    echo "error: no projects under ~/Developer or ~/Projects" >&2
    return 1
  fi
  if command -v fzf >/dev/null 2>&1; then
    printf '%s' "$list" | fzf --prompt='project> ' --height=40% --reverse
  else
    echo "error: fzf not installed; pass a directory explicitly" >&2
    return 1
  fi
}

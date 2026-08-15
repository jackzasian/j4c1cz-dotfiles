#!/usr/bin/env bash
# Subscription usage-limit bar for waybar: Claude (live, from Claude
# Desktop's own plan-usage-history.json), Cursor + OpenCode (manual,
# shared with the life-dashboard app's usage-limits.json).
#
# Dings once when a service crosses the alert threshold, then re-arms
# only after that service drops threshold-HYSTERESIS below it again —
# so a service sitting right at the line doesn't ding on every poll.
set -euo pipefail

STATE_DIR="${HOME}/.cache/waybar-status"
ALERTED_FILE="${STATE_DIR}/usage-limits-alerted.json"
mkdir -p "${STATE_DIR}"

python3 - "${ALERTED_FILE}" <<'PY'
import json, os, subprocess, sys
from pathlib import Path

alerted_file = Path(sys.argv[1])
HYSTERESIS = 10
DEFAULT_THRESHOLD = 90
ICON = "\U000F0868"  # gauge icon

claude_usage_file = Path.home() / ".config/Claude/plan-usage-history.json"
config_file = Path.home() / ".local/share/life-dashboard/usage-limits.json"


def load_json(path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return default


def claude_percent():
    data = load_json(claude_usage_file, None)
    if not data:
        return None
    samples = data.get("samples") or []
    if not samples:
        return None
    u = samples[-1].get("u") or {}
    vals = [v for v in (u.get("fh"), u.get("sd")) if v is not None]
    return max(vals) if vals else None


cfg = load_json(config_file, {})
threshold = cfg.get("alert_threshold_percent", DEFAULT_THRESHOLD)
svc_cfg = cfg.get("services") or {}

services = [
    ("Claude", claude_percent()),
    ("Cursor", (svc_cfg.get("cursor") or {}).get("usage_percent")),
    ("OpenCode", (svc_cfg.get("opencode") or {}).get("usage_percent")),
]

alerted = set(load_json(alerted_file, []))
newly_alerting = []
still_alerting = set()
for name, pct in services:
    if pct is None:
        continue
    if pct >= threshold:
        still_alerting.add(name)
        if name not in alerted:
            newly_alerting.append((name, pct))
    elif pct < threshold - HYSTERESIS and name in alerted:
        pass  # dropped back below threshold - HYSTERESIS: falls out of `alerted` below

alerted_file.write_text(json.dumps(sorted(still_alerting)))

if newly_alerting:
    icon_file = str(Path.home() / ".config/waybar/icons/claude.png")
    for name, pct in newly_alerting:
        subprocess.Popen(
            ["notify-send", "-a", "Usage limits", "-i", icon_file,
             f"{name} usage at {pct}%", "At or above your alert threshold"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    subprocess.Popen(
        ["paplay", "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

known = [(n, p) for n, p in services if p is not None]
worst = max(known, key=lambda x: x[1]) if known else None


def bar(pct, width=10):
    filled = round(width * pct / 100)
    return "█" * filled + "░" * (width - filled)


if worst is None:
    out = {"text": "", "tooltip": "Usage limits: no data yet", "class": "unknown"}
else:
    name, pct = worst
    if pct >= threshold:
        cls = "alert"
    elif pct >= threshold - HYSTERESIS:
        cls = "warn"
    else:
        cls = "ok"
    # Stay collapsed (zero width) at rest, like the other custom modules in
    # this bar — only take up bar space once something needs attention.
    text = "" if cls == "ok" else f"{ICON} {pct}%"
    lines = [f"Usage limits (alert at {threshold}%)", ""]
    for n, p in services:
        if p is None:
            lines.append(f"{n}: no data")
        else:
            lines.append(f"{n}: {bar(p)} {p}%")
    out = {"text": text, "tooltip": "\n".join(lines), "class": cls}

print(json.dumps(out))
PY

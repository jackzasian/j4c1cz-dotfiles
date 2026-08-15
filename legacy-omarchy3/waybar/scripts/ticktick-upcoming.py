#!/usr/bin/env python3
"""TickTick upcoming tasks for waybar.

Prefers Open API token in ~/.config/ticktick/open-api.env.
Falls back to Electron session cookie + private batch/check sync.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from datetime import date, datetime
from pathlib import Path

CACHE = Path.home() / ".cache/waybar-status/ticktick.json"
# Freshness before skipping a live API call
TTL_BATTERY_SEC = 300  # 5 min on battery
TTL_AC_SEC = 20
OPEN_ENV = Path.home() / ".config/ticktick/open-api.env"
ELECTRON_CFG = Path.home() / ".config/ticktick/config.json"
OPEN_BASE = "https://api.ticktick.com/open/v1"
PRIVATE_SYNC = "https://api.ticktick.com/api/v2/batch/check/0"


def emit(text: str, tooltip: str, cls: str) -> None:
    print(json.dumps({"text": text, "tooltip": tooltip, "class": cls}, ensure_ascii=False))


def load_env(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    if not path.exists():
        return out
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def http_json(url: str, headers: dict[str, str], timeout: float = 25) -> dict | list:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode())


def parse_due(raw: str | None) -> date | None:
    if not raw:
        return None
    # TickTick uses ISO with Z or offset, sometimes "YYYY-MM-DDTHH:MM:SS.000+0000"
    s = raw.replace("+0000", "+00:00")
    try:
        if s.endswith("Z"):
            dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        else:
            dt = datetime.fromisoformat(s)
        return dt.date()
    except ValueError:
        try:
            return date.fromisoformat(s[:10])
        except ValueError:
            return None


def incomplete_upcoming(tasks: list[dict]) -> list[tuple[date, str]]:
    """Today + future incomplete tasks only (never overdue / completed)."""
    today = date.today()
    rows: list[tuple[date, str]] = []
    seen: set[str] = set()
    for t in tasks:
        tid = str(t.get("id") or "")
        if tid and tid in seen:
            continue
        if tid:
            seen.add(tid)
        # Completed / cancelled
        status = t.get("status")
        if status in (2, -1) or t.get("completedTime"):
            continue
        due = parse_due(t.get("dueDate"))
        if due is None or due < today:
            continue
        title = (t.get("title") or "Untitled").strip()
        if not title:
            continue
        rows.append((due, title))
    rows.sort(key=lambda x: (x[0], x[1].lower()))
    return rows


def fetch_open_api(token: str) -> list[dict]:
    headers = {
        "Authorization": f"Bearer {token}",
        "User-Agent": "waybar-ticktick/1.0",
    }
    projects = http_json(f"{OPEN_BASE}/project", headers)
    if not isinstance(projects, list):
        return []
    tasks: list[dict] = []
    for p in projects:
        pid = p.get("id")
        if not pid:
            continue
        try:
            data = http_json(f"{OPEN_BASE}/project/{pid}/data", headers)
        except urllib.error.HTTPError:
            continue
        if isinstance(data, dict):
            tasks.extend(data.get("tasks") or [])
    return tasks


def fetch_private() -> list[dict]:
    if not ELECTRON_CFG.exists():
        raise FileNotFoundError("no electron config")
    cfg = json.loads(ELECTRON_CFG.read_text())
    tok = cfg.get("token")
    if not tok:
        raise RuntimeError("no session token")
    headers = {
        "Cookie": f"t={tok}",
        "User-Agent": "Mozilla/5.0",
        "x-device": "web",
        "Accept": "application/json",
    }
    data = http_json(PRIVATE_SYNC, headers, timeout=20)
    bean = (data or {}).get("syncTaskBean") or {}
    # Full snapshot from check/0; drop anything marked deleted in this payload
    deleted = {str(x) for x in (bean.get("delete") or [])}
    tasks = []
    for t in bean.get("update") or []:
        tid = str(t.get("id") or "")
        if tid and tid in deleted:
            continue
        tasks.append(t)
    return tasks


def on_battery() -> bool:
    for path in Path("/sys/class/power_supply").glob("*"):
        try:
            ptype = (path / "type").read_text().strip()
        except OSError:
            continue
        if ptype not in ("Mains", "USB"):
            continue
        try:
            online = (path / "online").read_text().strip()
        except OSError:
            online = "0"
        if online == "1":
            return False
        # Adapter exists but offline → likely on battery (check all first)
    adapters = []
    for path in Path("/sys/class/power_supply").glob("*"):
        try:
            if (path / "type").read_text().strip() in ("Mains", "USB"):
                adapters.append(path)
        except OSError:
            continue
    if not adapters:
        return False
    return all((p / "online").read_text().strip() != "1" for p in adapters if (p / "online").exists())


def cache_age_sec() -> float | None:
    if not CACHE.exists():
        return None
    return max(0.0, datetime.now().timestamp() - CACHE.stat().st_mtime)


def emit_rows(rows: list[tuple[date, str]], source: str) -> int:
    today = date.today()
    upcoming = [(d, t) for d, t in rows if d >= today]
    if not upcoming:
        emit("󰃯 —", f"No upcoming tasks ({source})", "empty")
        return 0
    next_due, next_title = upcoming[0]
    short = next_title if len(next_title) <= 28 else next_title[:25] + "…"
    when = "today" if next_due == today else next_due.isoformat()
    lines = [f"Next · {when} · {next_title}", f"Upcoming: {len(upcoming)} ({source})"]
    for d, t in upcoming[:6]:
        mark = "·" if d == today else " "
        lines.append(f"{mark} {d.isoformat()}  {t}")
    emit(f"󰃯 {short}", "\n".join(lines), "ok")
    return 0


def read_stale_cache() -> list[tuple[date, str]] | None:
    if not CACHE.exists():
        return None
    try:
        raw = json.loads(CACHE.read_text())
        return [(date.fromisoformat(d), t) for d, t in raw]
    except Exception:
        return None


def write_cache(rows: list[tuple[date, str]]) -> None:
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps([[d.isoformat(), t] for d, t in rows]))


def fetch_live() -> tuple[list[tuple[date, str]], str]:
    env = load_env(OPEN_ENV)
    token = env.get("TICKTICK_ACCESS_TOKEN") or os.environ.get("TICKTICK_ACCESS_TOKEN")
    if token:
        tasks = fetch_open_api(token)
        return incomplete_upcoming(tasks), "open-api"
    tasks = fetch_private()
    return incomplete_upcoming(tasks), "session"


def main() -> int:
    force = "--force" in sys.argv
    bat = on_battery()
    ttl = TTL_BATTERY_SEC if bat else TTL_AC_SEC
    age = cache_age_sec()
    cached = read_stale_cache()

    if not force and cached is not None and age is not None and age < ttl:
        src = f"cache·{int(age)}s" + ("·bat" if bat else "·ac")
        return emit_rows(cached, src)

    try:
        rows, source = fetch_live()
        write_cache(rows)
        if bat:
            source = f"{source}·bat"
        return emit_rows(rows, source)
    except Exception as exc:
        if cached is not None:
            return emit_rows(cached, "stale-cache")
        tip = (
            "Set ~/.config/ticktick/open-api.env\n"
            "TICKTICK_ACCESS_TOKEN=...\n"
            f"or keep TickTick logged in.\n({exc})"
        )
        emit("󰃯 —", tip, "missing")
        return 0


if __name__ == "__main__":
    sys.exit(main())

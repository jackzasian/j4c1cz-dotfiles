#!/usr/bin/env python3
"""Today / upcoming TaskNotes for waybar (replaces TickTick widget)."""
from __future__ import annotations

import json
import re
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

TASKS = Path.home() / "Obsidian/J4c1c/TaskNotes/Tasks"
CACHE = Path.home() / ".cache/waybar-status/tasknotes.json"
TITLE_RE = re.compile(r"^title:\s*[\"']?(.*?)[\"']?\s*$", re.M)
STATUS_RE = re.compile(r"^status:\s*(\S+)", re.M)
SCHEDULED_RE = re.compile(r"^scheduled:\s*[\"']?([^\s\"']+)", re.M)
DUE_RE = re.compile(r"^due:\s*[\"']?([^\s\"']+)", re.M)
PRIORITY_RE = re.compile(r"^priority:\s*(\S+)", re.M)


def emit(text: str, tooltip: str, cls: str) -> None:
    print(json.dumps({"text": text, "tooltip": tooltip, "class": cls}, ensure_ascii=False))


def parse_dt(raw: str) -> tuple[date, str | None] | None:
    raw = raw.strip().strip("\"'")
    try:
        d = date.fromisoformat(raw[:10])
    except ValueError:
        return None
    t = None
    if len(raw) > 10 and raw[10] in "T ":
        m = re.match(r"(\d{2}:\d{2})", raw[11:])
        if m:
            t = m.group(1)
    return d, t


def collect() -> list[tuple[date, int, str | None, str, str]]:
    today = date.today()
    horizon = today + timedelta(days=7)
    rows: list[tuple[date, int, str | None, str, str]] = []
    if not TASKS.is_dir():
        return rows
    for path in TASKS.glob("*.md"):
        text = path.read_text(errors="ignore")
        st = STATUS_RE.search(text)
        if st and st.group(1).lower() in {"done", "cancelled", "canceled"}:
            continue
        title = (TITLE_RE.search(text).group(1) if TITLE_RE.search(text) else path.stem).strip()
        pri = (PRIORITY_RE.search(text).group(1) if PRIORITY_RE.search(text) else "normal").lower()
        candidates: list[tuple[date, str | None]] = []
        for rx in (SCHEDULED_RE, DUE_RE):
            m = rx.search(text)
            if m:
                dt = parse_dt(m.group(1))
                if dt:
                    candidates.append(dt)
        if not candidates:
            continue
        # earliest by (date, time-of-day) -- untimed entries sort after
        # timed ones on the same day, so a 08:00 task counts as "sooner"
        # than an all-day one due the same date.
        d, t = min(candidates, key=lambda dt: (dt[0], dt[1] or "24:00"))
        if d < today or d > horizon:
            continue
        minutes = -1
        if t:
            hh, mm = t.split(":")
            minutes = int(hh) * 60 + int(mm)
        rows.append((d, minutes, t, title, pri))
    rows.sort(key=lambda r: (r[0], r[1] if r[1] >= 0 else 24 * 60, 0 if r[4] == "high" else 1, r[3]))
    return rows


def main() -> int:
    force = "--force" in sys.argv
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    if not force and CACHE.exists():
        age = datetime.now().timestamp() - CACHE.stat().st_mtime
        if age < 15:
            print(CACHE.read_text())
            return 0

    rows = collect()
    today = date.today()
    today_n = sum(1 for d, _, _, _, _ in rows if d == today)
    soon = [r for r in rows if r[0] > today][:5]
    high_today = any(d == today and p == "high" for d, _, _, _, p in rows)

    if not rows:
        text = "📋 –"
        tip = "No TaskNotes scheduled in the next 7 days"
        cls = "idle"
    else:
        next_date, _, next_time, next_title, next_pri = rows[0]
        label = next_title if len(next_title) <= 8 else next_title[:7] + "…"
        when = "today" if next_date == today else next_date.strftime("%a")
        lead = "🔴" if next_date == today and next_pri == "high" else "•"
        text = f"📋 {lead} {label}"
        next_when = f"{when}" + (f" {next_time}" if next_time else "")
        lines = [f"Next ({next_when}): {next_title}", f"Today ({today.isoformat()}):"]
        for d, _, t, title, pri in rows:
            if d == today:
                mark = "🔴" if pri == "high" else "•"
                tpart = f"{t} " if t else ""
                lines.append(f"  {mark} {tpart}{title}")
        if soon:
            lines.append("Upcoming:")
            for d, _, t, title, pri in soon:
                tpart = f" {t}" if t else ""
                lines.append(f"  {d}{tpart} · {title}")
        tip = "\n".join(lines)
        cls = "overdue" if high_today else "active"

    payload = json.dumps({"text": text, "tooltip": tip, "class": cls}, ensure_ascii=False)
    CACHE.write_text(payload + "\n")
    print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

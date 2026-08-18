"""Zen Browser bookmark sync into Links/links-inbox.md (optional extra)."""

from __future__ import annotations

import re
import shutil
import sqlite3
import sys
import tempfile
import urllib.parse
from datetime import date
from pathlib import Path

from . import config
from .notify import notify
from .recent import prepend_recent
from .urls import MD_LINK_RE, clean_title, decode_park_url, normalize_url, skip_url, url_key


def find_places_db() -> Path | None:
    root = config.zen_root()
    if not root.is_dir():
        return None
    candidates = sorted(root.glob("*/places.sqlite"), key=lambda p: p.stat().st_mtime, reverse=True)
    return candidates[0] if candidates else None


def read_zen_bookmarks(db_src: Path) -> list[tuple[str, str]]:
    with tempfile.TemporaryDirectory(prefix="zen-links-") as tmp:
        tmp_path = Path(tmp)
        db = tmp_path / "places.sqlite"
        shutil.copy2(db_src, db)
        for suffix in ("-wal", "-shm"):
            side = Path(str(db_src) + suffix)
            if side.exists():
                shutil.copy2(side, tmp_path / f"places.sqlite{suffix}")

        conn = sqlite3.connect(db)
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            """
            SELECT b.title AS title, p.url AS url
            FROM moz_bookmarks b
            JOIN moz_places p ON b.fk = p.id
            WHERE b.type = 1
            ORDER BY b.dateAdded DESC
            """
        ).fetchall()
        conn.close()

    out: list[tuple[str, str]] = []
    seen: set[tuple] = set()
    for row in rows:
        url = decode_park_url(row["url"] or "")
        if skip_url(url):
            continue
        url = normalize_url(url)
        key = url_key(url)
        if key in seen:
            continue
        seen.add(key)
        title = clean_title(row["title"] or "", url)
        raw = row["url"] or ""
        if "park.html" in raw:
            qs = urllib.parse.parse_qs(urllib.parse.urlparse(raw).query)
            if "title" in qs:
                title = clean_title(qs["title"][0], url)
        out.append((title, url))
    return out


def existing_keys() -> set[tuple]:
    keys: set[tuple] = set()
    for path in config.links_dir().glob("*.md"):
        try:
            text = path.read_text(errors="ignore")
        except OSError:
            continue
        for _, url in MD_LINK_RE.findall(text):
            keys.add(url_key(url))
    return keys


def append_inbox(new_items: list[tuple[str, str]]) -> None:
    today = date.today().isoformat()
    heading = f"## Zen sync {today}"
    inbox = config.links_dir() / "links-inbox.md"
    text = inbox.read_text(errors="ignore") if inbox.exists() else ""

    def render(items: list[tuple[str, str]]) -> list[str]:
        out = [heading, ""]
        for title, url in items:
            safe = title.replace("[", "(").replace("]", ")")
            out.append(f"- [{safe}]({url})")
        out.append("")
        return out

    if heading in text:
        parts = re.split(r"(?=^## )", text, flags=re.M)
        rebuilt: list[str] = []
        done = False
        for part in parts:
            if part.startswith(heading) and not done:
                existing_urls = {url_key(u) for _, u in MD_LINK_RE.findall(part)}
                extra = [(t, u) for t, u in new_items if url_key(u) not in existing_urls]
                if extra:
                    rebuilt.append(part.rstrip() + "\n" + "\n".join(render(extra)[1:-1]) + "\n\n")
                else:
                    rebuilt.append(part)
                done = True
            else:
                rebuilt.append(part)
        text = "".join(rebuilt)
    else:
        text = text.rstrip() + "\n\n" + "\n".join(render(new_items))

    inbox.write_text(text if text.endswith("\n") else text + "\n")


def run_sync(_args=None) -> int:
    links_dir = config.links_dir()
    inbox = links_dir / "links-inbox.md"
    if not links_dir.is_dir():
        notify("Links folder missing", str(links_dir), "critical")
        print(f"Missing {links_dir}", file=sys.stderr)
        return 1
    if not inbox.exists():
        notify("links-inbox.md missing", str(inbox), "critical")
        print(f"Missing {inbox}", file=sys.stderr)
        return 1

    db = find_places_db()
    if not db:
        notify("Zen profile not found", str(config.zen_root()), "critical")
        print(f"No places.sqlite under {config.zen_root()}", file=sys.stderr)
        return 1

    existing = existing_keys()
    bookmarks = read_zen_bookmarks(db)
    new_items = [(t, u) for t, u in bookmarks if url_key(u) not in existing]

    if not new_items:
        notify("Zen sync", "No new bookmarks")
        print("No new Zen bookmarks")
        return 0

    append_inbox(new_items)
    for title, url in new_items:
        prepend_recent("inbox", title, url, source="zen")
    notify("Zen sync", f"{len(new_items)} new → links-inbox")
    print(f"Appended {len(new_items)} new bookmarks to {inbox}")
    for title, url in new_items[:20]:
        print(f"  - {title}: {url}")
    if len(new_items) > 20:
        print(f"  … and {len(new_items) - 20} more")
    return 0
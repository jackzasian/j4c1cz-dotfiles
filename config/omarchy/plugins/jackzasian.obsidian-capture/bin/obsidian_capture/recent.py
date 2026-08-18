"""Newest-first feed in Links/links-recent.md (cap RECENT_CAP)."""

from __future__ import annotations

import re
from datetime import date

from . import config

RECENT_CAP = 50
RECENT_LINE_RE = re.compile(r"^- `\d{4}-\d{2}-\d{2}`")

_DEFAULT_TEXT = """---
id: 202607312010
title: "Recent Links"
created: 2026-07-31
tags: [links, recent]
up: [[202507291200-links-moc]]
---

# Recent Links

Newest first. Auto-updated when you save a link or run Zen sync. Cap: **50**.

---

## Feed

"""


def recent_file() -> object:
    return config.links_dir() / "links-recent.md"


def prepend_recent(topic: str, title: str, url: str, *, source: str = "capture") -> None:
    """Keep a newest-first feed in links-recent.md (max RECENT_CAP)."""
    today = date.today().isoformat()
    safe = title.replace("[", "(").replace("]", ")")
    tag = "zen" if source == "zen" else topic
    entry = f"- `{today}` · {tag} · [{safe}]({url})"

    path = recent_file()
    if path.exists():
        text = path.read_text(errors="ignore")
    else:
        text = _DEFAULT_TEXT

    if "## Feed" not in text:
        text = text.rstrip() + "\n\n## Feed\n\n"

    head, _, tail = text.partition("## Feed")
    rest = tail.lstrip("\n")
    lines = rest.splitlines()
    while lines and not lines[0].strip():
        lines.pop(0)

    existing = []
    other = []
    for line in lines:
        if RECENT_LINE_RE.match(line):
            existing.append(line)
        elif line.strip() == "":
            continue
        else:
            other.append(line)

    url_frag = f"]({url})"
    existing = [ln for ln in existing if url_frag not in ln]
    feed = [entry] + existing
    feed = feed[:RECENT_CAP]

    body = head + "## Feed\n\n" + "\n".join(feed) + "\n"
    if other:
        body += "\n" + "\n".join(other) + "\n"
    path.write_text(body if body.endswith("\n") else body + "\n")
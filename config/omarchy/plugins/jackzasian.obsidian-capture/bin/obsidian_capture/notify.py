"""Desktop notifications via notify-send (best-effort)."""

from __future__ import annotations

import subprocess


def notify(title: str, body: str = "", urgency: str = "normal", app: str = "Obsidian Capture") -> None:
    try:
        subprocess.run(
            ["notify-send", "-u", urgency, "-a", app, title, body],
            check=False,
            timeout=5,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
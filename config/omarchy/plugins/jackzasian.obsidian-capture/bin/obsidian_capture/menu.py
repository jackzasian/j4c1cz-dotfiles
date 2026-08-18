"""omarchy-menu based input/select prompts.

These call the native omarchy-menu-input / omarchy-menu-select wrappers, which
summon the Omarchy menu (Super+Space UI) in dmenu mode. Both print the
selection to stdout and exit non-zero on cancel.
"""

from __future__ import annotations

import subprocess


def menu_input(placeholder: str) -> str | None:
    cmd = ["omarchy-menu-input", placeholder]
    return _run(cmd)


def menu_pick(lines: list[str], placeholder: str) -> str | None:
    if not lines:
        return menu_input(placeholder)
    cmd = ["omarchy-menu-select", placeholder, *lines]
    return _run(cmd)


def _run(cmd: list[str]) -> str | None:
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None
    if proc.returncode != 0:
        return None
    out = (proc.stdout or "").strip()
    return out or None
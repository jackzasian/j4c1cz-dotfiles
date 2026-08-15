#!/usr/bin/env python3
"""Waybar custom module: one workspace with deduplicated app icons."""

from __future__ import annotations

import json
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gio", "2.0")
from gi.repository import Gio, Gtk  # noqa: E402

WORKSPACE_ID = int(sys.argv[1]) if len(sys.argv) > 1 else 1
ICON_SIZE = int(sys.argv[2]) if len(sys.argv) > 2 else 14
ICON_THEMES = ["Yaru-olive", "Yaru", "breeze", "breeze-dark", "Adwaita"]
DESKTOP_IDS = {
    "cursor": "cursor.desktop",
    "Cursor": "cursor.desktop",
    "zen": "zen.desktop",
    "kitty": "kitty.desktop",
    "clash-verge": "clash-verge.desktop",
    "Clash Verge": "clash-verge.desktop",
}


def hypr_json(args: list[str]):
    return json.loads(subprocess.check_output(["hyprctl", *args], text=True))


def icon_from_theme(theme: Gtk.IconTheme, name: str) -> str | None:
    info = theme.lookup_icon(name, ICON_SIZE, 0)
    if info is not None:
        return info.get_filename()
    return None


def icon_from_desktop(theme: Gtk.IconTheme, app_class: str) -> str | None:
    desktop_id = DESKTOP_IDS.get(app_class, f"{app_class.lower()}.desktop")
    try:
        gi.require_version("GioUnix", "2.0")
        from gi.repository import GioUnix

        app = GioUnix.DesktopAppInfo.new(desktop_id)
    except (ValueError, ImportError):
        app = Gio.DesktopAppInfo.new(desktop_id)
    if app is None:
        return None
    gicon = app.get_icon()
    if gicon is None:
        return None
    info = theme.lookup_by_gicon(gicon, ICON_SIZE, 0)
    if info is not None:
        return info.get_filename()
    return None


def icon_path(app_class: str) -> str | None:
    theme = Gtk.IconTheme.new()
    for name in ICON_THEMES:
        theme.set_custom_theme(name)
        path = icon_from_theme(theme, app_class)
        if path:
            return path
        path = icon_from_desktop(theme, app_class)
        if path:
            return path
    return None


def main() -> None:
    clients = hypr_json(["clients", "-j"])
    active = hypr_json(["activeworkspace", "-j"])
    groups: OrderedDict[str, dict] = OrderedDict()

    for client in clients:
        workspace = client.get("workspace", {})
        if workspace.get("id") != WORKSPACE_ID:
            continue
        if client.get("mapped") is False:
            continue

        app_class = client.get("class") or client.get("initialClass") or "unknown"
        entry = groups.setdefault(
            app_class,
            {"count": 0, "titles": [], "active": False},
        )
        entry["count"] += 1
        title = client.get("title") or app_class
        entry["titles"].append(title)
        if client.get("focused"):
            entry["active"] = True

    parts: list[str] = [f"<span>{WORKSPACE_ID}</span>"]
    tooltip_lines: list[str] = [f"Workspace {WORKSPACE_ID}"]

    for app_class, info in groups.items():
        path = icon_path(app_class)
        if path:
            parts.append(
                f'<img src="file://{path}" height="{ICON_SIZE}" width="{ICON_SIZE}"/>'
            )
        if info["count"] > 1:
            parts.append(f"<span baseline_shift=\"superscript\" size=\"x-small\">×{info['count']}</span>")
        tooltip_lines.append(f"{app_class} ({info['count']}): {', '.join(info['titles'][:4])}")

    classes: list[str] = []
    if active.get("id") == WORKSPACE_ID:
        classes.append("active")
    elif groups:
        classes.append("visible")
    if not groups:
        classes.append("empty")

    payload = {
        "text": " ".join(parts) if groups else str(WORKSPACE_ID),
        "tooltip": "\n".join(tooltip_lines),
        "class": " ".join(classes),
    }
    print(json.dumps(payload, ensure_ascii=False))


if __name__ == "__main__":
    main()

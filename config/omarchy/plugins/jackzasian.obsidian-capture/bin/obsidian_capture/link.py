"""Link capture: clipboard/argv URL → topic file + recent feed."""

from __future__ import annotations

import re
import subprocess
import sys

from . import config
from .menu import menu_input, menu_pick
from .notify import notify
from .topics import TOPICS
from .urls import MD_LINK_RE, extract_url, md_escape_title, url_key


def append_link(topic: str, title: str, url: str) -> object:
    filename = TOPICS[topic]
    path = config.links_dir() / filename
    if not path.exists():
        raise FileNotFoundError(path)

    line = f"- [{md_escape_title(title)}]({url})"
    text = path.read_text(errors="ignore")

    if topic == "inbox":
        marker = "## To Sort"
        if marker not in text:
            text = text.rstrip() + f"\n\n{marker}\n\n"
        text = re.sub(
            rf"({re.escape(marker)}\n(?:\n)?)-\s*\n",
            r"\1",
            text,
            count=1,
        )
        parts = re.split(r"(?=^## )", text, flags=re.M)
        out: list[str] = []
        done = False
        for part in parts:
            if part.startswith(marker) and not done:
                body = part.rstrip() + "\n" + line + "\n\n"
                out.append(body)
                done = True
            else:
                out.append(part)
        if not done:
            text = text.rstrip() + f"\n\n{marker}\n\n{line}\n"
        else:
            text = "".join(out)
    else:
        marker = "## Captured"
        if marker not in text:
            text = text.rstrip() + f"\n\n{marker}\n\n{line}\n"
        else:
            parts = re.split(r"(?=^## )", text, flags=re.M)
            out = []
            done = False
            for part in parts:
                if part.startswith(marker) and not done:
                    out.append(part.rstrip() + "\n" + line + "\n\n")
                    done = True
                else:
                    out.append(part)
            text = "".join(out) if done else text.rstrip() + f"\n\n{marker}\n\n{line}\n"

    path.write_text(text if text.endswith("\n") else text + "\n")
    return path


def existing_keys() -> set[tuple]:
    keys: set[tuple] = set()
    if not config.links_dir().is_dir():
        return keys
    for path in config.links_dir().glob("*.md"):
        try:
            text = path.read_text(errors="ignore")
        except OSError:
            continue
        for _, url in MD_LINK_RE.findall(text):
            keys.add(url_key(url))
    return keys


def clipboard_url() -> str | None:
    """URL from the Wayland clipboard, if it holds text."""
    try:
        types_proc = subprocess.run(["wl-paste", "-l"], capture_output=True, text=True, timeout=3)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None
    mimes = (types_proc.stdout or "").splitlines()
    if mimes and not any(m.startswith("text/") for m in mimes):
        return None

    try:
        proc = subprocess.run(["wl-paste", "-n"], capture_output=True, timeout=3)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None
    text = (proc.stdout or b"").decode("utf-8", errors="ignore")
    return extract_url(text)


def resolve_url(arg_url: str | None) -> str | None:
    if arg_url:
        return extract_url(arg_url)
    url = clipboard_url()
    if url:
        return url
    pasted = menu_input("Paste URL…")
    if pasted:
        return extract_url(pasted)
    return None


def run_link(args) -> int:
    from .urls import fetch_title, normalize_url

    if not config.links_dir().is_dir():
        notify("Links folder missing", str(config.links_dir()), "critical")
        print(f"Missing {config.links_dir()}", file=sys.stderr)
        return 1

    url = resolve_url(args.url)
    if not url:
        notify("No URL", "Copy a link, then press Super+Shift+Ctrl+L again", "critical")
        return 1

    url = normalize_url(url)
    if url_key(url) in existing_keys():
        notify("Already saved", url)
        print(f"Already saved: {url}")
        return 0

    topic = args.topic
    if not topic:
        picked = menu_pick(list(TOPICS), "Save link to…")
        if not picked:
            notify("Cancelled", "", "low")
            return 130
        topic = picked.strip().lower()
        if topic not in TOPICS:
            notify("Unknown topic", topic, "critical")
            return 1

    title = args.title or fetch_title(url)
    try:
        path = append_link(topic, title, url)
    except Exception as exc:
        notify("Save failed", str(exc), "critical")
        print(exc, file=sys.stderr)
        return 1

    from .recent import prepend_recent

    prepend_recent(topic, title, url, source="capture")
    notify(f"Saved → {path.stem}", title)
    print(f"Saved to {path}: {title} — {url}")
    return 0
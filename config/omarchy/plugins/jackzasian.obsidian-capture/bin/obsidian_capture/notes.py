"""Quick note capture: Obsidian Inbox and/or j4c1cz.com/notes."""

from __future__ import annotations

import json
import os
import re
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path

from . import config
from .menu import menu_input, menu_pick
from .notify import notify
from .urls import extract_url

MAX_WEB = 500
SLUG_RE = re.compile(r"[^a-z0-9]+")


def load_env_file(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    if not path.exists():
        return out
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def notes_config() -> dict[str, str]:
    cfg: dict[str, str] = {}
    for path in config.notes_env_files():
        cfg.update(load_env_file(path))
    return cfg


def slugify(text: str, *, max_len: int = 48) -> str:
    s = SLUG_RE.sub("-", text.strip().lower()).strip("-")
    if not s:
        return "note"
    if len(s) > max_len:
        s = s[:max_len].rstrip("-")
    return s or "note"


def derive_title(body: str, explicit: str | None) -> str:
    if explicit and explicit.strip():
        return explicit.strip()
    first = body.strip().splitlines()[0].strip() if body.strip() else "Untitled"
    first = re.sub(r"^#+\s*", "", first)
    first = re.sub(r"^[-*]\s+", "", first)
    if len(first) > 72:
        first = first[:69].rstrip() + "…"
    return first or "Untitled"


def unique_path(stamp: str, slug: str) -> Path:
    base = config.inbox_dir() / f"{stamp}-{slug}.md"
    if not base.exists():
        return base
    for i in range(2, 50):
        cand = config.inbox_dir() / f"{stamp}-{slug}-{i}.md"
        if not cand.exists():
            return cand
    return config.inbox_dir() / f"{stamp}-{slug}-{os.getpid()}.md"


def write_inbox(title: str, body: str) -> Path:
    config.inbox_dir().mkdir(parents=True, exist_ok=True)
    now = datetime.now()
    stamp = now.strftime("%Y%m%d%H%M")
    created = now.strftime("%Y-%m-%d")
    path = unique_path(stamp, slugify(title))
    body = body.strip()
    content = ""
    if body and body != title:
        content = body + "\n\n"
    text = (
        f"---\n"
        f'title: "{title.replace(chr(34), chr(39))}"\n'
        f"created: {created}\n"
        f"tags: [inbox]\n"
        f"type: note\n"
        f"---\n\n"
        f"# {title}\n\n"
        f"{content}"
    )
    path.write_text(text if text.endswith("\n") else text + "\n")
    return path


def open_inbox(file_rel: str | None = None) -> None:
    target = file_rel or "Inbox"
    vault_q = urllib.parse.quote(config.vault_name(), safe="")
    file_q = urllib.parse.quote(target, safe="")
    uri = f"obsidian://open?vault={vault_q}&file={file_q}"
    subprocess.run(["omarchy-launch-or-focus", "^obsidian$", "uwsm-app -- obsidian"], check=False, capture_output=True)
    subprocess.run(["xdg-open", uri], check=False, capture_output=True)


def new_note_id() -> str:
    return f"{int(time.time() * 1000):x}{secrets.token_hex(3)}"


def post_via_api(cfg: dict[str, str], text: str, url: str | None) -> dict:
    token = cfg.get("NOTES_TOKEN") or cfg.get("PUBLISH_TOKEN") or ""
    api = cfg.get("NOTES_API_URL") or "https://j4c1cz.com/api/notes"
    if not token:
        raise RuntimeError("no NOTES_TOKEN")
    req = urllib.request.Request(
        api,
        data=json.dumps({"text": text, "url": url}).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "obsidian-capture/1.0",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="ignore")
        raise RuntimeError(f"API {e.code}: {body}") from e


def upstash_cmd(cfg: dict[str, str], command: list) -> object:
    base = cfg.get("UPSTASH_REDIS_REST_URL", "").rstrip("/")
    token = cfg.get("UPSTASH_REDIS_REST_TOKEN", "")
    if not base or not token:
        raise RuntimeError("Upstash not configured")
    req = urllib.request.Request(
        base,
        data=json.dumps(command).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        payload = json.loads(resp.read().decode())
    if isinstance(payload, dict) and payload.get("error"):
        raise RuntimeError(str(payload["error"]))
    return payload.get("result") if isinstance(payload, dict) else payload


def post_via_upstash(cfg: dict[str, str], text: str, url: str | None) -> dict:
    note_id = new_note_id()
    note = {"id": note_id, "text": text, "createdAt": int(time.time() * 1000)}
    if url:
        note["url"] = url
    upstash_cmd(cfg, ["SET", f"content:note:{note_id}", json.dumps(note, ensure_ascii=False)])
    upstash_cmd(cfg, ["SADD", "content:notes", note_id])
    return {"ok": True, "id": note_id, "url": "/notes", "via": "upstash"}


def publish_web(text: str, url: str | None) -> dict:
    text = text.strip()
    if not text:
        raise RuntimeError("empty note")
    if len(text) > MAX_WEB:
        raise RuntimeError(f"notes are max {MAX_WEB} characters ({len(text)})")
    if url:
        try:
            urllib.parse.urlparse(url)
            if not url.startswith(("http://", "https://")):
                raise ValueError("bad scheme")
        except Exception as exc:
            raise RuntimeError("URL looks invalid") from exc

    cfg = notes_config()
    if cfg.get("NOTES_TOKEN"):
        try:
            return post_via_api(cfg, text, url)
        except Exception:
            pass
    return post_via_upstash(cfg, text, url)


def zenity_edit(initial: str = "") -> str | None:
    try:
        proc = subprocess.run(
            ["zenity", "--text-info", "--editable", "--title=Note", "--width=520", "--height=320"],
            input=initial,
            text=True,
            capture_output=True,
            timeout=600,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None
    if proc.returncode != 0:
        return None
    out = (proc.stdout or "").rstrip()
    return out or None


def resolve_body(args, *, edit: bool = False) -> str | None:
    if edit or getattr(args, "edit", False):
        return zenity_edit(" ".join(args.text) if args.text else "")
    if args.text:
        return " ".join(args.text).strip()
    if not os.isatty(0):
        data = sys.stdin.read().strip()
        if data:
            return data
    return menu_input("Quick note…")


def run_note(args, *, dest: str = "inbox", body: str | None = None, edit: bool = False) -> int:
    if args.inbox:
        open_inbox("Inbox")
        notify("Inbox", "Opened in Obsidian")
        return 0

    if body is None:
        body = resolve_body(args, edit=edit)
    if not body:
        notify("Cancelled", "", "low")
        return 130

    if not config.vault_dir().is_dir() and dest != "site":
        notify("Vault missing", str(config.vault_dir()), "critical")
        return 1

    url = args.url
    if not url and dest == "site":
        maybe = extract_url(body)
        if maybe and body.strip() == maybe:
            url = maybe

    messages: list[str] = []

    if dest in {"inbox", "both"}:
        if not config.vault_dir().is_dir():
            notify("Vault missing", str(config.vault_dir()), "critical")
            return 1
        title = derive_title(body, args.title)
        try:
            path = write_inbox(title, body)
        except OSError as exc:
            notify("Inbox save failed", str(exc), "critical")
            return 1
        messages.append(f"Inbox → {path.name}")
        print(f"Saved {path}")
        if args.open:
            rel = path.relative_to(config.vault_dir()).with_suffix("").as_posix()
            open_inbox(rel)

    if dest in {"site", "both"}:
        try:
            res = publish_web(body, url)
        except Exception as exc:
            notify("Site post failed", str(exc), "critical")
            print(exc, file=sys.stderr)
            return 1
        site = notes_config().get("SITE_URL", "https://j4c1cz.com").rstrip("/")
        link = f"{site}/notes"
        messages.append(f"Site → {link}")
        print(f"Posted {res.get('id')} → {link}")
        notify("Posted to j4c1cz.com", body[:80])
    else:
        notify("Saved → Inbox", messages[0] if messages else "")

    if dest == "both":
        notify("Saved inbox + site", body[:80])

    return 0


def run_dest(args) -> int:
    body = resolve_body(args)
    if not body:
        notify("Cancelled", "", "low")
        return 130
    picked = menu_pick(
        ["inbox — private Obsidian", "site — j4c1cz.com/notes", "both"],
        "Save note to…",
    )
    if not picked:
        notify("Cancelled", "", "low")
        return 130
    key = picked.split("—", 1)[0].strip().lower()
    if key not in {"inbox", "site", "both"}:
        notify("Cancelled", "", "low")
        return 130
    return run_note(args, dest=key, body=body)
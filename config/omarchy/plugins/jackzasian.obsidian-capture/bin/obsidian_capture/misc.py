"""Recent-feed opener and Links/ → git push (optional extras)."""

from __future__ import annotations

import fcntl
import os
import subprocess
import sys
from pathlib import Path

from . import config
from .notify import notify

RECENT_LOCK = Path.home() / ".cache" / "obsidian-links-github-push.lock"
RECENT_LOG = Path.home() / ".cache" / "obsidian-links-github-push.log"


def open_recent(_args=None) -> int:
    import urllib.parse

    vault_q = urllib.parse.quote(config.vault_name(), safe="")
    file_q = urllib.parse.quote("Links/links-recent", safe="")
    uri = f"obsidian://open?vault={vault_q}&file={file_q}"

    if _run_quiet(["omarchy-launch-or-focus", "^obsidian$", "uwsm-app -- obsidian"]):
        pass
    if not _run_quiet(["xdg-open", uri]):
        recent = config.links_dir() / "links-recent.md"
        if _run_quiet(["xdg-open", str(recent)]):
            pass

    notify("Recent links", "Opened links-recent")
    return 0


def _run_quiet(cmd: list[str]) -> bool:
    try:
        proc = subprocess.run(cmd, capture_output=True, timeout=15)
        return proc.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def run_push(_args=None) -> int:
    vault = config.vault_dir()
    links_rel = "Links"
    branch = os.environ.get("OBSIDIAN_VAULT_BRANCH", "main")
    remote = os.environ.get("OBSIDIAN_VAULT_REMOTE", "origin")

    RECENT_LOCK.parent.mkdir(parents=True, exist_ok=True)
    lock_fd = os.open(str(RECENT_LOCK), os.O_RDWR | os.O_CREAT, 0o644)
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        print("obsidian-capture push: already running", file=sys.stderr)
        return 0

    log = open(RECENT_LOG, "a")
    try:
        _log(log, f"=== {_now()} ===")
        if not (vault / ".git").is_dir():
            _log(log, f"ERROR: {vault} is not a git repository")
            notify("Links push failed", "Vault is not a git repo", "critical")
            return 1
        if not (vault / links_rel).is_dir():
            _log(log, f"ERROR: missing {vault}/{links_rel}")
            notify("Links push failed", "Links/ folder missing", "critical")
            return 1

        _enable_proxy()

        git = ["git", "-C", str(vault)]
        _log(log, f"cd {vault}")
        _log(log, " ".join(git) + f" add {links_rel}")
        subprocess.run([*git, "add", links_rel], check=False, capture_output=True)
        hermes_note = vault / "_meta" / "Hermes" / "obsidian-links-capture.md"
        if hermes_note.exists():
            subprocess.run([*git, "add", str(hermes_note.relative_to(vault))], check=False, capture_output=True)

        staged = subprocess.run([*git, "diff", "--staged", "--quiet"], capture_output=True)
        if staged.returncode == 0:
            _log(log, "No Links/ changes to push")
            return 0

        count = subprocess.run(
            [*git, "diff", "--staged", "--name-only"], capture_output=True, text=True
        ).stdout.count("\n")
        commit_msg = f"links weekly: {_date()} ({count} files)"
        subprocess.run([*git, "commit", "-m", commit_msg], check=False, capture_output=True)
        push = subprocess.run([*git, "push", remote, branch], capture_output=True, text=True)
        if push.returncode != 0:
            _log(log, f"push failed: {push.stderr.strip()}")
            notify("Links push failed", push.stderr.strip()[-120:], "critical")
            return 1
        _log(log, f"Pushed Links/ to {remote}/{branch}")
        notify("Links pushed", f"{count} files → private vault")
        return 0
    finally:
        log.close()
        os.close(lock_fd)


def _log(log, line: str) -> None:
    log.write(line + "\n")
    log.flush()


def _now() -> str:
    from datetime import datetime

    return datetime.now().isoformat(timespec="seconds")


def _date() -> str:
    from datetime import date

    return date.today().isoformat()


def _enable_proxy() -> None:
    proxy_sh = Path.home() / ".config" / "omarchy" / "proxy.sh"
    if not proxy_sh.exists():
        return
    subprocess.run(
        ["bash", "-lc", f"source {proxy_sh} && proxy_on"],
        capture_output=True,
        timeout=10,
    )
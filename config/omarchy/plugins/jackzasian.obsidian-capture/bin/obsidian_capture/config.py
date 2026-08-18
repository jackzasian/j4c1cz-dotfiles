"""Path configuration for obsidian-capture.

Every location can be overridden with an environment variable so the tool
works against any Obsidian vault layout, not just the author's defaults.
"""

from __future__ import annotations

import os
from pathlib import Path


def _env_path(name: str, default: Path) -> Path:
    raw = os.environ.get(name)
    return Path(raw) if raw else default


def vault_dir() -> Path:
    return _env_path("OBSIDIAN_VAULT_DIR", Path.home() / "Obsidian" / "J4c1c")


def links_dir() -> Path:
    return _env_path("OBSIDIAN_LINKS_DIR", vault_dir() / "Links")


def inbox_dir() -> Path:
    return _env_path("OBSIDIAN_INBOX_DIR", vault_dir() / "Inbox")


def vault_name() -> str:
    return os.environ.get("OBSIDIAN_VAULT_NAME", "J4c1c")


def zen_root() -> Path:
    return _env_path("OBSIDIAN_ZEN_ROOT", Path.home() / ".config" / "zen")


def notes_env_files() -> list[Path]:
    """Env files loaded for the web note publisher (NOTES_TOKEN, Upstash, …)."""
    return [
        _env_path("J4C1CZ_REPO_ENV", Path.home() / "Developer" / "j4c1cz" / ".env.local"),
        _env_path("J4C1CZ_NOTES_ENV", Path.home() / ".config" / "j4c1cz" / "notes.env"),
    ]
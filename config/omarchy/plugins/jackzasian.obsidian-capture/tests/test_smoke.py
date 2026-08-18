"""End-to-end smoke tests against a throwaway vault (no network, no menus)."""

import os
from pathlib import Path

import pytest

from obsidian_capture import config, link, notes, recent, sync


@pytest.fixture
def vault(tmp_path, monkeypatch):
    vault = tmp_path / "vault"
    links = vault / "Links"
    inbox = vault / "Inbox"
    links.mkdir(parents=True)
    inbox.mkdir(parents=True)

    for name in ("links-cycling.md", "links-misc.md", "links-inbox.md"):
        (links / name).write_text("# Links\n\n## Captured\n\n## To Sort\n\n")
    monkeypatch.setenv("OBSIDIAN_VAULT_DIR", str(vault))
    monkeypatch.setenv("OBSIDIAN_LINKS_DIR", str(links))
    monkeypatch.setenv("OBSIDIAN_INBOX_DIR", str(inbox))
    monkeypatch.setenv("OBSIDIAN_VAULT_NAME", "TestVault")
    return vault


class Args:
    def __init__(self, **kw):
        self.__dict__.update(text=[], url=None, title=None, open=False, inbox=False, edit=False, topic=None)

    def __getattr__(self, name):
        return None


def test_link_append_and_recent(vault):
    args = Args()
    args.url = "https://example.com/test"
    args.topic = "misc"
    args.title = "Test Page"
    rc = link.run_link(args)
    assert rc == 0

    misc = (vault / "Links" / "links-misc.md").read_text()
    assert "- [Test Page](https://example.com/test)" in misc

    recent_txt = (vault / "Links" / "links-recent.md").read_text()
    assert "example.com/test" in recent_txt


def test_link_dedupe(vault):
    args = Args()
    args.url = "https://example.com/dup"
    args.topic = "misc"
    args.title = "Dup"
    assert link.run_link(args) == 0
    assert link.run_link(args) == 0  # second time reports "already saved"

    misc = (vault / "Links" / "links-misc.md").read_text()
    assert misc.count("https://example.com/dup") == 1


def test_note_writes_inbox(vault):
    args = Args()
    args.text = ["hello", "world"]
    args.title = "Hello World"
    rc = notes.run_note(args, dest="inbox")
    assert rc == 0

    created = list((vault / "Inbox").glob("*.md"))
    assert len(created) == 1
    body = created[0].read_text()
    assert "title: \"Hello World\"" in body
    assert "# Hello World" in body


def test_prepend_recent_keeps_cap(vault):
    for i in range(55):
        recent.prepend_recent("misc", f"Title {i}", f"https://example.com/x{i}")
    feed = (vault / "Links" / "links-recent.md").read_text()
    count = sum(1 for line in feed.splitlines() if line.startswith("- `"))
    assert count <= recent.RECENT_CAP


def test_zen_sync_missing_profile(vault, monkeypatch):
    monkeypatch.setenv("OBSIDIAN_ZEN_ROOT", str(vault / "no-zen"))
    rc = sync.run_sync()
    assert rc == 1


def test_menu_fragment_is_valid_jsonc():
    import json
    import re

    text = Path("menu/obsidian-menu.jsonc").read_text()
    text = re.sub(r"^\s*//.*$", "", text, flags=re.M)
    text = re.sub(r",\s*([}\]])", r"\1", text)
    data = json.loads(text)
    assert "obsidian.save-link" in data
    assert "obsidian.quick-note" in data
    assert data["obsidian.save-link"]["action"].endswith("obsidian-capture link")


def test_bindings_fragment_uses_own_home():
    text = Path("hypr/obsidian-capture.lua").read_text()
    assert "local home = os.getenv(\"HOME\")" in text
    assert text.count("o.bind(") >= 5
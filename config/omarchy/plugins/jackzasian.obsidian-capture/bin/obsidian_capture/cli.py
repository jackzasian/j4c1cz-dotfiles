"""Command-line entry point for obsidian-capture."""

from __future__ import annotations

import argparse
import os


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="obsidian-capture",
        description="Save links and quick notes into an Obsidian vault.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_link = sub.add_parser("link", help="Save a URL (clipboard/argv/prompt) to a Links topic file")
    p_link.add_argument("url", nargs="?", help="URL to save (else clipboard / menu prompt)")
    p_link.add_argument("--topic", choices=["cycling", "study", "tech", "projects", "misc", "inbox"], help="Skip the topic picker")
    p_link.add_argument("--title", help="Override the page title")
    p_link.set_defaults(handler=_run_link)

    p_note = sub.add_parser("note", help="Capture a short note into Obsidian Inbox")
    p_note.add_argument("text", nargs="*", help="Note text (else menu prompt / stdin)")
    p_note.add_argument("--title", "-t", help="Override the Inbox note title")
    p_note.add_argument("--open", "-o", action="store_true", help="Open the saved note in Obsidian")
    p_note.add_argument("--inbox", action="store_true", help="Open the Inbox in Obsidian instead of capturing")
    p_note.add_argument("--url", "-u", help="Optional link for site posts")
    p_note.add_argument("--edit", "-e", action="store_true", help="Legacy alias for the edit command")
    p_note.add_argument("--web", "-w", action="store_true", help="Legacy alias for the web command")
    p_note.add_argument("--dest", "-d", action="store_true", help="Legacy alias for the dest command")
    p_note.add_argument("--both", "-b", action="store_true", help="Save to Inbox and post to the site")
    p_note.set_defaults(handler=lambda a: _run_note_compat(a))

    p_edit = sub.add_parser("edit", help="Capture a multiline note (zenity editor) into Inbox")
    p_edit.add_argument("text", nargs="*", help="Initial content for the editor")
    p_edit.add_argument("--title", "-t", help="Override the Inbox note title")
    p_edit.add_argument("--open", "-o", action="store_true", help="Open the saved note in Obsidian")
    p_edit.set_defaults(handler=lambda a: _run_note(a, edit=True))

    p_web = sub.add_parser("web", help="Post a short note to j4c1cz.com/notes")
    p_web.add_argument("text", nargs="*", help="Note text (else menu prompt / stdin)")
    p_web.add_argument("--url", "-u", help="Optional link for the note")
    p_web.set_defaults(handler=lambda a: _run_note(a, dest="site"))

    p_dest = sub.add_parser("dest", help="Capture a note, then choose inbox / site / both")
    p_dest.add_argument("text", nargs="*", help="Note text (else menu prompt / stdin)")
    p_dest.add_argument("--title", "-t", help="Override the Inbox note title")
    p_dest.add_argument("--open", "-o", action="store_true", help="Open the saved note in Obsidian")
    p_dest.add_argument("--url", "-u", help="Optional link for site posts")
    p_dest.set_defaults(handler=lambda a: _run_dest(a))

    p_recent = sub.add_parser("recent", help="Open the recent-links feed in Obsidian")
    p_recent.set_defaults(handler=_run_recent)

    p_sync = sub.add_parser("sync", help="Sync new Zen Browser bookmarks into Links/links-inbox.md")
    p_sync.set_defaults(handler=_run_sync)

    p_push = sub.add_parser("push", help="Commit and push Links/ to the vault's git remote")
    p_push.set_defaults(handler=_run_push)

    return parser


def _run_link(args):
    from .link import run_link

    return run_link(args)


def _run_note(args, *, dest: str = "inbox", edit: bool = False):
    from .notes import run_note

    return run_note(args, dest=dest, edit=edit)


def _run_note_compat(args):
    if args.edit:
        return _run_note(args, edit=True)
    if args.web:
        return _run_note(args, dest="site")
    if args.dest:
        return _run_dest(args)
    if args.both:
        return _run_note(args, dest="both")
    return _run_note(args)


def _run_dest(args):
    from .notes import run_dest

    return run_dest(args)


def _run_recent(args):
    from .misc import open_recent

    return open_recent(args)


def _run_sync(args):
    from .sync import run_sync

    return run_sync(args)


def _run_push(args):
    from .misc import run_push

    return run_push(args)


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    if not hasattr(args, "handler"):
        parser.print_help()
        return 2
    return args.handler(args) or 0


if __name__ == "__main__":
    os.environ.setdefault("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    raise SystemExit(main())
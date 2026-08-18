#!/usr/bin/env python3
"""Merge the plugin's menu entries into ~/.config/omarchy/extensions/omarchy-menu.jsonc.

Usage: merge_menu.py <fragment.jsonc> <user-menu.jsonc>

Preserves any user-added entries; the plugin fragment wins per entry ID.
User comments are dropped (the file is rewritten as clean JSONC).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def parse_jsonc(text: str) -> dict:
    text = re.sub(r"^\s*//.*$", "", text, flags=re.M)
    text = re.sub(r",\s*([}\]])", r"\1", text)
    return json.loads(text)


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    fragment = parse_jsonc(Path(sys.argv[1]).read_text())
    user_path = Path(sys.argv[2])
    merged = parse_jsonc(user_path.read_text()) if user_path.exists() else {}
    merged.update(fragment)

    header = (
        "// Managed by omarchy-obsidian-capture.\n"
        "// Plugin entries are merged from the plugin's menu/obsidian-menu.jsonc;\n"
        "// user entries above are preserved.\n"
    )
    user_path.parent.mkdir(parents=True, exist_ok=True)
    user_path.write_text(header + json.dumps(merged, indent=2, ensure_ascii=False) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
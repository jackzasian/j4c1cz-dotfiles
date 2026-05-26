#!/usr/bin/env python3
"""Sync or regenerate Arch branding.

Default: copy arch-j4c1cz.txt -> about.txt, screensaver.txt (preserves hand edits).
Pass --generate to rebuild arch-j4c1cz.txt from the neofetch mask filled with j4c1cz.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

LETTERS = "j4c1cz"
BRANDING_DIR = Path(__file__).resolve().parent
OUTPUT = BRANDING_DIR / "arch-j4c1cz.txt"


def mask_from_neofetch() -> list[str]:
    raw = r"""
                   -`
                  .o+`
                 `/oo+`
                `/+oo+`
               /`+oo+`
              /`  +oo+`
             /`    +oo+`
            /`      +oo+`
           /`        +oo+`
          /`          +oo+`
         /`            +oo+`
        /`              +oo+`
       /`                +oo+`
      /`                  +oo+`
     /`                    +oo+`
    /`                      +oo+`
   /`                        +oo+`
  /`                          +oo+`
 /`                            +oo+`
/`                              +oo+`
""".strip("\n").splitlines()
    return raw


def fill_mask(lines: list[str]) -> list[str]:
    idx = 0
    out = []
    for line in lines:
        row = []
        for ch in line:
            if ch != " ":
                row.append(LETTERS[idx % len(LETTERS)])
                idx += 1
            else:
                row.append(" ")
        out.append("".join(row))
    return out


def sync_from_source() -> None:
    if not OUTPUT.is_file():
        print(f"Missing {OUTPUT}", file=sys.stderr)
        sys.exit(1)
    text = OUTPUT.read_text()
    for name in ("about.txt", "screensaver.txt"):
        (BRANDING_DIR / name).write_text(text)
    lines = text.count("\n")
    print(f"Synced {OUTPUT} ({lines} lines) -> about.txt, screensaver.txt")


def generate_mask() -> None:
    lines = fill_mask(mask_from_neofetch())
    text = "\n".join(lines) + "\n"
    OUTPUT.write_text(text)
    for name in ("about.txt", "screensaver.txt"):
        (BRANDING_DIR / name).write_text(text)
    print(f"Generated {OUTPUT} ({len(lines)} lines) and synced copies")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--generate",
        action="store_true",
        help="Regenerate arch-j4c1cz.txt from neofetch mask (overwrites hand edits)",
    )
    args = parser.parse_args()
    if args.generate:
        generate_mask()
    else:
        sync_from_source()


if __name__ == "__main__":
    main()

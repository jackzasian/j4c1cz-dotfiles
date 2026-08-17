#!/usr/bin/env python3
"""jackz addition 2026-08-17: there's no Docker on the Mac Mini (checked —
`command not found`), so this doesn't extend the container list. It's a
separate, much smaller check bolted onto the same widget per Jack's choice:
reachability + backup-volume disk space + the couple of services that
actually matter there (Syncthing, the vault-backup launchd job). One SSH
round trip, short timeout so an unreachable host degrades to an "offline"
state fast rather than hanging the widget's poll cycle.
"""

from __future__ import annotations

import json
import subprocess

HOST = "jacks-mac-mini"
USER = "j4c1cz"
VOLUMES = ["/Volumes/Encrypted", "/Volumes/Share1T"]

REMOTE_CMD = (
    "df -H " + " ".join(VOLUMES) + " 2>/dev/null | tail -n +2; "
    "echo ---; "
    "pgrep -q syncthing && echo syncthing:running || echo syncthing:stopped; "
    "launchctl list 2>/dev/null | grep -q com.j4c1cz.omarchy-vault-backup "
    "&& echo vault-backup:registered || echo vault-backup:missing"
)


def run_ssh() -> str:
    try:
        result = subprocess.run(
            [
                "ssh",
                "-o", "ConnectTimeout=3",
                "-o", "BatchMode=yes",
                "-o", "StrictHostKeyChecking=accept-new",
                f"{USER}@{HOST}",
                REMOTE_CMD,
            ],
            capture_output=True,
            text=True,
            timeout=6,
        )
        if result.returncode != 0:
            return ""
        return result.stdout
    except Exception:
        return ""


def parse_df_line(line: str) -> dict | None:
    # macOS `df -H` columns: Filesystem Size Used Avail Capacity iused ifree %iused Mounted-on
    parts = line.split()
    if len(parts) < 9:
        return None
    mount = parts[8]
    volume = mount.split("/")[-1] if "/" in mount else mount
    return {
        "volume": volume,
        "size": parts[1],
        "used": parts[2],
        "avail": parts[3],
        "capacityPct": parts[4].rstrip("%"),
    }


def main() -> int:
    raw = run_ssh()
    if not raw:
        print(json.dumps({"reachable": False}, separators=(",", ":")))
        return 0

    lines = raw.splitlines()
    try:
        sep = lines.index("---")
    except ValueError:
        print(json.dumps({"reachable": False}, separators=(",", ":")))
        return 0

    disks = []
    for line in lines[:sep]:
        parsed = parse_df_line(line)
        if parsed:
            disks.append(parsed)

    services = {}
    for line in lines[sep + 1:]:
        if ":" in line:
            name, state = line.split(":", 1)
            services[name.strip()] = state.strip() == "running" or state.strip() == "registered"

    result = {
        "reachable": True,
        "disks": disks,
        "services": {
            "syncthing": services.get("syncthing", False),
            "vaultBackup": services.get("vault-backup", False),
        },
    }
    print(json.dumps(result, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

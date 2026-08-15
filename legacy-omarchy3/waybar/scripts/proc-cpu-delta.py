#!/usr/bin/env python3
"""Instantaneous CPU% for a set of PIDs, via /proc delta since last call.

Unlike `ps -o pcpu` (a lifetime average that stays near-zero for
long-lived processes even while actively busy right now), this measures
CPU time consumed between this invocation and the last one for the same
state key.

Usage: proc-cpu-delta.py <state_key> <threshold_pct> <pid> [pid ...]
Prints "1" (busy) or "0" (idle) and exits 0.
"""
import json
import os
import sys
import time

STATE_DIR = os.path.expanduser("~/.cache/waybar-status")
os.makedirs(STATE_DIR, exist_ok=True)

CLK_TCK = os.sysconf("SC_CLK_TCK")


def read_proc_ticks(pid):
    # comm field is wrapped in parens and may contain spaces; find the
    # matching ')' and index from there rather than a naive split()
    try:
        with open(f"/proc/{pid}/stat", "r") as f:
            content = f.read()
        rparen = content.rindex(")")
        rest = content[rparen + 2 :].split()
        utime = int(rest[11])  # field 14 overall, index 11 after comm
        stime = int(rest[12])  # field 15 overall, index 12 after comm
        return utime + stime
    except (OSError, ValueError, IndexError):
        return 0


def main():
    if len(sys.argv) < 3:
        print("0")
        return
    state_key = sys.argv[1]
    threshold = float(sys.argv[2])
    pids = sys.argv[3:]

    total_ticks = sum(read_proc_ticks(p) for p in pids)
    now = time.time()

    state_file = os.path.join(STATE_DIR, f"cpu-delta-{state_key}.json")
    prev = {}
    if os.path.exists(state_file):
        try:
            with open(state_file) as f:
                prev = json.load(f)
        except (OSError, ValueError):
            prev = {}

    with open(state_file, "w") as f:
        json.dump({"ticks": total_ticks, "time": now}, f)

    if not pids or not prev:
        print("0")
        return

    dt = now - prev.get("time", now)
    dticks = total_ticks - prev.get("ticks", total_ticks)
    if dt <= 0.05 or dticks < 0:
        print("0")
        return

    pct = 100.0 * (dticks / CLK_TCK) / dt
    print("1" if pct >= threshold else "0")


if __name__ == "__main__":
    main()

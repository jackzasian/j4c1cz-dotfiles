# Bar port — verification checklist

Ported 2026-08-11 from `~/.config/waybar/config.jsonc` (+ 2 profiles) against the
`quattro` branch at `4.0.0.alpha`. **Not installed.** Validate against the real Quattro
`omarchy-shell` first.

## Offline checks already done

- `python3 -m json.tool shell.json` — pass
- All 12 surviving scripts copied unchanged from `~/.config/waybar/scripts/`
- No script contains `pkill -RTMIN+N waybar` (signal-refresh is handled in `shell.json`
  click handlers via `omarchy-shell -q shell reloadConfig`)

## Widget disposition — full table

### Replaced by built-in widgets (scripts dropped)

| Waybar module | Quattro widget | Script | Notes |
|---|---|---|---|
| `custom/update` | `omarchy.system-update` | --- | Same command (`omarchy-update-available`), native indicator |
| `custom/weather` | `omarchy.weather` | `weather-status.sh` (kept as reference) | Built-in uses same Omarchy location.conf |
| `custom/tailscale` | `omarchy.tailscale` | `tailscale-status.sh` (dropped) | |
| `custom/token-usage` | `omarchy.agents` | `token-usage.sh` (dropped) | Built-in shows rate-limit meters with pace, today, last week, all-time |
| `custom/usage-limits` | `omarchy.agents` | `usage-limits.sh` (dropped) | **Alerts with notification sounds are lost** — `omarchy.agents` is purely visual |
| `custom/screenrecording-indicator` | `omarchy.indicators` (ScreenRecording) | indicator script (dropped) | |
| `custom/idle-indicator` | `omarchy.indicators` (StayAwake) | indicator script (dropped) | |
| `custom/notification-silencing-indicator` | `omarchy.indicators` (Dnd) | indicator script (dropped) | |
| `backlight` | `omarchy.monitor` | --- | |
| `group/audio` (output+input) | `omarchy.audio` + `omarchy.microphone` | --- | Built-in audio includes volume slider, output picker, per-app mixer |
| `network` | `omarchy.network` | --- | |
| `bluetooth` | `omarchy.bluetooth` | --- | |
| `tray` | `omarchy.tray` | --- | |
| `battery`, `cpu`, `memory` | `omarchy.power` | --- | Battery + power profile + system stats in one panel |
| `hyprland/workspaces` | `omarchy.workspaces` | --- | |
| `custom/omarchy` | `omarchy.menu` | --- | **Right-click terminal lost** (see Known gaps below) |

### Ported as `type: "command"` widgets (scripts kept)

| Widget id | Script | Patched? | Notes |
|---|---|---|---|
| `ai-claude-code` | `ai-tool-status.sh cc` | No | Process activity + CPU-busy detection |
| `ai-cursor` | `ai-tool-status.sh cu` | No | |
| `ai-claude-desktop` | `ai-tool-status.sh cd` | No | Click handlers preserved |
| `ai-opencode` | `ai-tool-status.sh oc` | No | |
| `tasknotes` | `tasknotes-upcoming.py` | No | Click handler patched in shell.json |
| `voxtype` | `omarchy-voxtype-status` (CLI) | No | No script file, uses system command |
| `hermes-gateway` | `agents-status.sh` | No | Renamed from `custom/agents` to avoid collision with `omarchy.agents` |
| `clash-geo` | `clash-geo-status.sh` | No | Click handlers patched in shell.json |
| `syncthing` | `syncthing-status.sh` | No | |
| `kdeconnect` | `kdeconnect-status.sh` | No | |

### Scripts copied but NOT wired in shell.json (kept for reference)

| Script | Reason |
|---|---|
| `spotify-status.sh` | `omarchy.media` is the built-in MPRIS widget — not placed in this port; spotify button was in center but Quattro's center is full |
| `weather-status.sh` | Replaced by `omarchy.weather` built-in |
| `ticktick-upcoming.py` | Was in scripts/ directory but never referenced by any waybar config |
| `workspace-strip.sh` | Was for an older pill-bar layout, not in any current config |

### Waybar-specific scripts NOT copied (5 dropped)

| Script | Reason |
|---|---|
| `waybar-apply-profile.sh` | Waybar-only profile switching |
| `waybar-monitor-watch.sh` | Waybar-only; replaced by new `profile-switch.md` design |
| `waybar-power-apply.sh` | Waybar interval scaling |
| `waybar-power-watch.sh` | Waybar power event watcher |
| `waybar-restart.sh` | Waybar process management |

## Install

```bash
P=~/dotfiles/quattro-prep/shell
T=~/.config/omarchy

# 1. Scripts first (widgets reference them)
mkdir -p "$T/bar/scripts"
cp "$P"/scripts/* "$T/bar/scripts/"
chmod +x "$T/bar/scripts/"*.sh "$T/bar/scripts/"*.py

# 2. Bar config
cp "$P/shell.json" "$T/shell.json"

# 3. Reload the running shell (or just reboot)
omarchy-shell -q shell reloadConfig 2>/dev/null || true
```

Keep the old waybar configs until this is proven.

## Must verify on the real thing

Ordered by likelihood of biting.

1. **`omarchy-shell shell reloadConfig` as signal-refresh replacement.** The
   shell.json click handlers for `tasknotes`, `clash-geo`, and `weather` use
   `omarchy-shell -q shell reloadConfig` to force command widgets to re-execute.
   Confirm this actually causes inline `type:"command"` widgets to re-run (the
   PluginRegistry schema doesn't explicitly document this behavior — it was
   inferred from the docs saying `reloadConfig` reloads shell.json).
   → Click tasknotes, watch for immediate refresh.

2. **`omarchy.menu` right-click.** The waybar `custom/omarchy` had
   `on-click-right=xdg-terminal-exec`. The built-in `omarchy.menu` widget
   likely doesn't support a custom right-click action. If you miss it, add a
   zero-width inline `type:"command"` widget next to `omarchy.menu` with just
   `onClickRight: "xdg-terminal-exec"`. → Right-click the Omarchy logo.

3. **`omarchy.agents` vs the dropped scripts.** `token-usage.sh` computed
   API-equivalent cost vs Pro plan ($20/mo), and `usage-limits.sh` sounded an
   alert + notification when a subscription crossed the threshold. The built-in
   `omarchy.agents` shows rate-limit meters but may not alert on thresholds.
   → Click the agents widget, compare to the old tooltip.

4. **`omarchy.indicators` items filter.** The widget is configured with
   `"items": ["ScreenRecording", "Dnd"]`. Confirm both indicators appear and
   toggle correctly. The idle indicator (StayAwake) is not included — add it
   back if you want the idle-override indicator.
   → Toggle screen recording, toggle DND.

5. **`omarchy.clock` format strings.** Mapped waybar strftime → Qt/QML format:
   `{:L%A %H:%M}` → `"dddd HH:mm"`, `{:L%d %B W%V %Y}` → `"d MMMM 'W'ww yyyy"`.
   Qt's `dddd` is locale-aware (same as waybar's `%A` with `:L`). If the day
   doesn't localize to Chinese or you get `Monday` instead of `星期一`, the
   mapping is wrong. → Check clock display in both formats.

6. **`omarchy.power` coverage.** This replaces `battery`, `cpu`, and `memory`
   from the old bar. The panel popup should show system stats; the bar icon
   likely shows battery. Confirm at-a-glance CPU/memory numbers aren't missed.
   → Click the power widget to open the panel.

7. **`omarchy.audio` + `omarchy.microphone` separation.** The old `group/audio`
   packed output + input together. They're now separate widgets. Confirm both
   appear and the bar doesn't overflow on 1920px.
   → Check bar layout on the Studio Display.

8. **Click handlers on `type:"command"` widgets.** The quattro branch docs
   document `onClick` / `onClickRight` on command widgets, but the exact event
   mapping (left-click vs right-click vs middle-click) needs live confirmation.
   → Right-click clash-geo, confirm cache clears and widget refreshes.

9. **`omarchy.media` / Spotify.** The built-in MPRIS widget is not in
   `shell.json` because the center layout is already full. If you want Spotify
   controls back in the bar, either move `omarchy.media` to right or trim the
   AI tool chips in laptop mode. `spotify-status.sh` is kept as a ready-to-use
   command widget if you prefer the old behavior.
   → Decide during live testing.

10. **`ai-tool-status.sh` CPU delta tracking.** This script writes state files
    to `~/.cache/waybar-status/`. The path is waybar-specific but functionally
    correct — it's just a data directory, not a waybar API. No change needed,
    but worth noting if you ever clean up waybar leftovers.
    → Confirm tool chips show process activity correctly.

11. **`proc-cpu-delta.py` from `~/.config/waybar/scripts/` path.** This script
    is called from `ai-tool-status.sh` using a hardcoded path to
    `~/.config/waybar/scripts/proc-cpu-delta.py`. That path won't exist after
    the migration. **Before installing**, edit `ai-tool-status.sh` to point at
    the new location `~/.config/omarchy/bar/scripts/proc-cpu-delta.py`.
    → Edit line ~52 of ai-tool-status.sh.

12. **Power helper path.** `clash-geo-status.sh` and `weather-status.sh` source
    `power.sh` from `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` —
    this resolves dynamically, so as long as `power.sh` is in the same
    `~/.config/omarchy/bar/scripts/` directory, it works. ✓

## Known gaps

- **Signal-refresh is heavy.** `omarchy-shell shell reloadConfig` reloads the
  entire shell.json, re-executing every command widget, not just the one that
  was clicked. This works but may cause a visual flicker. A lighter per-widget
  refresh IPC method may exist in the stable release — check back.

- **Right-click terminal on Omarchy menu.** `custom/omarchy` had
  `on-click-right=xdg-terminal-exec`. The built-in `omarchy.menu` doesn't
  support this. Workaround: add a zero-width command widget next to it in left
  section.

- **CPU/memory at-a-glance numbers.** The old bar showed `{usage}% <icon>` for
  CPU and `{percentage}% <icon>` for memory. These are now hidden inside
  `omarchy.power`'s panel. If you miss them, write simple exec widgets polling
  `/proc/stat` and `/proc/meminfo`.

- **Spotify media widget not in bar.** `omarchy.media` is omitted from
  `shell.json` because the center layout was already full and mixing MPRIS with
  AI-tool chips felt wrong. Add it yourself (`omarchy bar put omarchy.media`)
  if you disagree.

- **Usage-limit alerts lost.** `usage-limits.sh` triggered notify-send + paplay
  when subscriptions crossed the alert threshold. `omarchy.agents` is visual-only.
  Re-implement as a separate script if you relied on these.

- **Waybar group drawers (laptop profile).** `group/apps` and `group/more` used
  animated drawers to hide/show groups of widgets on the laptop screen. Quattro
  has no drawer concept. The laptop profile layout simply uses fewer widgets.
  Profile switching is a separate deliverable (see `profile-switch.md`).

- **Battery-aware interval scaling.** `waybar-power-apply.sh` doubled poll
  intervals on battery. Quattro has no equivalent — all intervals are static
  in `shell.json`. Could be reimplemented by calling `omarchy bar set <id>
  interval <n>` on AC change, but that requires the widget to support runtime
  `setBarWidget` (built-ins do; inline command widgets may not).

- **Alpha branch caveat.** This was written against `4.0.0.alpha`. The stable
  release may shift the schema, command names, or IPC surface. Every click
  handler, format string, and widget id needs re-verification.

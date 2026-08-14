# Handoff: finish the Omarchy Quattro bar port

## Context

thinkpad1 (Arch/Omarchy 3.8.4, Hyprland 0.56.2) is waiting on Omarchy Quattro (4.x) to
release on the stable channel — expected mid-August 2026, not yet live as of
2026-08-11. Full plan and rationale: `~/Obsidian/J4c1c/_meta/Hermes/omarchy-migration-runbook.md`
(read this first, especially §0 the release gate, §1 what Quattro changes, §3 blast
radius, and the day-of card at the top).

Everything produced for this migration is **staged, not live** — draft files that get
installed deliberately after the upgrade and after validating against the real
Quattro (this was all written against the `quattro` branch at `4.0.0.alpha`, which may
drift before stable ships). Do not touch `~/.config/hypr/`, `~/.config/waybar/`, or
any live config. Everything you produce goes under `~/dotfiles/quattro-prep/`.

## Already done (don't redo)

- **Backups**: full pre-Quattro snapshot (504 files, sha256-verified) on two separate
  physical Mac Mini disks. Not your concern.
- **Proxy/safety scaffolding** (`~/dotfiles/quattro-prep/{hooks,uwsm-env.d,local-bin,etc-sudoers.d,restore}/`,
  see its `README.md`): a `pre-refresh-pacman.d` hook that protects the Clash
  `XferCommand`, a PATH-ordering fix so `~/.local/bin` shims beat `/usr/bin`, an
  `omarchy-pkg-aur-accessible` shim, a sudoers `env_keep` drop-in, and
  chromium/docker restore scripts.
- **Hyprland Lua port** (`~/dotfiles/quattro-prep/hypr-lua/`, see its `VERIFY.md`): all
  12 `~/.config/hypr/*.conf` files (52 bindings, monitors, workspace-monitor map,
  gestures, plugins, autostart) ported to the 6 Quattro `.lua` entry points. Dry-run
  verified against Quattro's real `default/hypr/helpers.lua` with a stubbed `hl` API —
  syntax-checked with `luac -p`, executed, bindings reconciled 52→49+3 deliberate
  drops, zero silent losses. Use this as the quality bar and the pattern to copy: a
  `luac`/exec dry run, then a companion `VERIFY.md` listing everything that needs
  hands-on confirmation on the real machine.

## Your task: the bar

Translate `~/.config/waybar/config.jsonc` (+ `config.laptop.jsonc` /
`config.docked.jsonc` profiles) into a Quattro `~/.config/omarchy/shell.json`, and
carry forward the 21 scripts in `~/.config/waybar/scripts/`. Output to
`~/dotfiles/quattro-prep/shell/`.

### What Quattro's bar actually is

Quickshell-based, one process (`omarchy-shell`), configured by
`~/.config/omarchy/shell.json`. Docs:
`docs/omarchy-shell.md` in the `quattro` branch (fetch it — see "Getting the source"
below), authoritative schema at `shell/services/PluginRegistry.qml`.

Key facts already confirmed by reading the branch:

- Bar layout: `shell.json` → `{"bar": {"position": "top", "layout": {"left": [...], "center": [...], "right": [...]}}}`,
  each entry `{"id": "..."}` referencing a built-in plugin id, or an inline custom
  module.
- **Generic script widget exists** — this is the waybar `custom/exec` equivalent:
  ```json
  { "id": "vpn", "type": "command", "exec": "~/.config/omarchy/bar/scripts/vpn-status",
    "interval": 5, "tooltip": "VPN", "onClick": "nm-connection-editor" }
  ```
  Output is **plain text or Waybar-style JSON** (`{"text":..., "tooltip":..., "class":...}`)
  — your scripts' existing output format should work unchanged.
- Custom QML widget form also exists (`{"id":"gpu","type":"qml"}` +
  `~/.config/omarchy/bar/modules/gpu.qml`) if a command widget isn't expressive enough.
- Built-in widget ids confirmed present in the branch (there may be more; re-check):
  `omarchy.agents`, `audio`, `background`, `bar`, `battery`, `bluetooth`, `clipboard`,
  `clock`, `dev-gallery`, `disk-speedtest`, `dropbox`, `emojis`, `idle`, `image-picker`,
  `lock`, `media`, `menu`, `monitor`, `network`, `nightlight`, `notifications`, `osd`,
  `polkit`, `power`, `reminders`, `speedtest`, `tailscale`, `weather`, `wifiqr`. The
  shipped default `shell.json` also references `omarchy.workspaces`,
  `omarchy.indicators`, `omarchy.keyboard-layout`, `omarchy.system-update`,
  `omarchy.tray` — those didn't turn up in a `manifest.json` grep, so confirm whether
  they're truly built-in (baked into `omarchy.bar` itself) or something else.
- Shell plugins are git repos (`omarchy plugin add <url>`, cloned to
  `~/.config/omarchy/plugins/<id>/`), and built-ins can be cloned/edited via
  `omarchy plugin` (Setup → Plugins). That's the sanctioned durable-customization
  path — prefer it over touching package-owned files.

### Your machine's current modules — already extracted, use this, don't re-derive

Three waybar configs, same `custom/*` module set, different `modules-left/center/right`
arrangement:

```
config.jsonc (docked, current default) / config.docked.jsonc (identical):
  left:   custom/omarchy, hyprland/workspaces
  center: clock, custom/spotify, custom/claude-code, custom/cursor,
          custom/claude-desktop, custom/opencode, custom/token-usage,
          custom/usage-limits, custom/tasknotes, custom/weather, custom/update,
          custom/voxtype, custom/screenrecording-indicator, custom/idle-indicator,
          custom/notification-silencing-indicator
  right:  tray, custom/agents, custom/clash-geo, custom/tailscale, custom/syncthing,
          custom/kdeconnect, bluetooth, backlight, group/audio, network, memory,
          cpu, battery

config.laptop.jsonc (sparse):
  left:   custom/omarchy, group/apps
  center: clock, custom/spotify, custom/token-usage, custom/usage-limits,
          custom/tasknotes, custom/weather, custom/update, custom/voxtype,
          custom/screenrecording-indicator, custom/idle-indicator,
          custom/notification-silencing-indicator
  right:  group/more, custom/tailscale, group/audio, battery
```

`group/apps`, `group/more`, `group/audio` are waybar's native grouping — check
`config.laptop.jsonc` for what's nested inside each before assuming they're single
widgets.

Custom module definitions (`exec` / `interval` / `on-click` / `signal` / etc, already
extracted from `config.jsonc`):

```
custom/omarchy:        on-click=uwsm-app -- omarchy-menu, on-click-right=xdg-terminal-exec
custom/spotify:         scripts/spotify-status.sh, interval=2, json, on-click=playerctl -p spotify play-pause, on-click-right=uwsm-app -- spotify
custom/claude-code:     scripts/ai-tool-status.sh cc, interval=2, json
custom/cursor:          scripts/ai-tool-status.sh cu, interval=2, json
custom/claude-desktop:  scripts/ai-tool-status.sh cd, interval=2, json, on-click=omarchy-launch-or-focus com.anthropic.Claude "uwsm-app -- ~/.local/bin/claude-launch", on-click-right=pkill+relaunch
custom/opencode:        scripts/ai-tool-status.sh oc, interval=2, json
custom/token-usage:     scripts/token-usage.sh, interval=60, json
custom/usage-limits:    scripts/usage-limits.sh, interval=300, json
custom/tasknotes:       scripts/tasknotes-upcoming.py, interval=20, signal=11, json, on-click=pkill -RTMIN+11 waybar; obsidian, on-click-right=force-refresh + pkill -RTMIN+11
custom/agents:          scripts/agents-status.sh, interval=10, json
custom/clash-geo:       scripts/clash-geo-status.sh, interval=60, signal=12, json, on-click=clash-verge, on-click-right=clear cache + pkill -RTMIN+12
custom/tailscale:       scripts/tailscale-status.sh, interval=15, json
custom/syncthing:       scripts/syncthing-status.sh, interval=15, json, on-click=xdg-open http://127.0.0.1:8384
custom/kdeconnect:      scripts/kdeconnect-status.sh, interval=5, json, on-click=uwsm-app -- kdeconnect-app
custom/update:          exec=omarchy-update-available, signal=7, interval=21600, on-click=omarchy-launch-floating-terminal-with-presentation omarchy-update
custom/weather:         scripts/weather-status.sh, interval=600, signal=13, json, on-click=notify-send weather
custom/screenrecording-indicator: $OMARCHY_PATH/default/waybar/indicators/screen-recording.sh, signal=8, json, on-click=omarchy-capture-screenrecording
custom/idle-indicator:  $OMARCHY_PATH/default/waybar/indicators/idle.sh, signal=9, json, on-click=omarchy-toggle-idle
custom/notification-silencing-indicator: $OMARCHY_PATH/default/waybar/indicators/notification-silencing.sh, signal=10, json, on-click=omarchy-toggle-notification-silencing
custom/voxtype:         exec=omarchy-voxtype-status, json, on-click=omarchy-voxtype-model, on-click-right=omarchy-voxtype-config
```

Scripts directory (`~/.config/waybar/scripts/`, 21 files — port unchanged unless a
built-in widget makes one redundant): `agents-status.sh`, `ai-tool-status.sh`,
`clash-geo-status.sh`, `kdeconnect-status.sh`, `power.sh`, `proc-cpu-delta.py`,
`spotify-status.sh`, `syncthing-status.sh`, `tailscale-status.sh`,
`tasknotes-upcoming.py`, `ticktick-upcoming.py`, `token-usage.sh`,
`usage-limits.sh`, `waybar-apply-profile.sh`, `waybar-monitor-watch.sh`,
`waybar-power-apply.sh`, `waybar-power-watch.sh`, `waybar-restart.sh`,
`weather-status.sh`, `weather-status.sh.bak.1785969015` (ignore, it's a backup),
`workspace-strip.sh`.

### What you still need to figure out (I didn't get to these before handoff)

1. **The three "indicator" scripts source `$OMARCHY_PATH/default/waybar/indicators/*.sh`**
   — that's Omarchy's own waybar integration, which no longer exists once waybar is
   retired. Check whether `omarchy.idle`, `omarchy.notifications`, and a
   screen-recording equivalent are now just built-in widgets that replace these
   outright (very likely) rather than something to port.
2. **Signal-based refresh has no obvious equivalent.** Waybar modules use
   `pkill -RTMIN+N waybar` to force an immediate re-poll (see `custom/tasknotes`,
   `custom/clash-geo`, `custom/weather`, and the three indicators, all keyed off
   `signal=N`). Quickshell is one long-running process with an IPC surface
   (`omarchy-shell-ipc`, mentioned in `docs/omarchy-shell.md` — "IPC is the canonical
   way for CLIs to talk to a running shell"). Find the equivalent — check
   `bin/omarchy-shell-ipc` and `bin/omarchy-bar` in the branch tree — and rewrite the
   `on-click`/`on-click-right` handlers in `tasknotes-upcoming.py`,
   `clash-geo-status.sh`, `weather-status.sh` accordingly. This affects real user
   workflows (clicking tasknotes to force-refresh before opening Obsidian), so don't
   skip it.
3. **Which built-ins genuinely replace a script vs. which don't.** Before porting each
   script as a `type:"command"` widget, check whether `omarchy.tailscale`,
   `omarchy.media` (vs `spotify-status.sh`), `omarchy.weather`, `omarchy.agents`,
   `omarchy.monitor` (vs `proc-cpu-delta.py`), `omarchy.battery`, `omarchy.network`,
   `omarchy.bluetooth`, `omarchy.clipboard` already do the job. Read each plugin's
   `manifest.json` + QML in `shell/` to know what it actually shows before deciding to
   keep or drop the custom script. Document the decision either way — don't silently
   drop a script's functionality.
4. **Profile switching (laptop vs docked) has no home in `shell.json`.** There is no
   per-monitor or profile concept in the schema as read so far. You'll need to design
   something: most likely a script that rewrites `shell.json`'s `bar.layout` and
   reloads the shell (check for a `omarchy shell reload` or IPC call), triggered the
   same way `waybar-monitor-watch.sh` currently is (Hyprland `monitoradded`/
   `monitorremoved` events via `hyprctl`). This is genuinely new code, not a
   translation — say so explicitly in your output rather than pretending it's solved.
5. **`group/apps`, `group/more`, `group/audio`** — read what's nested in each
   (`config.laptop.jsonc` has the fullest version) before flattening them into
   `shell.json`'s layout arrays.

### Getting the source

The `quattro` branch tree isn't guaranteed to still be cached on this machine. Refetch it:

```bash
cd /tmp && rm -rf omarchy-quattro && \
curl -fsSL https://codeload.github.com/basecamp/omarchy/tar.gz/refs/heads/quattro -o q.tar.gz && \
tar xzf q.tar.gz && mv omarchy-quattro-quattro omarchy-quattro 2>/dev/null || true
```
(Tarball extracts to `omarchy-quattro-quattro/` — check and rename, or just use
whatever directory name it lands as.) Read `docs/omarchy-shell.md` in full, and
`shell/services/PluginRegistry.qml` for the authoritative schema. Also check
`shell/` for individual plugin `manifest.json` + QML files to see what each built-in
widget actually renders — don't guess from the id name alone.

**Caveat to carry forward in your own output**: this is the `4.0.0.alpha` branch tree,
not the stable release. Say so in whatever you write, the same way the existing
`hypr-lua/VERIFY.md` and `quattro-prep/README.md` do.

### Deliverables (match the quality bar already set)

1. `~/dotfiles/quattro-prep/shell/shell.json` — the translated bar config.
2. `~/dotfiles/quattro-prep/shell/scripts/` — copies of the 21 scripts, patched only
   where the signal-refresh mechanism (#2 above) requires it. Note per-script whether
   it was kept as-is, patched, or dropped as redundant (#3 above), and why.
3. `~/dotfiles/quattro-prep/shell/profile-switch.md` (or a script, if you get far
   enough to write one) — your design for laptop/docked switching, explicitly marked
   as new code rather than a port.
4. `~/dotfiles/quattro-prep/shell/VERIFY.md` — same shape as `hypr-lua/VERIFY.md`:
   what was checked offline (JSON validity at minimum; a real dry-run isn't possible
   without a running Quickshell, say so), and a numbered list of what needs hands-on
   confirmation after the real upgrade, ordered by likelihood of biting.
5. Update `~/dotfiles/quattro-prep/README.md`'s file table to include the new `shell/`
   entry, matching its existing style.

Do **not** install anything live, do **not** touch `~/.config/waybar` or
`~/.config/omarchy/shell.json` (it doesn't exist yet since Quattro isn't installed),
and do **not** run `omarchy plugin add` or anything network-mutating against this
machine's real state.

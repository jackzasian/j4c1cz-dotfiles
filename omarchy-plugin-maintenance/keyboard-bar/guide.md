---
tags: [omarchy, workflow, keyboard]
created: 2026-10-22
updated: 2026-10-22
---

# Omarchy keyboard bar guide

The bar keeps the things you check at a glance. Everything else opens from **Desktop Tools**, with its settings and background services retained.

> Applied 2026-10-22. Panel opening was verified on both screens, and shortcuts are registered. Use the physical keyboard: synthetic modifier/text input did not reach the intended menu, so the complete physical shortcut flow was not verified automatically.

## Start here

Press **Super+Ctrl+M** to open the Desktop Tools submenu in OmaCast. Type a tool name, use **↑/↓** to select it and **Enter** to open it. For example, search `backup`, `plugins`, `phone` or `screen time`.

You can also click the **Tools button** at the left of the bar. In your usual **Super+Space** OmaCast launcher, search `Desktop Tools` or the tool's name. The same menu entries are available there.

**Super** is the Windows/logo key. Your physical **Caps Lock sends Ctrl** because this machine swaps Caps Lock and Ctrl. You can use Caps Lock wherever this guide says Ctrl.

## What stays visible

| Part of bar | What it contains |
| --- | --- |
| Left | Tools button and workspaces |
| Center | Date/time calendar and Today Tasks; indicators, keyboard layout and update badge when applicable |
| Right | System tray, Notification Center, network, audio and battery/power |

Weather, media, Bluetooth, display tools, sync, phone, usage and maintenance panels are hidden from the bar. They remain installed and open through Desktop Tools. Some apps can still put their own icons in the system tray.

## Keyboard controls

| Shortcut | Use |
| --- | --- |
| **Super+Ctrl+M** | Desktop Tools |
| **Super+Space** | OmaCast; search Desktop Tools or a plugin name |
| **Super+Ctrl+A** | Audio |
| **Super+Ctrl+W** | Network |
| **Super+Ctrl+B** | Bluetooth |
| **Super+Ctrl+D** | Display controls |
| **Super+Ctrl+P** | Power and battery |
| **Super+Ctrl+Alt+D** | Calendar dates and events |
| **Super+Shift+Space** | Show or hide the whole bar |
| **Super+K** | Shortcut reference |
| **Super+Shift+T** | Open/focus Obsidian for tasks |

Your **Super+Ctrl+1–4** screenshot bindings are preserved: area, OCR, fullscreen and window. They do not select numbered bar panels.

In the **Desktop Tools submenu in OmaCast**, type to filter, use **↑/↓** to select, and **Enter** to open. With an empty search, **Backspace** goes back. **Esc** clears the query, then backs out of the submenu, then closes the launcher. Letters such as h/j/k/l enter search text.

In a **bar popup**, **Tab / Shift+Tab** switches between available panels in the same visible bar region when the panel supports the standard bar controls. Use its displayed keyboard hints for controls inside the popup; **Esc** closes or backs out. Hidden tools open from Desktop Tools and are skipped by visible-bar panel switching. In **Activity Monitor**, Esc first collapses the expanded view, then closes. In **Media**, Esc closes; Space/Enter toggles playback and Left/Right selects the previous/next track. These media keys are implemented in the panel; playback actions were not invoked during verification.

## Which tool to open

| Need | Desktop Tools entry | What to use it for |
| --- | --- | --- |
| Keep things working | Plugins | Review installed plugins and check available updates |
| Keep things working | Backup History | Check backup runs and failures; opening it does not start a backup |
| Keep things working | Monitor Layouts | Manage display arrangement and saved layouts |
| Keep things working | Display Controls | Brightness and display controls |
| Keep things working | Proxy | Check RelayPilot and its existing controls |
| Understand the machine | Activity Monitor | CPU, memory and processes |
| Understand the machine | Screen Time | Local application usage and trends |
| Understand the machine | Agent Usage | Existing coding-agent usage panel |
| Understand the machine | Docker | Existing container monitoring |
| Connect devices | Syncthing | Check vault/file sync and connected devices |
| Connect devices | Phone | Existing KDE Connect phone controls |
| Connect devices | Bluetooth | Connections and pairing |
| Connect devices | Tailscale | Existing private-network connections and controls |
| Listen or watch | Bluetooth Codec | Audio codec/profile for a connected Bluetooth audio device |
| Listen or watch | Speaker EQ | Existing speaker EQ profiles |
| Listen or watch | Media | Playback controls |
| Plan and capture | Calendar | Date grid and calendar events |
| Plan and capture | Today Tasks | Read the canonical Today view from Obsidian |
| Plan and capture | Quick Note | Capture a note into Obsidian |
| Look things up | Weather | Weather details |
| Look things up | GitHub | Existing GitHub panel |
| Look things up | Search | Secondary Keystroke search palette |
| Help | Keyboard Bar Guide | Open this note |
| Help | Show / Hide Bar | Toggle the whole top bar |

**TaskNotes in the bar is read-only.** Create, edit, complete and manage recurring tasks in native Obsidian so the existing TaskNotes and device-sync workflow remains authoritative. The calendar reads the existing feed. Writable HEY/Google backends and the unused quick-add overlay are disabled, so the named Calendar command opens the date/event panel. Duplicate reminders remain off.

## Technical appendix: bring an icon back

Settings live in `~/.config/omarchy/shell.json`. Hidden widgets retain their layout entries so their popups can still load. Set the selected entry's **`"menuOnly": false`** to restore its icon. The file hot-reloads when saved. Keep the other settings on that entry.

Monitor Layouts uses its existing **`"showBarIcon": true`** setting instead. The Tools button uses the stock command module configured inline in `shell.json`; the stock bar stays in use. Both it and Super+Ctrl+M run `~/.local/bin/oma-cast run omarchy:desktop-tools`. Super+Space still opens the normal OmaCast root launcher. Stock weather, Bluetooth, display, Tailscale and media use supported user clones with IDs `jackz.weather`, `jackz.bluetooth`, `jackz.monitor`, `jackz.tailscale` and `jackz.media`. Commands using their original Omarchy IDs resolve the enabled clones.

These visibility changes are local customizations. When updating a plugin, review its visibility patch; an upstream update can replace a locally patched widget. Review OmaCal’s local manifest patch too: its unused quick-add overlay is removed so the named Calendar route opens the calendar panel for the read-only feed.

## Technical appendix: restore the previous layout

The snapshot from just before this simplification is:

```text
~/.local/state/omarchy-bar-simplify/20261022-224552/
```

To restore only the previous bar configuration, first preserve the current one, then copy the snapshot:

```bash
cp ~/.config/omarchy/shell.json ~/.config/omarchy/shell.json.before-layout-restore
cp ~/.local/state/omarchy-bar-simplify/20261022-224552/.config/omarchy/shell.json ~/.config/omarchy/shell.json
```

This restores all shell settings from that snapshot, so compare the files first if you have made newer changes. It leaves the new keyboard binding and Desktop Tools menu in place. Local visibility patches default to showing icons when `menuOnly` is absent. The snapshot also contains the original bindings, menu extension and widget files for selective recovery; avoid replacing unrelated newer work.

Related: [[omarchy-customizations]], [[omarchy-shortcuts-and-tooling]], [[2026-10-22-omarchy-plugin-upgrade]].

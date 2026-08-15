# Legacy Omarchy 3 configs

Historical reference only — retired by the Omarchy Quattro (4.0.0) migration on
2026-08-15. `waybar`, `walker`, `mako`, `swayosd` are all replaced by the
Quickshell-based `omarchy-shell` (see `~/dotfiles/quattro-prep/shell/` and the
live `~/.config/omarchy/shell.json`). Moved out of `config/` so
`sync-from-system.sh` stops treating them as live (their `~/.config/*` sources
no longer exist — the upgrade renamed them to `*.omarchy-upgrade-to-quattro.*.bak`
on the live machine).

Kept for: waybar `custom/*` module definitions and script-porting reference,
mako/swayosd config values in case a future built-in shell widget needs the
same tuning re-applied.

See `~/Obsidian/J4c1c/_meta/Hermes/omarchy-migration-runbook.md` §3.1 and
`quattro-bar-and-desktop-customization.md` for what replaced each of these.

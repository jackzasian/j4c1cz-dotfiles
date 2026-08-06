# j4c1cz dotfiles (Omarchy / Hyprland)

My Omarchy / Hyprland desktop configuration for Arch Linux.

## Security

This repo is public but scrubbed: exact home coordinates, street address, and
machine identifiers (machine-id, disk PARTUUIDs) are removed. `location.conf`
files are kept at city level only, and `sync-from-system.sh` preserves those
redactions on every sync.

## Layout

Files under `config/` mirror `~/.config/`. Shell files are under `home/`.

## Restore (manual)

```bash
# Example: restore Hyprland config
cp -r config/hypr/* ~/.config/hypr/

# Or symlink a directory
ln -sfn ~/dotfiles/config/omarchy ~/.config/omarchy
```

## Waybar taskbar dedup (optional)

Stock Waybar shows duplicate icons for each window. To group same-app windows:

```bash
omarchy pkg add base-devel meson ninja gobject-introspection
./scripts/install-waybar-taskbar-dedup.sh
```

Patch: `patches/waybar-0.15.0-taskbar-dedup.patch`. See `04 Tech/Hermes/waybar-customization.md`.

## Power profile auto-switch (AC/battery)

`config/systemd/user/power-profile-policy.{service,timer}` + `home/.local/bin/power-profile-policy`
switch `power-profiles-daemon` automatically: `balanced` on AC, `power-saver` on
battery. Checked every 2 minutes, idempotent (only calls `powerprofilesctl set`
when the profile actually needs to change). No `sudo` required.

```bash
# Install
cp home/.local/bin/power-profile-policy ~/.local/bin/
cp config/systemd/user/power-profile-policy.* ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now power-profile-policy.timer
```

Manual overrides via the Omarchy power-profile menu get reverted within 2
minutes — same "no sticky override" convention as
`~/Developer/omarchy-services/scripts/battery-policy.sh`. See
`04 Tech/Hermes/power-profile-policy.md` for full context and the undo steps.

## Sync from live system

```bash
./sync-from-system.sh
```

After changing Plymouth assets:

```bash
~/.config/omarchy/plymouth/apply-plymouth.sh
```

## Regenerate branding

```bash
~/.config/omarchy/branding/generate-arch-j4c1cz.sh
```

Use `--generate` only to rebuild from the neofetch mask (overwrites hand-edited `arch-j4c1cz.txt`).

## Machine

- Omarchy on Arch Linux (Hyprland)
- GitHub: [jackzasian](https://github.com/jackzasian)

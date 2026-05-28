# j4c1cz dotfiles (Omarchy / Hyprland)

Private backup of Linux desktop configuration.

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

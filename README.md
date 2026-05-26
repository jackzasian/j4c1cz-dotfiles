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

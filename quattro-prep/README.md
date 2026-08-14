# Quattro prep — staged, NOT live

Built 2026-08-11, before Omarchy Quattro (4.x) shipped stable. **Nothing here is active.**
Everything is a draft to validate against the real Quattro after the upgrade, then install
deliberately. Runbook: `~/Obsidian/J4c1c/_meta/Hermes/omarchy-migration-runbook.md`

Written against the `quattro` branch at `4.0.0.alpha`. The stable release may shift the Lua API,
the `shell.json` schema, or command names — treat every file as a draft, not gospel.

## Contents

| Path | Installs to | Purpose |
|------|-------------|---------|
| `hooks/pre-refresh-pacman.d/10-restore-proxy-xfercommand` | `~/.config/omarchy/hooks/pre-refresh-pacman.d/` | Re-adds the Clash `XferCommand` after `omarchy refresh pacman` overwrites `/etc/pacman.conf` |
| `uwsm-env.d/99-jackz-path.conf` | `~/.config/uwsm/env.d/` | Prepends `~/bin` + `~/.local/bin` so shims beat `/usr/bin` |
| `local-bin/omarchy-pkg-aur-accessible` | `~/.local/bin/` | Shim: proxied AUR reachability check (replaces a git patch) |
| `etc-sudoers.d/10-jackz-proxy-env` | `/etc/sudoers.d/` | Passes proxy env through `sudo` (replaces the `sudo -E` patches) |
| `chromium-extensions/fixed-geolocation/` | `~/.local/share/chromium-extensions/` | Your extension, out of the pacman-owned tree |
| `restore/fix-chromium-extensions.sh` | — | Relocates the extension, rewrites `chromium-flags.conf` + `omarchy-set-geolocation` |
| `restore/restore-docker-daemon.sh` | — | Shows Quattro's `daemon.json` vs yours, then you choose |
| `hypr-lua/` | `~/.config/hypr/` | Lua port of the 12 `.conf` files |
| `shell/shell.json` | `~/.config/omarchy/` | Bar layout translated from `waybar/config.jsonc` |
| `shell/scripts/` | `~/.config/omarchy/bar/scripts/` | 12 surviving custom scripts (6 unchanged, 0 patched, 9 dropped vs waybar's 21) |
| `shell/profile-switch.md` | — | Design for laptop/docked profile switching (new code) |
| `shell/VERIFY.md` | — | Offline checks + 12-point live-verification checklist |

## Why the PATH drop-in is load-bearing

Pre-Quattro, `~/.config/uwsm/env` did `export PATH=$OMARCHY_PATH/bin:$PATH:$HOME/.local/bin`, and
`~/.local/bin` landed at position 7 — ahead of `/usr/bin` at 12. That ordering is what makes two
wrappers work:

- `~/.local/bin/yay` → routes yay + child git through Clash HTTP proxy, **unsetting `ALL_PROXY`**
  because SOCKS breaks AUR git clones
- `~/.local/bin/cursor`

Quattro's `/usr/share/omarchy/default/bash/env-bootstrap` **appends** `~/.local/bin`, so
`/usr/bin/yay` (the real package, installed) would shadow the wrapper and AUR builds would lose the
proxy. `99-jackz-path.conf` restores the ordering — and, as a bonus, makes `~/.local/bin` shims a
supported way to override package-owned `omarchy-*` commands without touching `/usr/bin`.

## Order of installation (after the upgrade, once verified)

```bash
P=~/dotfiles/quattro-prep

# 1. PATH first — everything else depends on shim precedence
mkdir -p ~/.config/uwsm/env.d && cp "$P/uwsm-env.d/99-jackz-path.conf" ~/.config/uwsm/env.d/
#    log out / back in, then confirm:
#    command -v yay        -> ~/.local/bin/yay
#    printf '%s\n' "$PATH" | tr : '\n' | grep -n 'local/bin\|/usr/bin'

# 2. AUR shim
cp "$P/local-bin/omarchy-pkg-aur-accessible" ~/.local/bin/ && omarchy-pkg-aur-accessible && echo "AUR reachable"

# 3. pacman proxy guard  (test it BEFORE you ever need it)
mkdir -p ~/.config/omarchy/hooks/pre-refresh-pacman.d
cp "$P/hooks/pre-refresh-pacman.d/10-restore-proxy-xfercommand" ~/.config/omarchy/hooks/pre-refresh-pacman.d/
#    then: omarchy refresh pacman   and check `grep -c XferCommand /etc/pacman.conf` == 1

# 4. sudoers (optional — see the note in the file)
sudo visudo -cf "$P/etc-sudoers.d/10-jackz-proxy-env" \
  && sudo install -m 0440 -o root -g root "$P/etc-sudoers.d/10-jackz-proxy-env" /etc/sudoers.d/

# 5. chromium + docker
bash "$P/restore/fix-chromium-extensions.sh"
bash "$P/restore/restore-docker-daemon.sh"
```

Use `/usr/bin/sudo` explicitly if `sudo` misbehaves — `~/bin/sudo` is a `run0` wrapper and does not
accept all sudo flags (`sudo -n` fails with `run0: unrecognized option`).

## Patches this replaces

The 7 modified files in the old `~/.local/share/omarchy` checkout, and what happens to each:

| Patched command | Fate under Quattro |
|---|---|
| `omarchy-pkg-add`, `-install`, `-remove` (`sudo` → `sudo -E`) | superseded by the sudoers `env_keep` drop-in |
| `omarchy-pkg-drop` (`sudo -E` **and** a `pacman -Qq \| grep -Fxq` → `pacman -Q` fix) | **Quattro already fixed the lookup** upstream (associative array). Only the `-E` part remains, covered by sudoers. Patch retired. |
| `omarchy-pkg-aur-accessible` (hardcoded `--proxy`) | replaced by the `~/.local/bin` shim |
| `omarchy-pkg-aur-add`, `omarchy-update-aur-pkgs` (source `omarchy-pkg-aur-env`) | covered by the `~/.local/bin/yay` wrapper once PATH ordering is restored |
| `default/omarchy-skill/SKILL.md` (your edits) | the upgrade repoints `~/.claude/skills/omarchy` at the package tree; re-apply your edits somewhere not package-owned |

Original diffs: `~/dotfiles/patches/omarchy-local/` and
`Backups/ThinkPad/pre-quattro/20260811T122329/omarchy-local-patches/`.

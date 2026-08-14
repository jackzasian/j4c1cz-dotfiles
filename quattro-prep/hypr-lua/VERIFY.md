# Hyprland Lua port — verification checklist

Ported 2026-08-11 from the 12 `~/.config/hypr/*.conf` files against the `quattro`
branch at `4.0.0.alpha`. **Not installed.** Validate against the real Quattro first.

## Offline checks already done

- `luac -p` on all 8 files — pass
- Executed all 7 modules against a stubbed `hl`/`o` API using Quattro's **real**
  `default/hypr/helpers.lua`, so `o.bind` / `o.window` / `o.launch*` behaved as shipped:
  `binds=49 monitors=2 workspace_rules=10 window_rules=3 config=6 env=7 animations=1 gestures=4 permissions=1 exec_on_start=14`
- Bindings reconciled against `bindings.conf`: **52 original → 49 ported + 3 deliberate drops**,
  no duplicate keys, nothing invented.

The 3 drops:

| Binding | Why |
|---|---|
| `switch:on:Lid Switch` → `dpms off` | Quattro's defaults bind the lid to `omarchy-system-lid-close` / `omarchy-hyprland-monitor-clamshell`, which is strictly more capable. Kept commented in `bindings.lua` — re-enable only if clamshell regresses. |
| `switch:off:Lid Switch` → `dpms on` | same |
| `SUPER+SHIFT+ALT+L` → `obsidian-open-links-recent` | **Was already dead.** `bindings.conf` bound this key twice (lines 17 and 98); hyprlang's last-wins meant only `j4c1cz clip` ever fired. Give it its own key if you actually wanted it. |

## Install

```bash
P=~/dotfiles/quattro-prep/hypr-lua
cp "$P"/{hyprland,monitors,input,bindings,looknfeel,autostart,plugins,envs-local}.lua ~/.config/hypr/
hyprctl reload && hyprctl configerrors
```

Keep the old `.conf` files until this is proven — Quattro leaves them on disk and
simply stops reading them, which makes them a free reference.

## Must verify on the real thing

Ordered by likelihood of biting.

1. **`hl.monitor` extra keys.** `sdr_min_luminance` / `sdr_max_luminance` came from
   `monitorv2` blocks. If `hl.monitor()` rejects them, drop them (HDR tonemapping on
   the Studio Display only) or set via `hyprctl keyword`. → `hyprctl monitors all`
2. **Monitor `desc:` strings.** The Samsung desc has **two consecutive spaces**
   (`ATNA40HQ10-0  0x0000003F`). Preserved verbatim; do not tidy. If workspaces land
   on the wrong output, this is why. → `hyprctl monitors | grep description`
3. **Re-binding vs unbinding.** `SUPER+W` and `SUPER+CTRL+DELETE` override Omarchy
   defaults by re-declaring. If a key double-fires instead of overriding, capture the
   default's returned keybind object and call `:unbind()` (pattern in
   `default/hypr/bindings/utilities.lua:77`).
4. **`hl.workspace_rule` monitor binding.** Confirm 5/6/7 land on the ThinkPad panel
   and the rest on the Studio when both are attached.
5. **`hl.gesture` with a function action.** The 3 overview gestures use
   `action = function() hl.dispatch(hl.dsp.exec_cmd(...)) end`. Only the shipped
   template documents this shape — no Omarchy default uses it.
6. **Plugin config keys.** `["dynamic-cursors"]` needs bracket-quoting; `overview` is
   camelCase (`panelHeight`, not `panel_height`). → `hyprctl getoption plugin:overview:panelHeight`
7. **`hl.permission`** only matters if Omarchy sets `ecosystem.enforce_permissions`.
   Harmless otherwise.
8. **`hl.env(k, "")`** — the fcitx5 IM modules must end up *set but empty*, not unset.
   Quattro also ships `/usr/lib/environment.d/10-omarchy-fcitx.conf`, so this may be
   redundant. → `systemctl --user show-environment | grep IM_MODULE`
9. **Capture bindings.** `satty`, `wf-recorder` and `wl-screenrec` are all retired by
   Quattro. Confirm `omarchy-capture-screenshot` / `-text-extraction` still exist and
   behave the same before trusting `SUPER+CTRL+1..4`.
10. **`lazydocker`** is retired (`lazydocker-bin` on the removal list) — `SUPER+SHIFT+D`
    will do nothing until you reinstall it.

## Known incomplete

- **`window-no-gaps` toggle.** The old `~/.local/state/omarchy/toggles/hypr/` held
  `window-no-gaps.conf`; Quattro's toggles are Lua and the upgrade only writes
  `flags.lua`. Check whether Quattro has a native equivalent before reimplementing.
- **XREAL.** `xreal.conf` sourced two *generated* `.conf` files. Both are currently
  empty stubs, so nothing functional is lost, but `~/.local/bin/xreal-travel` must be
  changed to emit `.lua` (or better, apply at runtime via `hyprctl keyword`) before
  cinema mode works again. `envs-local.lua` loads a `.lua` variant if one appears.
- **Waybar autostart.** Three `exec-once` entries dropped (`waybar-apply-profile.sh`,
  `waybar-monitor-watch.sh`, `waybar-power-watch.sh`) — no target exists any more. See
  `../shell/`.
- **`hyprsunset-flux-schedule`.** Still started here, but Quattro ships an
  `omarchy.nightlight` plugin and `omarchy-refresh-hyprsunset`. If those supersede it,
  drop both this and the systemd unit rather than running two schedulers.

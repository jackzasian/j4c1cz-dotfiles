-- ~/.config/hypr/hyprland.lua — Quattro entry point  (2026-08-11, DRAFT)
--
-- Based on Quattro's shipped config/hypr/hyprland.lua, extended with the extra
-- modules this machine needs. Ported from the 21 `source =` lines of the old
-- ~/.config/hypr/hyprland.conf.

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults. Replaces these old source lines, which are now all
-- inside this one require:
--   default/hypr/autostart.conf, bindings/{media,clipboard,tiling-v2,utilities}.conf,
--   envs.conf, looknfeel.conf, input.conf, windows.conf
require("default.hypr.omarchy")

-- Personal overrides, loaded after Omarchy's defaults so package updates can
-- improve the defaults without rewriting these files.
require("hypr.monitors")     -- monitors + workspace->monitor map
require("hypr.input")        -- keyboard, touchpad, native gestures
require("hypr.bindings")     -- 52 bindings
require("hypr.looknfeel")    -- rounding, groupbar, workspace animation, cursor
require("hypr.autostart")    -- login app layout, hyprpm, dock lights
require("hypr.plugins")      -- dynamic-cursors, Hyprspace, hyprgrass (inert)
require("hypr.envs-local")   -- fcitx5 IM modules, XREAL

-- Toggle config flags dynamically. Replaces
--   source = ~/.local/state/omarchy/toggles/hypr/*.conf
-- Quattro's toggles are Lua (~/.local/state/omarchy/toggles/hypr/flags.lua,
-- written by the upgrade). NOTE: your old toggles dir also held
-- window-no-gaps.conf, which will NOT be picked up. Check whether Quattro has an
-- equivalent toggle (`omarchy toggle` / the shell's Toggles menu) before
-- reimplementing it.
require("default.hypr.toggles")

-- The theme's hyprland.conf (`source = ~/.config/omarchy/current/theme/hyprland.conf`)
-- is no longer sourced by hand — Quattro's theming handles it, and the current
-- path moved to ~/.local/state/omarchy/current. See docs/theming.md.

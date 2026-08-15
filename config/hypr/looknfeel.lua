-- Ported from ~/.config/hypr/looknfeel.conf + the cursor half of
-- ~/Developer/Anya-cursors/cursor.conf  (2026-08-11, DRAFT)

hl.config({
  decoration = {
    rounding = 14,
    rounding_power = 2.8,
  },

  group = {
    groupbar = {
      rounding = 12,
      rounding_power = 2.8,
      gradient_rounding = 12,
      gradient_rounding_power = 2.8,
    },
  },
})

-- Keep popped tiles consistent with global rounding.
o.window({ tag = "pop" }, { rounding = 14 })

-- ── Window transparency ──────────────────────────────────────────────────────
-- Quattro's own default (windows.lua, read-only) sets opacity "0.985 0.96" —
-- barely transparent at all. jackz wants it noticeably more see-through, and
-- adjustable without re-asking each time -- managed by omarchy-window-opacity,
-- edit by hand or via that command, both fine.
o.window({ tag = "default-opacity" }, { opacity = "0.9 0.8" })
hl.config({ decoration = { blur = { enabled = true, size = 4, passes = 2 } } })

-- Smooth workspace slide while swiping. Omarchy's default uses a fade; this
-- restores the slide that gestures-macos.conf set with
-- `animation = workspaces, 1, 4, easeOutQuint, slide`.
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })

-- ── Cursor: Anya-cursors ─────────────────────────────────────────────────────
-- Previously `source = ~/Developer/Anya-cursors/cursor.conf`. Lua cannot source
-- a .conf, and that file lives in an upstream repo you can't push to, so the
-- settings are inlined here instead. The repo stays useful only as the theme
-- asset source.
--
-- no_hardware_cursors = true matches the running session as of 2026-08-03 and is
-- what makes the dynamic-cursors plugin render correctly. Verify after upgrade:
--   hyprctl getoption cursor:no_hardware_cursors
hl.config({
  cursor = {
    no_hardware_cursors = true,
  },
})

hl.env("XCURSOR_THEME", "Anya-cursors")
hl.env("XCURSOR_SIZE", "24")

o.exec_on_start("gsettings set org.gnome.desktop.interface cursor-theme 'Anya-cursors'")
o.exec_on_start("gsettings set org.gnome.desktop.interface cursor-size 24")
o.exec_on_start("hyprctl setcursor Anya-cursors 24")

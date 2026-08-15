-- Ported from ~/.config/hypr/{input,gestures-macos}.conf  (2026-08-11, DRAFT)

hl.config({
  input = {
    kb_layout = "us",
    -- physical Caps sends Ctrl. Several bindings in bindings.lua depend on this
    -- (the CleanShot-style SUPER+CTRL+1..4 captures, and Bedtime mode).
    kb_options = "ctrl:swapcaps",

    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    touchpad = {
      natural_scroll = true,        -- macOS-like content scrolling
      clickfinger_behavior = true,  -- two-finger click = right click
      drag_3fg = 1,                 -- macOS-like three-finger window drag
      scroll_factor = 0.35,
    },
  },
})

-- Per-app touchpad scroll speed.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- ── macOS-like touchpad gestures (was gestures-macos.conf) ───────────────────
-- Native Hyprland gestures (0.55+). hyprgrass is touchscreen-only — see plugins.lua.
--
-- The overview gestures deliberately go through `hyprctl dispatch` rather than a
-- direct overview:toggle dispatcher: Hyprspace is loaded by hyprpm *after* the
-- config is parsed, so naming its dispatcher at parse time drops Hyprland into
-- safe mode. Same reasoning as the overview binds in bindings.lua.
local function dispatch_shell(command)
  return function()
    hl.dispatch(hl.dsp.exec_cmd(command))
  end
end

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up", action = dispatch_shell("hyprctl dispatch overview:toggle") })
hl.gesture({ fingers = 4, direction = "down", action = dispatch_shell("hyprctl dispatch overview:close") })
-- ThinkPad touchpads often can't resolve 4 fingers reliably, so 3-up too.
hl.gesture({ fingers = 3, direction = "up", action = dispatch_shell("hyprctl dispatch overview:toggle") })

hl.config({
  gestures = {
    workspace_swipe_distance = 350,
    workspace_swipe_cancel_ratio = 0.2,
    workspace_swipe_min_speed_to_force = 25,
    workspace_swipe_direction_lock = true,
    workspace_swipe_direction_lock_threshold = 8,
    workspace_swipe_create_new = true,
    workspace_swipe_forever = false,
    -- false ≈ macOS direction (swipe left → space on the right). Flip if backwards.
    workspace_swipe_invert = false,
  },
})

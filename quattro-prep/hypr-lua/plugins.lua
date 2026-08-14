-- Ported from ~/.config/hypr/{plugins,hyprspace}.conf  (2026-08-11, DRAFT)
--
-- hyprpm still works under a Lua config — plugin loading is a Hyprland feature,
-- not an Omarchy one, so Omarchy shipping no hyprpm integration is expected.
-- Upstream's own example/hyprland.lua carries the hl.permission line below.
-- Loading itself happens via `hyprpm update -n` in autostart.lua.
--
-- IMPORTANT Lua syntax detail: plugin option keys with a dash ("dynamic-cursors")
-- are not valid Lua identifiers, so they need bracket-quoted keys.
--
-- Docs: ~/Obsidian/J4c1c/_meta/Hermes/hypr-plugins-stack.md

-- Only needed if Omarchy enables ecosystem.enforce_permissions; harmless otherwise.
-- Without it you get a permission prompt on every plugin load.
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-- ── hypr-dynamic-cursors (VirtCode) ──────────────────────────────────────────
-- Anya-cursors theme is set in looknfeel.lua; mode = "none" so only shake-to-find
-- runs. https://github.com/VirtCode/hypr-dynamic-cursors
hl.config({
  plugin = {
    ["dynamic-cursors"] = {
      enabled = true,
      mode = "none",

      -- Shake-to-find (macOS "shake to enlarge pointer")
      shake = {
        enabled = true,
        threshold = 3.0,   -- lower = triggers sooner (default 6.0; trackpads need lower)
        base = 4.0,        -- magnification at shake start
        speed = 4.0,       -- magnification increase per second of continued shaking
        influence = 0.0,
        limit = 0.0,       -- 0 = no upper limit
        timeout = 2000,    -- ms magnified after shaking ends
        effects = false,   -- no tilt/rotate while shaking (mode is none anyway)
        ipc = false,
      },

      -- High-res hyprcursor textures when magnified
      hyprcursor = {
        enabled = true,
        nearest = 1,
        resolution = -1,
        fallback = "clientside",
      },
    },
  },
})

-- ── Hyprspace (0xl30 fork) ───────────────────────────────────────────────────
-- Reads plugin:overview:* in camelCase, NOT plugin:hyprspace.
-- Pin: 0xl30/Hyprspace 8b4284e for Hyprland 0.56.
--
-- BEFORE UPGRADING: check the fork supports whatever Hyprland version Quattro
-- pulls. This is the one plugin likely to lag — it is a fork, not upstream.
--
-- overrideGaps MUST stay 0: Config::Legacy::mgr().lock() aborts on 0.56 and you
-- get the Error Overlay. If Quattro ships a newer Hyprland where the legacy
-- config path is gone entirely, this whole block may need revisiting.
hl.config({
  plugin = {
    overview = {
      panelHeight = 140,
      workspaceMargin = 6,
      workspaceBorderSize = 1,
      panelBorderWidth = 1,
      reservedArea = 32,

      onBottom = false,
      centerAligned = true,
      exitOnClick = true,
      exitOnSwitch = true,
      switchOnDrop = true,
      autoDrag = true,
      showNewWorkspace = true,
      showEmptyWorkspace = false,

      disableGestures = true,
      reverseSwipe = true,
      exitKey = "Escape",

      overrideGaps = 0,
    },
  },
})

-- ── hyprgrass (horriblename) — TOUCHSCREEN ONLY ──────────────────────────────
-- Enabled at the hyprpm level on this machine but inert, because this ThinkPad
-- has no touchscreen and the touch_gestures config block below stays commented.
-- Post-upgrade checks must verify BOTH layers, not just `hyprpm list`.
-- ThinkPad trackpad gestures live in input.lua, not here.
--
-- hl.config({ plugin = { touch_gestures = {
--   sensitivity = 4.0,
--   workspace_swipe_fingers = 3,
--   workspace_swipe_edge = "d",
-- } } })
--
-- Optional hyprgrass-pulse volume on 3-finger vertical (not a macOS default):
--   pulse-gesture = 3, vertical, volume

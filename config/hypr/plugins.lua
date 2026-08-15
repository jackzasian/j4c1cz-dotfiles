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

-- ── hypr-dynamic-cursors (VirtCode) — PLUGIN DISABLED 2026-08-15 ────────────
-- Anya-cursors theme is set in looknfeel.lua and works fine on its own.
-- https://github.com/VirtCode/hypr-dynamic-cursors
--
-- hl.config({ plugin = { ["dynamic-cursors"] = {...} } }) fails on EVERY key
-- with "unknown config key", even though the option genuinely exists
-- (`hyprctl getoption plugin:dynamic-cursors:enabled` returns a real bool).
-- Confirmed this is not a Lua-nesting, hyphen-escaping, key-casing, or timing/
-- reload-order issue: tried the identical shape as the working Hyprspace/overview
-- block below (which sets fine), a flat "plugin:dynamic-cursors:enabled" string
-- key, "dynamiccursors", "DynamicCursors", and live `hyprctl eval` at runtime
-- (not just config-parse time) — all fail identically. `hyprctl keyword` is
-- disabled under this non-legacy parser ("Use eval"), so there's no other
-- write path to try. Also checked: no cached plugin README/docs describing an
-- alternate IPC/config mechanism (only the built .so + state.toml are cached
-- under /var/cache/hyprpm), and no `--legacy` override flag on hyprctl.
--
-- With the config unreachable, the plugin runs on its compiled-in default
-- `mode = "tilt"` instead of the `mode = "none"` this was set up for — the
-- cursor visibly rotates/tilts during movement, which is what "cursor not
-- correct" actually was. Rather than live with that, disabled the plugin
-- outright: `hyprpm disable dynamic-cursors && hyprpm reload -n`. Trade-off:
-- lose shake-to-find magnification too, since it's the same plugin. If a
-- later Hyprland/Quattro release fixes the hl.config() write path, re-enable
-- with `hyprpm enable dynamic-cursors` and uncomment the block below.
-- Root cause worth an upstream report (see the omarchy skill's contributing.md).
--
-- hl.config({
--   plugin = {
--     ["dynamic-cursors"] = {
--       enabled = true,
--       mode = "none",
--
--       -- Shake-to-find (macOS "shake to enlarge pointer")
--       shake = {
--         enabled = true,
--         threshold = 3.0,   -- lower = triggers sooner (default 6.0; trackpads need lower)
--         base = 4.0,        -- magnification at shake start
--         speed = 4.0,       -- magnification increase per second of continued shaking
--         influence = 0.0,
--         limit = 0.0,       -- 0 = no upper limit
--         timeout = 2000,    -- ms magnified after shaking ends
--         effects = false,   -- no tilt/rotate while shaking (mode is none anyway)
--         ipc = false,
--       },
--
--       -- High-res hyprcursor textures when magnified
--       hyprcursor = {
--         enabled = true,
--         nearest = 1,
--         resolution = -1,
--         fallback = "clientside",
--       },
--     },
--   },
-- })

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

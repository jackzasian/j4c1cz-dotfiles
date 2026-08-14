-- Ported from ~/.config/hypr/{envs-local,xreal}.conf  (2026-08-11, DRAFT)

-- ── PATH ─────────────────────────────────────────────────────────────────────
-- envs-local.conf set a full literal PATH via `env = PATH,...` to force
-- ~/.local/bin ahead of everything (needed by omarchy-hyprland-monitor-internal
-- and the yay wrapper).
--
-- DO NOT port that literal PATH. It hardcoded ~/.local/share/omarchy/bin, which
-- no longer exists, and it would fight Quattro's own env-bootstrap. The PATH
-- ordering is handled instead by:
--   ~/.config/uwsm/env.d/99-jackz-path.conf   (see ../uwsm-env.d/)
-- which prepends $HOME/bin and $HOME/.local/bin after Omarchy is done.
--
-- After the upgrade, confirm inside a Hyprland session:
--   command -v yay      -> ~/.local/bin/yay   (NOT /usr/bin/yay)
--   command -v cursor   -> ~/.local/bin/cursor

-- ── fcitx5 on Wayland ────────────────────────────────────────────────────────
-- GTK/QT IM modules are deliberately EMPTY so both toolkits use their native
-- Wayland text-input protocol instead of routing through the fcitx module.
-- hl.env with "" reproduces `env = GTK_IM_MODULE,` (a set-but-empty value).
-- VERIFY after upgrade: Quattro ships /usr/lib/environment.d/10-omarchy-fcitx.conf
-- (it retires ~/.config/environment.d/fcitx.conf). If that already sets these,
-- this block is redundant — check with `systemctl --user show-environment | grep IM_MODULE`.
hl.env("GTK_IM_MODULE", "")
hl.env("QT_IM_MODULE", "")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("INPUT_METHOD", "fcitx")

-- ── XREAL glasses ────────────────────────────────────────────────────────────
-- xreal.conf did:
--   source = ~/.local/state/xreal/monitor.generated.conf
--   source = ~/.local/state/xreal/windowrules.generated.conf
--
-- Lua cannot `source` a .conf, and both files are currently empty stubs
-- ("inactive until cinema mode starts" / "until glasses are connected"), so
-- nothing functional is lost right now.
--
-- To restore this properly, pick one:
--   (a) Change the generator (~/.local/bin/xreal-travel) to emit .lua and load it
--       here with the optional-require helper, e.g.
--         local ok = pcall(dofile, os.getenv("HOME") .. "/.local/state/xreal/monitor.generated.lua")
--       Quattro has default/hypr/require_optional.lua for exactly this shape.
--   (b) Better fit for how this actually works: cinema mode is dynamic, so have
--       xreal-travel apply monitors and window rules at runtime via
--       `hyprctl keyword ...` and stop generating config fragments at all.
--
-- Until then this is a no-op, matching today's empty stubs.
local xreal_generated = os.getenv("HOME") .. "/.local/state/xreal/monitor.generated.lua"
local file = io.open(xreal_generated, "r")
if file then
  file:close()
  dofile(xreal_generated)
end

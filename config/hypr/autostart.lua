-- Ported from ~/.config/hypr/autostart.conf  (2026-08-11, DRAFT)
--
-- exec-once = X  ->  o.exec_on_start("X")   (raw command)
--                ->  o.launch_on_start("X") (wraps in uwsm-app --)
--
-- Several entries from autostart.conf are DELETED rather than ported. Each is
-- noted below with why, so you can tell deliberate removal from oversight.

-- ── Night light ──────────────────────────────────────────────────────────────
-- hyprsunset itself stays a systemd user unit; a duplicate exec-once caused
-- "CTM manager already running". Only the schedule generator runs here.
-- VERIFY: Quattro ships an omarchy.nightlight shell plugin and omarchy-refresh-hyprsunset.
-- If that supersedes hyprsunset-flux-schedule, drop this and the systemd unit.
o.launch_on_start("hyprsunset-flux-schedule")

-- DROPPED: the `sleep 2 && systemctl --user stop app-Hyprland-hypridle-*.scope`
-- hack. It existed because Omarchy 3's default autostart exec-once'd hypridle
-- while hypridle.service was also WantedBy=graphical-session.target, so two
-- instances double-inhibited sleep. Quattro RETIRES hypridle entirely (idle is
-- the omarchy.idle shell plugin), so there is nothing left to de-duplicate.

-- ── Login app layout ─────────────────────────────────────────────────────────
-- Staggered on purpose: concurrent GPU-process init on Intel xe fails
-- intermittently ("GPU process isn't usable" / silent no-window), so Electron and
-- Chromium apps are serialised. The delay also lets hyprpm reload and Clash
-- settle before proxy-dependent apps start.
--
-- Kept as `sleep N && hyprctl dispatch exec "[workspace N silent] ..."` verbatim.
-- The [workspace N silent] prefix is a launch-time rule, not a persistent window
-- rule, so it does not pin later windows of the same app.
local function launch_delayed(seconds, workspace, command)
  o.exec_on_start(string.format(
    'sleep %d && hyprctl dispatch exec "[workspace %d silent] %s"', seconds, workspace, command))
end

launch_delayed(4, 1, "wechat-launch")
launch_delayed(6, 1, "discord-launch")
launch_delayed(9, 2, "uwsm-app -- zen-browser")
-- Kitty + Zellij "agents" layout (cursor/claude/opencode + ssh x2 + nvim)
launch_delayed(12, 3, "uwsm-app -- kitty-agents")
launch_delayed(13, 3, "uwsm-app -- nautilus --new-window")
launch_delayed(15, 4, "uwsm-app -- cursor")
launch_delayed(18, 4, "uwsm-app -- obsidian")
launch_delayed(21, 5, "uwsm-app -- spotify")

-- ── ThinkPad / dock hardware ─────────────────────────────────────────────────
-- Studio Display docked: zero the laptop panel + keyboard backlight.
-- The hotplug watcher is a systemd user unit, not started here.
o.launch_on_start("studio-dock-lights auto")

-- ── Hyprland plugins ─────────────────────────────────────────────────────────
-- Rebuild + reload plugins on startup so the ABI matches after a Hyprland bump.
-- `hyprpm reload` alone silently fails to load stale plugin binaries. No -f, so
-- it only rebuilds when headers/commits actually changed. See plugins.lua.
o.exec_on_start("sleep 5 && hyprpm update -n > /tmp/hyprpm-startup.log 2>&1")

-- ── DROPPED: waybar ──────────────────────────────────────────────────────────
-- Quattro retires waybar; these three scripts have no target any more:
--   ~/.config/waybar/scripts/waybar-apply-profile.sh   (docked vs laptop profile)
--   ~/.config/waybar/scripts/waybar-monitor-watch.sh   (re-apply on hotplug)
--   ~/.config/waybar/scripts/waybar-power-watch.sh     (AC/battery poll intervals)
--
-- The bar is now ~/.config/omarchy/shell.json (see ../shell/shell.json), which has
-- no per-monitor or profile concept. Laptop/docked switching needs reimplementing
-- as something that rewrites shell.json and reloads the shell. Until that exists,
-- you get one static bar on all outputs. Tracked in the runbook §8 backlog.

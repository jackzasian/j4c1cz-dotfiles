-- Ported from ~/.config/hypr/bindings.conf  (2026-08-11, DRAFT) — 52 bindings.
--
-- Syntax notes for reviewing this file:
--   bindd = SUPER SHIFT, X, Desc, exec, cmd   ->  o.bind("SUPER + SHIFT + X", "Desc", cmd)
--   bindl / bindld                            ->  o.bind(..., { locked = true })
--   unbind = MOD, KEY   +   rebind            ->  just re-declare o.bind(); user
--       files load after default.hypr.omarchy, so the later bind wins. To
--       REMOVE a packaged default first, call hl.unbind("SUPER + W") BEFORE
--       the new o.bind() — Omarchy's sanctioned override, see the omarchy
--       skill docs and /usr/share/omarchy/default/hypr/bindings.lua.
--
-- Helper table forms (see default/hypr/helpers.lua):
--   { launch = "cmd" }            -> uwsm-app -- cmd
--   { focus = "match", launch = } -> omarchy-launch-or-focus 'match' 'uwsm-app -- cmd'
--   { webapp = url }              -> omarchy-launch-webapp 'url'
--   { webapp = url, focus = true} -> omarchy-launch-or-focus-webapp '<description>' 'url'
--   { tui = "x", focus = true }   -> omarchy-launch-or-focus-tui 'x'
-- Raw strings are used wherever the command needs shell expansion, or where the
-- or-focus *name* differs from the description (the helper reuses the
-- description as the name, which would change matching behaviour).

local home = os.getenv("HOME")

-- ── Applications ─────────────────────────────────────────────────────────────
-- SUPER+RETURN 2026-08-15: NOT re-declared here anymore. Re-declaring it
-- (first as kitty-agents, then as a plain `kitty -o shell=.` override) left
-- Quattro's own packaged default (`omarchy-launch-terminal`, which calls
-- xdg-terminal-exec) ALSO registered on the same combo the whole time —
-- confirmed via `hyprctl binds -j` showing 2 live registrations, and
-- jackz actually seeing two terminal windows open on one press. (Note: the
-- packaged default COULD have been removed with hl.unbind("SUPER + RETURN"),
-- as with SUPER+W below — this was settled before that was known. Chosen
-- alternative:) made kitty the system default terminal
-- (~/.config/xdg-terminals.list) and removed kitty.conf's global Zellij
-- shell override (nothing else needed it — see kitty.conf's own comment).
-- Quattro's single default binding now does exactly what we want: one
-- plain kitty window, no crossover.
-- $() needs a shell; exec dispatchers run through /bin/sh, so this is fine.
o.bind("SUPER + ALT + RETURN", "Terminal (Zellij, cwd)",
  [[uwsm-app -- kitty --session none -d "$(omarchy-cmd-terminal-cwd)" -e zellij]])
-- Re-declared from Quattro's preinstalled-bindings block, which
-- omarchy_preinstalled_bindings = false now disables (see hyprland.lua).
o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + SHIFT + M", "Music", { omarchy = "spotify" })
o.bind("SUPER + SHIFT + RETURN", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + F", "File manager", { launch = "nautilus --new-window" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)",
  [[uwsm-app -- nautilus --new-window "$(omarchy-cmd-terminal-cwd)"]])
o.bind("SUPER + SHIFT + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
-- NOTE: lazydocker is retired by Quattro (lazydocker-bin is on the removal list).
-- Reinstall it or drop this binding.
o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + SHIFT + ALT + D", "Discord", { launch = "discord-launch" })
o.bind("SUPER + SHIFT + G", "Signal", { focus = "^signal$", launch = "signal-desktop" })
o.bind("SUPER + SHIFT + O", "Obsidian", { focus = "^obsidian$", launch = "obsidian" })
o.bind("SUPER + SHIFT + W", "Wechat", "wechat-launch")
o.bind("SUPER + SHIFT + SLASH", "Passwords", { focus = "Bitwarden", launch = "bitwarden-desktop" })
o.bind("SUPER + SHIFT + ALT + C", "Claude",
  { focus = "Claude", launch = home .. "/.local/bin/claude-launch" })

-- ── Obsidian / notes capture ─────────────────────────────────────────────────
-- Capture keybindings are managed by the omarchy-obsidian-capture plugin
-- (see require("obsidian-capture") at the bottom of this file).
o.bind("SUPER + SHIFT + T", "Tasks (Obsidian)", { focus = "^obsidian$", launch = "obsidian" })

-- Quattro's default binds Omawrite to SUPER+SHIFT+W, which we need for
-- WeChat instead — but `omarchy_preinstalled_bindings = false` (see
-- hyprland.lua) now removes the packaged Omawrite binding entirely, so
-- SUPER+SHIFT+W is cleanly WeChat-only. This gives Omawrite a dedicated key:
o.bind("SUPER + SHIFT + CTRL + W", "Omawrite", { launch = "omawrite" })

-- CONFLICT carried over from bindings.conf: SUPER+SHIFT+ALT+L was bound twice —
-- once to the links-recent feed and again to `j4c1cz clip` (line 98). In hyprlang
-- the last one won, so only "Publish link" was reachable. The recent feed is now
-- available via the Obsidian Super+Space menu (`obsidian-capture recent`), so the
-- shadowed binding is intentionally left unbound.
o.bind("SUPER + SHIFT + ALT + L", "Publish link to j4c1cz", home .. "/.local/bin/j4c1cz clip")

-- ── Web apps ─────────────────────────────────────────────────────────────────
o.bind("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
o.bind("SUPER + SHIFT + E", "Email", { webapp = "https://app.hey.com" })
-- Re-declared from the disabled preinstalled-bindings block (see hyprland.lua).
o.bind("SUPER + SHIFT + ALT + E", "New email",
  { webapp = "https://app.hey.com/messages/new?display=standalone&new_window=true" })
o.bind("SUPER + SHIFT + S", "Google Maps", { webapp = "https://maps.google.com/", focus = true })
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
o.bind("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })
-- description == or-focus name for these three, so the helper form is safe.
o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
o.bind("SUPER + SHIFT + CTRL + G", "Google Messages",
  { webapp = "https://messages.google.com/web/conversations", focus = true })
o.bind("SUPER + SHIFT + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
-- Raw: the or-focus name is "Hermes Discord", not the description.
o.bind("SUPER + SHIFT + H", "Hermes Discord webapp",
  [[omarchy-launch-or-focus-webapp "Hermes Discord" "https://discord.com/channels/@me"]])

-- ── Window management overrides ──────────────────────────────────────────────
-- jackz wants macOS-style semantics: SUPER+Q = hard quit, SUPER+W = soft
-- close (WeChat stays in the tray; "close this tab" for tabbed apps).
--
-- SUPER+Q is clean: nothing else claims it, so this is the only handler.
o.bind("SUPER + Q", "Quit app (hard close)", hl.dsp.window.close())
--
-- SUPER+W needs an explicit unbind: Quattro's packaged default
-- (`o.bind("SUPER + W", "Close window", hl.dsp.window.close())` in
-- default/hypr/bindings/tiling.lua) registers first, so without this the
-- hard close above would fire alongside the tray-safe close below and
-- hard-quit WeChat despite the intent. `hl.unbind("SUPER + W")` is Omarchy's
-- sanctioned override (see /usr/share/omarchy/default/hypr/bindings.lua and
-- the omarchy skill docs) and must come BEFORE the re-bind. Confirmed live:
-- with the unbind, only the tray-safe close remains.
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window (tray-safe)", "omarchy-close-window")

-- Laptop LCD while docked — see _meta/Hermes/studio-dock-lights.md
o.bind("SUPER + CTRL + DELETE", "Toggle laptop display",
  home .. "/.local/bin/omarchy-hyprland-monitor-internal toggle")

-- ── CleanShot-style captures ─────────────────────────────────────────────────
-- Physical Caps sends Ctrl because of kb_options = ctrl:swapcaps (input.lua).
-- NOTE: satty and wf-recorder/wl-screenrec are retired by Quattro. Verify the
-- omarchy-capture-* commands still exist and behave the same before trusting these.
-- Quattro's packaged defaults claim SUPER+CTRL+1..9 for bar panels
-- (default/hypr/bindings/utilities.lua, spelled as `code:10`..`code:18`).
-- Captures win, so unbind all nine before re-declaring the capture keys.
hl.unbind("SUPER + CTRL + code:10")
hl.unbind("SUPER + CTRL + code:11")
hl.unbind("SUPER + CTRL + code:12")
hl.unbind("SUPER + CTRL + code:13")
hl.unbind("SUPER + CTRL + code:14")
hl.unbind("SUPER + CTRL + code:15")
hl.unbind("SUPER + CTRL + code:16")
hl.unbind("SUPER + CTRL + code:17")
hl.unbind("SUPER + CTRL + code:18")
o.bind("SUPER + CTRL + 1", "Capture area", "omarchy-capture-screenshot region")
o.bind("SUPER + CTRL + 2", "Capture OCR", "omarchy-capture-text")
o.bind("SUPER + CTRL + 3", "Capture fullscreen", "omarchy-capture-screenshot fullscreen")
o.bind("SUPER + CTRL + 4", "Capture window", "omarchy-capture-screenshot windows")

-- ── Phone, agents, audio ─────────────────────────────────────────────────────
o.bind("SUPER + SHIFT + K", "Phone KDE Connect",
  [[uwsm-app -- sh -c 'kdeconnect-pair-help; uwsm-app -- kdeconnect-app']])
o.bind("SUPER + SHIFT + J", "Hermes Mac (SSH)", { launch = "kitty --session none -e hermes-mac ssh" })
o.bind("SUPER + SHIFT + ALT + J", "Hermes logs", { launch = "kitty --session none -e hermes-mac logs" })
o.bind("SUPER + ALT + O", "Switch audio output", "omarchy-audio-output-switch")

-- ── Hyprspace overview ───────────────────────────────────────────────────────
-- Routed through `hyprctl dispatch` on purpose: hyprpm loads Hyprspace after the
-- config is parsed, so naming overview:toggle as a dispatcher directly would fail
-- at startup and drop Hyprland into safe mode.
o.bind("SUPER + GRAVE", "Workspace overview", "hyprctl dispatch overview:toggle")
o.bind("SUPER + SHIFT + GRAVE", "Workspace overview (all monitors)", "hyprctl dispatch overview:toggle all")
o.bind("SUPER + SHIFT + V", "Workspace overview", "hyprctl dispatch overview:toggle")

-- ── Locked bindings (work while the session is locked / input inhibited) ─────
-- Quattro's own defaults already bind the lid switch to omarchy-system-lid-close
-- and omarchy-hyprland-monitor-clamshell, which is MORE capable than these two
-- raw dpms calls. Try the stock behaviour first and only re-enable these if
-- clamshell handling regresses on this ThinkPad.
-- o.bind("switch:on:Lid Switch", nil, "hyprctl dispatch dpms off", { locked = true })
-- o.bind("switch:off:Lid Switch", nil, "hyprctl dispatch dpms on", { locked = true })

-- Bedtime: blank all screens + lights, lid stays open (toggle).
o.bind("SUPER + SHIFT + CTRL + S", "Bedtime mode",
  home .. "/.local/bin/bedtime-mode toggle", { locked = true })

-- Added by omarchy-obsidian-capture
require("obsidian-capture")

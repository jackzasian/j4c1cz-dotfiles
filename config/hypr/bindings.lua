-- Ported from ~/.config/hypr/bindings.conf  (2026-08-11, DRAFT) — 52 bindings.
--
-- Syntax notes for reviewing this file:
--   bindd = SUPER SHIFT, X, Desc, exec, cmd   ->  o.bind("SUPER + SHIFT + X", "Desc", cmd)
--   bindl / bindld                            ->  o.bind(..., { locked = true })
--   unbind = MOD, KEY   +   rebind            ->  just re-declare o.bind(); user
--       files load after default.hypr.omarchy, so the later bind wins.
--       VERIFY: if a re-declared key double-fires instead of overriding, grab the
--       returned keybind object from the default and call :unbind() on it.
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
-- jackz actually seeing two terminal windows open on one press. Can't
-- unbind a packaged default (same limit as the SUPER+W saga above), so
-- instead: made kitty the system default terminal
-- (~/.config/xdg-terminals.list) and removed kitty.conf's global Zellij
-- shell override (nothing else needed it — see kitty.conf's own comment).
-- Quattro's single default binding now does exactly what we want: one
-- plain kitty window, no crossover.
-- $() needs a shell; exec dispatchers run through /bin/sh, so this is fine.
o.bind("SUPER + ALT + RETURN", "Terminal (Zellij, cwd)",
  [[uwsm-app -- kitty --session none -d "$(omarchy-cmd-terminal-cwd)" -e zellij]])
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
o.bind("SUPER + SHIFT + CTRL + L", "Save link to Obsidian", home .. "/.local/bin/obsidian-save-link")
o.bind("SUPER + SHIFT + CTRL + N", "Quick note → Inbox", home .. "/.local/bin/obsidian-save-note")
o.bind("SUPER + SHIFT + ALT + N", "Multiline note → Inbox", home .. "/.local/bin/obsidian-save-note --edit")
o.bind("SUPER + SHIFT + CTRL + M", "Post note → j4c1cz.com", home .. "/.local/bin/obsidian-post-note")
o.bind("SUPER + SHIFT + CTRL + COMMA", "Note destination…", home .. "/.local/bin/obsidian-note-dest")
o.bind("SUPER + SHIFT + T", "Tasks (Obsidian)", { focus = "^obsidian$", launch = "obsidian" })

-- Quattro's default binds Omawrite to SUPER+SHIFT+W, which we need for
-- WeChat instead (see Window management overrides below). Can't unbind the
-- packaged default, so both technically still fire on that key — this gives
-- Omawrite a clean second key if you want to actually use it.
o.bind("SUPER + SHIFT + CTRL + W", "Omawrite", { launch = "omawrite" })

-- CONFLICT carried over from bindings.conf: SUPER+SHIFT+ALT+L was bound twice —
-- once to obsidian-open-links-recent (line 17) and again to `j4c1cz clip`
-- (line 98). In hyprlang the last one won, so only "Publish link" was reachable.
-- Preserving that behaviour; the shadowed binding is kept here commented so you
-- can give it its own key if you actually wanted it.
-- o.bind("SUPER + SHIFT + ALT + L", "Open recent links", home .. "/.local/bin/obsidian-open-links-recent")
o.bind("SUPER + SHIFT + ALT + L", "Publish link to j4c1cz", home .. "/.local/bin/j4c1cz clip")

-- ── Web apps ─────────────────────────────────────────────────────────────────
o.bind("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
o.bind("SUPER + SHIFT + E", "Email", { webapp = "https://app.hey.com" })
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
-- SUPER+W is NOT clean, and can't be made clean: Quattro's packaged default
-- (`o.bind("SUPER + W", "Close window", hl.dsp.window.close())` in
-- default/hypr/bindings/tiling.lua) re-declaring the same combo doesn't
-- unbind it — Hyprland's Lua bind API only lets you :unbind() a keybind
-- object you captured at declare time, and that one lives in a read-only
-- packaged file. Confirmed via `hyprctl binds -j`: both are live
-- simultaneously. So pressing SUPER+W fires BOTH the hard close above AND
-- the tray-safe close below — in practice this may still hard-quit WeChat
-- despite the intent. If that turns out to actually happen, the only real
-- fix is picking a different key for the tray-safe close instead.
o.bind("SUPER + W", "Close window (tray-safe)", "omarchy-close-window")

-- Laptop LCD while docked — see _meta/Hermes/studio-dock-lights.md
o.bind("SUPER + CTRL + DELETE", "Toggle laptop display",
  home .. "/.local/bin/omarchy-hyprland-monitor-internal toggle")

-- ── CleanShot-style captures ─────────────────────────────────────────────────
-- Physical Caps sends Ctrl because of kb_options = ctrl:swapcaps (input.lua).
-- NOTE: satty and wf-recorder/wl-screenrec are retired by Quattro. Verify the
-- omarchy-capture-* commands still exist and behave the same before trusting these.
o.bind("SUPER + CTRL + 1", "Capture area", "omarchy-capture-screenshot region")
o.bind("SUPER + CTRL + 2", "Capture OCR", "omarchy-capture-text-extraction")
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
o.bind("SUPER + code:41", "Workspace overview", "hyprctl dispatch overview:toggle")
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

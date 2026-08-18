-- Managed by omarchy-obsidian-capture. Keybindings for the capture CLI.
-- Loaded from ~/.config/bindings.lua via: require("obsidian-capture")
local home = os.getenv("HOME")
local capture = home .. "/.local/bin/obsidian-capture"

o.bind("SUPER + SHIFT + CTRL + L", "Save link to Obsidian", capture .. " link")
o.bind("SUPER + SHIFT + CTRL + N", "Quick note → Inbox", capture .. " note")
o.bind("SUPER + SHIFT + ALT + N", "Multiline note → Inbox", capture .. " edit")
o.bind("SUPER + SHIFT + CTRL + M", "Post note → j4c1cz.com", capture .. " web")
o.bind("SUPER + SHIFT + CTRL + COMMA", "Note destination…", capture .. " dest")
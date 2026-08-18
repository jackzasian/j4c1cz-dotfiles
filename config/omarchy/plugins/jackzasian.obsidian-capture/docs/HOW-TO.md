# HOW-TO

Day-to-day usage of `obsidian-capture`.

## Daily use

1. Copy a link anywhere.
2. `Super+Shift+Ctrl+L` — pick a topic (`cycling` / `study` / `tech` / `projects` / `misc` / `inbox`).
3. See what's new: open the `Obsidian → Open Recent Links` menu item.

Zen-only bookmarks: wait for Sunday sync, or run `obsidian-capture sync`.

Sunday 20:15: `Links/` is pushed to the vault's git remote (also runs after
every Zen sync via the unit's `ExecStartPost`).

## All commands

```bash
# Link capture
obsidian-capture link https://example.com/x
obsidian-capture link --topic study "https://example.com/x" --title "Custom"
# no URL → clipboard, then a menu prompt, then a topic picker

# Notes
obsidian-capture note "buy more gels"          # → Inbox
obsidian-capture note --title "Todo" "pick up bike" --open
obsidian-capture edit                          # multiline zenity editor → Inbox
obsidian-capture edit "start with this draft"
obsidian-capture web "short public note"       # → j4c1cz.com/notes
obsidian-capture web --url https://… "see this"
obsidian-capture dest "note then choose where" # inbox | site | both

# Utilities
obsidian-capture recent    # open links-recent in Obsidian
obsidian-capture sync      # Zen bookmarks → links-inbox
obsidian-capture push      # git add/commit/push Links/
```

## Legacy aliases

If you're used to the old names, they still work:

| Old | Now routes to |
|-----|---------------|
| `obsidian-save-link` | `obsidian-capture link` |
| `obsidian-save-note` | `obsidian-capture note` |
| `obsidian-save-note-edit` | `obsidian-capture edit` |
| `obsidian-post-note` | `obsidian-capture web` |
| `obsidian-note-dest` | `obsidian-capture dest` |

## No Omarchy / no Wayland

The interactive prompts use the Omarchy menu. In a headless or non-Omarchy
environment, always pass the URL/text as arguments or pipe on stdin:

```bash
echo "https://example.com" | obsidian-capture link --topic misc
printf 'note text' | obsidian-capture note
```

## Troubleshooting

- **"Links folder missing"** — set `OBSIDIAN_VAULT_DIR` / `OBSIDIAN_LINKS_DIR`
  or create the folder structure (see README).
- **Menu entries don't appear** — the omarchy menu hot-reloads
  `~/.config/omarchy/extensions/omarchy-menu.jsonc` on save; reopen Super+Space.
- **Keybindings don't work after an update** — re-run
  `~/Projects/omarchy-obsidian-capture/install.sh` and `hyprctl reload`
  (or `omarchy plugin update jackzasian.obsidian-capture`).
- **`sync` says no profile** — point `OBSIDIAN_ZEN_ROOT` at the directory that
  contains `*/places.sqlite`.
- **`web` fails with "no NOTES_TOKEN"** — configure
  `~/.config/j4c1cz/notes.env` (or set `NOTES_TOKEN` in the environment).
- **`push` is stuck** — check `~/.cache/obsidian-links-github-push.log`.
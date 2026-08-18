# Architecture

`omarchy-obsidian-capture` is a single Python CLI plus Omarchy plugin glue.

```
manifest.json   → omarchy plugin metadata (schemaVersion 1, kind: service)
Service.qml     → runs install.sh --plugin once at shell start (idempotent)
install.sh      → symlinks, menu merge, keybindings hook, optional timers
bin/
  obsidian-capture        entry point (resolves its own symlink)
  obsidian_capture/       shared Python package
    cli.py                argparse subcommand dispatch
    config.py             env-driven vault/link/inbox/zen paths
    urls.py               URL normalize/extract/title, tracking-param strip
    link.py               link capture → topic file + recent feed
    notes.py              note/edit/web/dest capture + publish
    recent.py             newest-first links-recent.md feed (cap 50)
    sync.py               Zen Browser bookmarks → inbox + recent
    misc.py               open-recent + Links/ git push
  wrappers/               legacy aliases (obsidian-save-link, …)
menu/obsidian-menu.jsonc  fragment merged into the Omarchy menu
hypr/obsidian-capture.lua keybinding fragment (require'd from bindings.lua)
scripts/merge_menu.py     JSONC-safe menu merge (preserves user entries)
systemd/                 optional zen-sync + push timers
```

## Data flow

### Capture a link

```
keybind / menu action
  → obsidian-capture link
  → resolve URL (argv → clipboard mime-check → omarchy-menu input)
  → normalize (strip utm_/tracking params, rstrip path)
  → dedupe against every Links/*.md
  → topic picker (omarchy-menu select) unless --topic
  → title = --title or page <title> (2s timeout, host fallback)
  → append under "## Captured" (or "## To Sort" for inbox)
  → prepend links-recent.md feed (cap 50, URL-deduped)
  → notify-send
```

### Capture a note

```
note / edit / web / dest
  → body = args → stdin → omarchy-menu input (edit uses zenity)
  → Inbox: unique <timestamp>-<slug>.md with frontmatter
  → site: notes API POST (fallback Upstash), ≤500 chars
  → dest: omarchy-menu select inbox | site | both
```

### Zen sync (optional)

`sync` reads the newest Zen `places.sqlite` (copy to a temp dir, WAL-safe),
de-dupes against the whole `Links/` tree, appends a dated `## Zen sync` block
to `links-inbox.md`, and feeds the recent feed with the `zen` tag.

### Push (optional)

`push` stages only `Links/` (plus the Hermes note if present) and commits +
pushes to the vault's remote. Uses `flock` to avoid overlapping runs, enables
the omarchy proxy if present, and logs to `~/.cache/obsidian-links-github-push.log`.

## Plugin wiring (idempotent)

`install.sh --plugin` (invoked by `Service.qml` at shell start) does three
cheap, repeatable jobs and exits quickly once done:

1. Symlink `bin/obsidian-capture` and the legacy wrappers into `~/.local/bin/`.
2. Merge `menu/obsidian-menu.jsonc` into
   `~/.config/omarchy/extensions/omarchy-menu.jsonc`
   (JSONC-safe; user entries preserved, plugin wins per entry ID).
3. Copy `hypr/obsidian-capture.lua` to `~/.config/obsidian-capture.lua` and
   append one `require("obsidian-capture")` to `~/.config/hypr/bindings.lua`.

Step 3 relies on Omarchy's Lua module path (`~/.config/?.lua`) and the fact
that the last `o.bind()` for a combo wins, so the fragment safely overrides any
older duplicate bindings. The fragment defines its own `local home` because
`home` is a local in `bindings.lua` while `o` is a global from the helpers.
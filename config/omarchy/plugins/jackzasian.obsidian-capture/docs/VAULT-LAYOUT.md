# Vault layout

`obsidian-capture` expects (and creates) this structure inside the vault
(default `~/Obsidian/J4c1c`, override with `OBSIDIAN_VAULT_DIR`):

```
Obsidian/<Vault>/
├── Links/                     ← link capture + recent feed
│   ├── links-cycling.md       topic files (## Captured section)
│   ├── links-study.md
│   ├── links-tech.md
│   ├── links-projects.md
│   ├── links-misc.md
│   ├── links-inbox.md         (## To Sort section for un-topic'd links)
│   ├── links-recent.md        newest-first feed, cap 50, created on first save
│   └── 202507291200-links-moc.md   (optional MOC, untouched)
└── Inbox/                     ← note + edit targets
    └── <YYYYMMDDHHMM>-<slug>.md   frontmatter: title, created, tags:[inbox], type:note
```

## File conventions

- Topic files use a `## Captured` heading; `links-inbox.md` uses `## To Sort`.
- The recent feed stores one line per entry:

  ```
  - `2026-08-17` · misc · [Title](https://…)
  ```

  Tags are the topic name, or `zen` for Zen-synced links.
- Entries are deduplicated by normalized URL (host lowercased, tracking params
  stripped, path trailing slash removed) across all `Links/*.md`.

## Configuring a different vault

```bash
export OBSIDIAN_VAULT_DIR="$HOME/Obsidian/OtherVault"
export OBSIDIAN_LINKS_DIR="$HOME/Obsidian/OtherVault/Links"
export OBSIDIAN_INBOX_DIR="$HOME/Obsidian/OtherVault/Inbox"
export OBSIDIAN_VAULT_NAME="OtherVault"
```

The topic→file map is fixed (`cycling`, `study`, `tech`, `projects`, `misc`,
`inbox`) to match the feed and MOC conventions.
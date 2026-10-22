# Omarchy plugin maintenance — 2026-10-22

This records four updates and ten additions adapted to Jack's desktop. Popularity and workflow choices are recorded in [catalog-review.md](catalog-review.md). Exact source commits, local patches and validation results are in [plugins.lock.json](plugins.lock.json). Security findings and fixes are in [security-review.md](security-review.md).

The bar now keeps Tools/workspaces, calendar/tasks, notification history, network, audio and power visible. Occasional panels open through the existing OmaCast launcher with **Super+Ctrl+M**. See the [keyboard bar guide](keyboard-bar/guide.md) and [source recipe](keyboard-bar/README.md). TaskNotes remains the task source of truth, existing Syncthing sharing and KDE Connect pairings are reused, and calendar events come from the existing private ICS feed. Task completion and editing open native Obsidian. The feed URL, credentials, task contents, screenshots and runtime authentication files are excluded.

## Updated plugins

| Plugin | Change | Preserved behavior |
| --- | --- | --- |
| Speaker EQ | 3.0.0 → 3.1.0; Git origin repaired | Existing audio backend, reconnect patch, profiles and output switcher |
| Oma Cast | Merged upstream `90efedd` into fork commit `c3f2265` | Hidden-window focus release; explicit handoff to the default Codex agent |
| GitHub | 0.2.2 → 0.3.0, commit `6f361a4` | `MISE_QUIET=1`; links open in the existing browser |
| Keystroke | 1.3.0 → 1.5.1, commit `b7a10ca` | Search-only opening; disabled AI, clipboard, extensions and Smart Match; confirmation guards |

EQ and Oma Cast are on their published `jackz/plugin-update-20261022` branches. GitHub and Keystroke use upstream commits plus the exact patches in `patches/`.

## Added plugins

| Plugin | Version | Desktop adaptation |
| --- | --- | --- |
| Notification Center | 1.2.0 | Three days, at most 500 entries; hover previews hidden |
| Activity Monitor | 2.1.1 | One process/resource monitor; privileged power sampling disabled |
| Syncshell | 0.2.3 | Existing managed Syncthing; core rebuilt with Go 1.27.3 |
| OmaConnect | 1.5.0 | Existing phone pairing; remote commands, SMS and media controls hidden; security fork |
| Omaplug | 1.6.6 | Manual update review; compressed catalog uses existing RelayPilot proxy |
| OmaTaskNotes | 0.2.2 | Read-only Today view; native Obsidian edits; preserves Base view ordering |
| OmaCal | 1.2.1 | Existing private feed; duplicate reminders and external account sync disabled |
| hyprmoncfg panel | 2.10.0 | Uses existing backend; stale daemon restarted with display layout preserved |
| Screen Time | 1.6.2 | Compact icon and local activity history |
| Backup History | 0.3.0 | Four weeks of local history; complements the existing backup dashboard |

The adjacent `shell.json` snapshot contains the final bar configuration. `syncshell-settings.toml` records the nonsecret integration settings. Keep private calendar configuration and existing Keystroke settings on the machine; the lock file records their relevant privacy switches without copying credentials.

## Restore or update

Work from a clean checkout at each commit in the lock file. Preserve existing plugin changes before replacing a live checkout. Apply the GitHub, Keystroke and Omaplug patches to their matching pinned commits with `git apply --check`, then `git apply`. The Activity Monitor patch changes test fixtures only; it fixes synthetic PID collisions inside sandbox namespaces and is not a runtime customization.

Oma Cast uses the repository's `plugin/` directory and its existing development link, rather than a plugin manifest at the repository root. Keep its CLI link to `bin/oma-cast`.

Run the plugin's relevant checks before enabling it. Review updates individually so upstream changes do not erase local guards or replace security forks. Omaplug's patch reuses this machine's existing RelayPilot port7897 when desktop processes inherit no HTTPS proxy. Adapt that local fallback when restoring on another machine; it changes no proxy service settings.

## Rebuild the Syncshell core

Use Syncshell source commit `45b25c88015c4b482b401b100c4fc5e39f9b96b6` and a task-local Go 1.27.3 toolchain. The official Linux amd64 archive has SHA256 `65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40`, published at [go.dev/dl](https://go.dev/dl/). Verify that digest and scan the downloaded toolchain with current signatures before executing it.

With `task_go` pointing to that toolchain's `go/bin/go` and `syncshell_src` pointing to the pinned source checkout:

```bash
cd "$syncshell_src/core"
GOTOOLCHAIN=local GOENV=off GOPROXY=https://proxy.golang.org \
  GOSUMDB=sum.golang.org "$task_go" mod download
GOTOOLCHAIN=local GOENV=off CGO_ENABLED=1 \
  "$task_go" test -mod=readonly -race -count=1 ./...
GOTOOLCHAIN=local GOENV=off GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
  "$task_go" build -mod=readonly -trimpath -buildvcs=false \
  -ldflags=-buildid= -o ../bin/x86_64/syncshell-core ./cmd/syncshell-core
sha256sum ../bin/x86_64/syncshell-core
"$task_go" version -m ../bin/x86_64/syncshell-core
```

The reviewed binary digest is `71c7f0f1fd46e9debad269e94455b291c97cc4f7c0eba53c1aa7d9be10424666`. Record a new digest if the compiler, source or flags change. The upstream bundled checksum file describes upstream's binary, so a local security rebuild intentionally differs from it. This directory stores the source recipe and digest, not toolchain archives or compiled binaries.

## Validation

EQ's 332 unit tests and Oma Cast's 88 Node tests passed. GitHub helper/cache/QML checks and Keystroke's actual-palette privacy regression checks passed. Notification Center, Activity Monitor, Screen Time, monitor controls and Backup History suites passed; the Activity Monitor fixture patch and unavailable namespace cases are recorded in the lock file. Syncshell passed race tests across all eight core packages using Go 1.27.3.

Live checks covered TaskNotes' Today view, the existing calendar feed, the notification watcher, Activity Monitor and five Oma Cast toggles; the slowest toggle was 89 ms. OmaCal's supported runtime suite passed across five time zones; a separate Node26 Casablanca assertion differs because Node's ICU data is older than system tzdata. An independent system-zoneinfo check passed480 round trips. Omaplug loaded all5856 catalog entries in the live desktop after its compression/proxy fix.

Live Syncthing, paired-phone and Screen Time checks passed. Restarting the installed hyprmoncfg1.25.1 daemon repaired its editor IPC while retaining the active Studio Display profile and both screens’ geometry. Backup History correctly exposed the latest failed job; its last recorded successful backup is October12, and the latest job ended with rsync I/O timeout(code30). The backup service itself was not changed.

One older shell instance crashed when the hyprmoncfg daemon closed its Unix socket during the22:20 restart, then recovered automatically. The core shows a QtNetwork/socket callback reaching QObject::deleteLater; the exact caller is unsymbolized, so this is not attributed to a specific plugin. The final22:27 shell restart, display-panel rendering and catalog loads succeeded, with no subsequent core recorded during verification.

Detailed local evidence is retained under `~/.local/state/omarchy-plugin-upgrade/20261022-213736/`. No full system upgrade ran, and security-scan permissions or the held unattended updater were not changed.

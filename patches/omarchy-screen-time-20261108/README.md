# Screen-time Service.qml — Session Status Repair

**Date:** 2026-11-08 ~13:30 UTC
**Status:** Implementation complete, all 355 tests pass
**Parent activation:** Pending unlocked shell restart. Manifest has keepLoaded:true; plugin reload preserves the existing service.

## Problem

`Service.qml` called `shell.serviceFor("omarchy.lock")` and `shell.serviceFor("omarchy.idle")` — both always return `null` because `PluginShellApi.serviceFor()` is ownership-scoped (`pluginServiceFor` checks `pluginOwnsTarget`). The shell's separate first-party proxy allowlist (`pluginFirstPartyServiceFor`) includes `omarchy.idle` but excludes `omarchy.lock` (authentication service). After 10 seconds of futile retries, a warning was logged and the plugin fell back to its persistent watcher — which was already the correct implementation.

## Fix

Removed the impossible `serviceFor()` path entirely. The supported fallbacks are now the primary and only path:

| State | Source | Mechanism |
|-------|--------|-----------|
| Lock | `omarchy-shell lock isLocked` IPC | One persistent bash watcher process, change-only output, exits on parent death |
| Screensaver | In-process toplevel scan | Zero subprocess, scans for `org.omarchy.screensaver` appId every 10s |

Both are read-only, sandbox-safe, and require no service ownership.

### Changes to `Service.qml`

- **Removed:** `lockService`, `idleService` properties, `refreshShellServices()`, `onShellChanged` handler, `serviceLookupTimer`, `serviceLookupWarned`, both `Connections` blocks for lock/idle services
- **Changed:** `sessionStateWatcher` now has `running: root.ready` (starts immediately, no 10s delay)
- **Changed:** `watcherSupervisorTimer` now has `running: root.ready` (always supervises, not gated on `!lockService`)
- **Changed:** `screensaverScanTimer` now has `running: root.ready` (always active, not gated on `!idleService`)
- **Kept:** All pause/resume state machine logic (`setSessionLocked`, `setScreensaverActive`, `scheduleResume`, `applyResume`, `cancelResume`) — unchanged and well-designed

### Changes to `tests/service.test.js`

- Removed assertions for `serviceFor("omarchy.lock")` / `serviceFor("omarchy.idle")`
- Removed test for "services unavailable after 10s" warning
- Renamed fallback test to "lock watcher uses supported IPC and starts with ready"
- Added test asserting no unsupported `serviceFor` calls remain
- Updated supervisor/scan timer assertions to match unconditional `running: root.ready`

## Files changed

| File | Action |
|------|--------|
| `~/.config/omarchy/plugins/agx.screen-time/qml/Service.qml` | Modified |
| `~/.config/omarchy/plugins/agx.screen-time/tests/service.test.js` | Modified |

## Backups

- `screen-time-fix/backup/Service.qml.orig` — original Service.qml
- `screen-time-fix/backup/service.test.js.orig` — original service.test.js

## Test results

```
355 tests, 355 pass, 0 fail (full suite)
14 tests, 14 pass, 0 fail (service.test.js alone)
```

## What was NOT changed

- `BarWidget.qml` — parent installed shared IPC ownership there
- `shell.json` — not touched
- Stay Awake — left enabled (per audit)
- Package files — no new dependencies
- Shell source (`/usr/share/omarchy/`) — read-only, not edited

## Activation verified by parent

The shell journal shows plugin reloads, but the manifest has `keepLoaded: true`: the existing service and its 13:25 watcher remain alive. The edited Service.qml has NOT replaced the running service. The session is securely locked; do not restart the shell until it is unlocked. After unlock, run `omarchy restart shell`, check for a new watcher, and inspect only the new shell PID journal for the old service-access warning. Preserve Stay Awake.

Parent reran the full suite: 355 pass, zero failures. Actual lock/unlock accounting after activation remains untested; polling retains approximately ten-second detection granularity. This patch removes impossible private lookups and uses the existing bounded read-only IPC path; it does not make transitions instantaneous.

Apply the maintained delta only against its original local baseline, preserving other edits. The full original files remain in the task scratch screen-time-fix/backup directory.

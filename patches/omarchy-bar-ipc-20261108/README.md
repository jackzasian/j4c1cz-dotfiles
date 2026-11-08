# Omarchy bar / IPC handoff — 2026-11-08

**Ready for parent-coordinated activation; not installed.** No live config, packaged file, service, monitor, Stay Awake flag, Fcitx file, audit note, or screen-time Service.qml/tests was changed. No shell reload/restart was requested. Publishing remains with the parent. This scratch directory is not a Git repository.

## Exact changes

- `shell.json`: Desktop Tools `type: command` becomes `type: qml`. Its existing ID, icon, tooltip and exact click command remain. Two stock IDs become supported `jackz.indicators` and `jackz.system-update` clones; the corresponding stock plugins are disabled. All sections, entries, settings, services and other disabled IDs remain.
- `bar/modules/desktop-tools.qml`: 19-line WidgetButton with writable injected properties. This avoids the installed bar's broken CustomCommandModule while retaining the stock bar and plugin service access.
- `bar/ipc/`: Registry singleton, IpcLease, OwnedIpcHandler and qmldir. One live owner per IPC target. All instances keep rendering/clicking; deleting the owner transfers the target to the next instance. Legacy IPC keeps first-instance semantics; normal shell summon/toggle still uses the stock bar's focused-monitor routing. This does not turn legacy IPC into focused-monitor routing.
- 13 existing plugin entry points replace IpcHandler with OwnedIpcHandler and add a relative import. All method bodies remain intact, including widget broadcasts and specialized methods.
- 8 existing panels gate their inherited packaged Panel handler with an IpcLease. Panels already using `manageIpc: false` retain their custom handlers.
- Two stock widget-only clones (Indicators.qml, SystemUpdate.qml and manifests). Indicators loads unchanged implementations directly from `/usr/share/omarchy/shell/plugins/bar/indicators/`; no copied indicator tree or full bar clone. Its `clonedFrom` metadata preserves the installed host's supported idle/nightlight/notifications proxy access, including Stay Awake.

`files.json` lists all 31 destination files; `changes.patch` is the exact review diff. `backup/` holds byte-for-byte pre-change copies of every existing target (22 files); new targets have null baseline hashes. `staged/` is the install payload. Only screen-time's BarWidget.qml IPC declaration changes, not Kimi's Service.qml/tests.

## Evidence and checks

Run from this directory:

```
python test.py
python compile.py
python apply.py
```

- `test.py` instantiates the actual installed Ui/Panel twice: original duplicate-target warning reproduced, leased pair clean.
- Extracts and executes actual installed Bar.injectProps and CustomCommandModule: original readonly moduleName warning reproduced. Replacement injects settings and dispatches the exact Desktop Tools command to a stub (does not launch Desktop Tools during testing).
- Real isolated Quickshell IPC calls: two OwnedIpcHandler instances, one owner, ping returns pong; retire destroys owner, subsequent ping still returns pong. No duplicate or IPC method-export warnings.
- `compile.py`: all 27 changed/new QML files compile against the installed Commons/Ui and actual plugin dependency files. This only compiles components; it does not instantiate plugin services or windows. A host-portal app-ID warning can occur for the separate test process.
- Configuration comparison: same entry counts and settings in every section, only the three described entry edits; plugin service list unchanged.
- `apply.py` without flags is read-only. It passes against the current packaged sources and every target baseline hash.

Logs retain red and green evidence. Tests use separate, bounded Quickshell processes, not the live shell. Live two-monitor rendering, real mouse activation, focused-monitor popups and reload/hotplug behavior remain for the coordinated activation check.

## Activation and rollback

Parent must coordinate the batch: saving user plugins can hot reload before the rest of the batch lands. This task deliberately did not run `apply.py --apply`. Run it only in the parent's controlled activation window. It checks all target hashes and package hashes before writing; any concurrent edit or package update refuses installation. It writes shell.json last and performs no rescan/reload/restart itself. Retain backups before activation. If the guard refuses, merge that exact delta and retest; do not bypass it or blindly regenerate snapshots.

Rollback in the same controlled window: restore the 22 existing files from `backup/` and remove only the 9 new paths marked `sha256_before: null` in files.json. Preserve any post-install edits by reviewing before restoration. Parent verifies both bars, Desktop Tools, widget IPC, and Stay Awake status after its activation.

## Pending 4.5 / Qt upgrade

Read published source (not installed):

- https://github.com/omacom/omarchy/blob/v4.5.0/shell/plugins/bar/Bar.qml — CustomCommandModule at lines 3159–3165 makes both moduleName and settings writable. The Desktop Tools workaround is unnecessary after that fix is installed and verified; restore its original command type and remove the local component then.
- https://github.com/omacom/omarchy/blob/v4.5.0/shell/Ui/Panel.qml — uses ShellIpc instead of IpcHandler.
- https://github.com/omacom/omarchy/blob/v4.5.0/shell/Commons/ShellIpc.qml and IpcRegistry.qml — registers handlers with a shell socket registry but retains native IpcHandler registration; does not gate duplicate native targets. Do not assume duplicate warnings are fixed by upgrading. These files were inspected, not executed.

This source inspection is of upstream v4.5.0, not proof of exact 4.5.0-3 package contents. No package upgrade was applied. The activation guard rejects a changed host: re-evaluate after upgrade rather than installing stale widget clones. Rebase clones onto upgraded stock widgets (new ShellIpc/socket behavior), remove the command workaround, and rerun tests under the upgraded Qt. Third-party plugin updates may overwrite local IPC edits; review/reapply the small diff or remove it when upstream deduplicates targets. Package-backed indicator paths also need rechecking if upstream moves them.

## Publication scope

Parent can publish README, prepare/apply/test/compile scripts, source/, files.json, package-context.json and changes.patch as maintained task source. Exclude backup/, staged/, runtime dependency copies, logs and fetched upstream snapshots; they are ignored. No unrelated working changes were committed or pushed here.

## Parent activation

Installed on 2026-11-08 at 13:25 UTC after review, fresh baseline guards and repeat tests. Shell restarted successfully; both eDP-1 and DP-1 expose omarchy-bar layers, Hyprland configerrors empty, Stay Awake preserved. New shell PID 109555 has no duplicate-handler or readonly-property warnings. Screen-time service work remains separate. Original backup/staged payload stays in the task scratch directory; this maintained copy stores recipes and diff only.

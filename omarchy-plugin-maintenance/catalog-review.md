# Catalog review — 2026-10-22

The original link uses [Most viewed](https://plugins.omarchy.org/index.html?sort=views&page=3#catalog), which measures attention to listings. For install interest, the store provides [Most copied](https://plugins.omarchy.org/index.html?sort=copies#catalog). Its `copies` field records install-command copy events. These are **not verified downloads, successful installations or unique users**. The engagement code uses a session repeat guard for copy events.

This review uses the cached October 22 snapshot: catalog generation `2026-10-22T13:01:26.024Z`, containing 5,856 listings, joined to the cached store statistics by plugin ID. Counts below are that snapshot’s totals. The statistics contain additional IDs, so ranking includes only plugins present in the catalog. No catalog or statistics were fetched again for this document.

## The 20 most-copied listings

| Rank | Plugin | Command copies | Jack’s decision |
| ---: | --- | ---: | --- |
| 1 | [hyprmoncfg: Multi-Monitor Manager for Omarchy](https://github.com/crmne/omarchy-hyprmoncfg) | 11,085 | Selected: docking controls using the existing monitor backend. |
| 2 | [Plugin Manager (Omaplug)](https://github.com/fross100/omaplug) | 10,701 | Selected: review updates manually and preserve local changes. |
| 3 | [Lock Screen Explorer](https://github.com/SirJul1337/omarchy-lock-explorer) | 8,655 | Deferred: appearance choice; no current lock-screen need. |
| 4 | [Radio Atlas](https://github.com/AksharP5/omarchy-radio-atlas) | 6,528 | Deferred: useful for radio listening; no current workflow requirement. |
| 5 | [OmaSettings](https://github.com/twiking/omasettings) | 5,824 | Deferred: broad settings overlap with an already customized desktop. |
| 6 | [Notification Center](https://github.com/jankeesvw/omarchy-notification-center) | 5,715 | Selected: recover missed agent and security notifications. |
| 7 | [Omaland](https://github.com/bobby-nicholas/omaland) | 5,544 | Deferred: desktop appearance work can be considered separately. |
| 8 | [Omarchy Power Manager](https://github.com/onlyVishesh/omarchy-power-manager) | 5,029 | Deferred: existing charge-limit and power-profile automation covers this. |
| 9 | [Omamail](https://github.com/huacnlee/omamail) | 4,102 | Deferred: would introduce a separate mail workflow. |
| 10 | [AI Usage](https://github.com/akitaonrails/ai-usagebar) | 3,821 | Conditional: first identify a quota gap in the existing Agents panel. |
| 11 | [Dock](https://github.com/rosakodu/omarchy-dock) | 3,475 | Deferred: existing bar and workspace controls are sufficient. |
| 12 | [Navbar Cat](https://github.com/yeehahboogie/omarchy-navbar-cat) | 3,329 | Deferred: optional decoration. |
| 13 | [System Monitor](https://github.com/Harshith292002/omarchy-system-monitor) | 2,959 | Skipped: Activity Monitor fills the chosen resource-monitor role. |
| 14 | [OmaProton VPN](https://github.com/grichard99/omaproton-vpn) | 2,933 | Skipped: preserve RelayPilot as the network owner. |
| 15 | [Activity Monitor](https://github.com/stappmus/omarchy-activity-monitor) | 2,854 | Selected: inspect CPU, memory and competing agent processes. |
| 16 | [Screen Time](https://github.com/ax1g/quickshell-screentime-plugin) | 2,353 | Selected: inspect local activity patterns with a compact bar icon. |
| 17 | [Calendar](https://github.com/tmn73/omarchy-calendar) | 2,125 | Deferred: OmaCal reuses the existing private calendar feed. |
| 18 | [Okomart](https://github.com/brianblakely/omarchy-plugins) | 1,859 | Skipped: Omaplug is the chosen plugin manager. |
| 19 | [Dock (OmaDock)](https://github.com/thepathless/omadock) | 1,818 | Deferred: another dock adds little to the existing desktop. |
| 20 | [Themes Gallery](https://github.com/gotar/omarchy-themes) | 1,799 | Deferred: optional theme browsing. |

## Personalized shortlist

The selected set supports existing services and the way Jack already works:

1. **Notification Center and Activity Monitor:** retain missed agent/security notices and inspect concurrent agent resource use. Notification history is limited to three days; privileged process-power sampling remains disabled.
2. **[Syncshell](https://github.com/omarchy-QOL/syncshell), [OmaTaskNotes](https://github.com/Doghouse-Mike/omatasknotes) and [OmaCal](https://github.com/crmne/omacal):** reuse current vault synchronization, canonical TaskNotes files and the existing private calendar feed. Task edits and completion open native Obsidian. Feed addresses and credentials stay outside this record.
3. **hyprmoncfg, Omaplug and [Backup History](https://github.com/POSO-PocketSolutions/omarchy-backup-history):** make docking, reviewed plugin updates and existing local backup status easier to inspect.
4. **[OmaConnect](https://github.com/jitendradara12/omaconnect) and Screen Time:** use the existing phone pairing and show local activity history. Unneeded phone remote-command, SMS and media controls stay hidden.

Popularity was one input. The selected workflow plugins have different command-copy totals: Syncshell 647, OmaConnect 1,499, OmaCal 151, OmaTaskNotes 46 and Backup History 37. Their fit comes from existing sync, task, calendar, phone and backup arrangements. Source review and adaptations are recorded in [security-review.md](security-review.md); exact installed commits and local patches are in [plugins.lock.json](plugins.lock.json).

## Deferred overlaps

- **[Todoist](https://github.com/Aryan-Techie/omarchy-todoist):** a second task system would duplicate the canonical TaskNotes workflow.
- **Additional VPN controllers:** RelayPilot already owns network/proxy behavior. Keep that ownership clear.
- **[Exposé](https://github.com/kristofferR/omarchy-expose), extra docks and workspace replacements:** Hyprspace and the current bar already provide navigation.
- **[Omarchy Find](https://github.com/jesseburlamaque/omarchy-find) and more launchers:** Oma Cast and Keystroke were updated and adapted during this task.
- **AI Usage:** consider it if the existing Agents panel lacks a specific quota view; inspect its CLI credential access before adding it.
- **Spotify replacements, mail migrations and additional audio engines:** keep the working Spotify, mail and EQ arrangements unless a concrete missing feature emerges.
- **Cosmetic plugins:** lock-screen explorers, animated bar pets, motion wallpapers and theme galleries remain optional choices.

## Snapshot evidence

Local cached inputs: `/tmp/omarchy-plugin-catalog-20261022.json`, `/tmp/omarchy-plugin-stats-20261022.json`, `/tmp/omarchy-plugin-store-20261022.html` and `/tmp/omarchy-plugin-engagement-20261022.js`. Public source repositories are linked above. This record contains no private task titles, device identifiers, feed URLs or authentication data.

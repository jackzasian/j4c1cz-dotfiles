# Keyboard access and a smaller bar

The stock Omarchy bar stays in use. Tools/workspaces sit at the left, calendar/Today Tasks at the center, and tray/notifications/network/audio/power at the right. Mode indicators, alternate keyboard layout and update notices retain their conditional behavior.

**Super+Ctrl+M** and the Tools button both run the existing `oma-cast run omarchy:desktop-tools` command. Its internal submenu contains 24 actions. Super+Space retains the usual launcher. The menu definition is shared data in `~/.config/omarchy/extensions/omarchy-menu.jsonc`; the native `omarchy.menu` plugin remains disabled as before. The published fragment excludes unrelated existing private quicklinks.

## Maintained files

- `guide.md`: the user guide also saved in Obsidian at `Notes/Tech/Omarchy keyboard bar guide.md`.
- `bindings.lua`: only the new Tools binding and the Calendar override; merge into the existing user bindings, preserving unrelated shortcuts.
- `tools-widget.json`: the stock command module entry used at the left of the bar; it needs no helper process or custom QML.
- `desktop-tools-menu.json`: merge these entries into the existing menu extension.
- `patches.lock.json`: exact baseline and resulting file hashes for 20 local patches.
- `../shell.json`: the current complete configuration snapshot; review before replacing any newer local configuration.

## Plugin adaptations

The installed shell needs bar widgets mounted to summon their panels. Hidden widgets retain their entries and settings, but `menuOnly: true` collapses their dimensions and hides their buttons. Their roots, services and separate popup windows remain available. No replacement bar or broader service access was introduced. Monitor Layouts already supports this behavior through `showBarIcon: false`.

Fourteen existing user plugins have small presentation patches. Five stock plugins use supported user clones: `omarchy.weather`, `omarchy.bluetooth`, `omarchy.monitor`, `omarchy.tailscale` and `omarchy.media` become `jackz.*`. Create those with `omarchy plugin clone <source-id>` before applying their matching patch from the clone directory. The source package was `omarchy-settings 4.0.6-1`; each patch's baseline hash is recorded. Original Omarchy ids resolve to the enabled clone. The media clone also adds the standard open/close contract and a keyboard panel: Escape closes, Enter/Space toggles playback, and Left/Right selects the previous/next track.

OmaCal's unused Quick Add overlay declaration is removed for the current feed-only setup. Otherwise generic shell summons choose Quick Add instead of the calendar. The remaining service and bar-widget declarations let the named Calendar shortcut route to the focused monitor. Google/HEY connections and the Quick Add shortcut were already off.

Apply these patches **after** the earlier maintenance patches recorded in `../plugins.lock.json`. For each plugin, compare its current files with the baseline hashes, then run `patch --dry-run -p1 -i <absolute-patch-path>` in that plugin directory. Review differences after upstream/package updates; do not force a patch onto changed source. These local UI patches are not claimed to have been merged upstream. To restore an icon, set its inline `menuOnly` to false; Monitor Layouts uses `showBarIcon: true`.

## Validation and limits

All 20 patch artifacts were applied to temporary copies of their preserved starting files and reproduced the live source hashes. Plugin manifest validation and live QML loading passed. All 21 popup/menu targets mapped on the focused output on both monitors (42 checks); geometry shows ten visible widget slots per screen and no hidden tool taking bar space. Representative Syncthing, Screen Time and monitor panels displayed their existing live service data. The live OmaCast backend returned all 24 Tools actions; dispatching its Plugins action opened the panel and closed the launcher.

Hyprland reload/config checks passed; both new chords are registered once and screenshot shortcuts 1–4 remain. Physical keyboard input was not automated reliably: synthetic modifier/text events did not consistently target the launchers. An early test created an unintended `backup` ChatGPT chat and the user was informed. This is not recorded as a passing keyboard test. Activity Monitor's first Escape collapses the expanded view; the second closes it. Omaplug closed after its focus settled. No playback controls, pairing, sync configuration, monitor changes or plugin updates were executed during the access checks.

Independent review found no new command interpolation, privileges, service-scope bypass or remote upload in these changes. No Quickshell core was recorded after 22:40 during this task; an earlier crash notification remained visible from previous history.

The local rollback/evidence directory is `~/.local/state/omarchy-bar-simplify/20261022-224552/` (private). It contains original config/bindings/menu/widget files and private runtime captures; do not publish the directory. Restore only the required files and preserve newer unrelated changes.

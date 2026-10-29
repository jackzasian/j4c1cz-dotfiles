# Tibo Reset Forecast

Personal Omarchy widget using the public [codex-reset.com API](https://codex-reset.com/developers).
Inspired by [tibo-reset-watch](https://github.com/Chloride233/tibo-reset-watch) and
[codex-cache-meter](https://github.com/ivkiwi/codex-cache-meter). No upstream code copied.

The bar shows the community's 24-hour probability. A countdown appears only for
an active announcement with an explicit timestamp. These forecasts do not change
your account's limits. Hover shows confidence, freshness and the source; `*`
means stale/unavailable. Left click opens the source, right click checks the local
five-minute cache. No login credentials are sent to this service.

Install `home/.local/bin/omarchy-codex-reset-forecast` at `~/.local/bin/`, copy this
directory to `~/.config/omarchy/plugins/jackz.codex-reset`, and add the plugin ID to
the bar layout. Remove its layout entry to undo. The companion `jackz.agents`
chip uses the existing Omarchy account collector for your weekly reset countdown.

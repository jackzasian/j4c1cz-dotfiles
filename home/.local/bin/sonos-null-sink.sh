#!/bin/bash

# Ensure the Sonos Roam null sink exists with a friendly description.

# jackz fix 2026-08-16: found a 5-day-old orphaned duplicate sink today
# (module 536870917, traced back to a flaky boot on 2026-08-11 where a
# then-broken unit file made systemd retry this service 5x in 2 minutes —
# one retry's `grep -q` guard ran before the previous invocation's
# `pactl load-module` had finished registering, so both proceeded to create
# a sink). It broke omarchy-audio-output-switch: with two identical "Sonos
# Roam" entries back to back, cycling outputs looked stuck. The old guard
# only asked "does at least one exist" — never cleaned up extras. This does.
existing=$(pactl -f json list sinks 2>/dev/null | jq -r '.[] | select(.name == "sonos_stream") | "\(.index)\t\(.state)\t\(.owner_module)"')
count=$(grep -c . <<<"$existing" 2>/dev/null || echo 0)

if (( count > 1 )); then
	# Keep whichever is RUNNING (or just the first, if none are), unload the rest.
	keep_module=$(awk -F'\t' '$2=="RUNNING"{print $3; exit}' <<<"$existing")
	[[ -n "$keep_module" ]] || keep_module=$(awk -F'\t' 'NR==1{print $3}' <<<"$existing")
	while IFS=$'\t' read -r _idx _state module; do
		[[ "$module" == "$keep_module" ]] && continue
		pactl unload-module "$module" 2>/dev/null || true
	done <<<"$existing"
elif (( count == 0 )); then
	pactl load-module module-null-sink sink_name=sonos_stream 'sink_properties="device.description=\"Sonos Roam\""' >/dev/null
fi

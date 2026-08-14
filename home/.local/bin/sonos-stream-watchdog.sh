#!/bin/bash

# Sonos Roam stream watchdog:
# - ensure the null sink exists
# - ensure the HTTP stream server is running
# - when audio is routed to the Roam sink and the Roam is reachable, make it
#   play our stream (idempotent)
# - after the sink stays idle for 3 ticks (~3 min), stop the Roam so it can sleep

STATE=/tmp/sonos-idle-count

~/.local/bin/sonos-null-sink.sh

systemctl --user is-active --quiet sonos-http-stream.service || systemctl --user start sonos-http-stream.service

idx=$(pactl list short sinks 2>/dev/null | awk '$2=="sonos_stream"{print $1; exit}')
[[ -z "$idx" ]] && exit 0

if pactl list sink-inputs 2>/dev/null | grep -q "Sink: $idx"; then
	rm -f "$STATE"
	timeout 4 ~/.local/bin/sonos-stream-ctl start >/dev/null 2>&1
	exit 0
fi

count=$(cat "$STATE" 2>/dev/null || echo 0)
count=$((count + 1))
echo "$count" > "$STATE"
if (( count >= 3 )); then
	rm -f "$STATE"
	timeout 4 ~/.local/bin/sonos-stream-ctl stop >/dev/null 2>&1
fi

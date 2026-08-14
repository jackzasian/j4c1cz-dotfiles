#!/bin/bash

# Ensure the Sonos Roam null sink exists with a friendly description.

if ! pactl list short sinks 2>/dev/null | grep -q 'sonos_stream'; then
	pactl load-module module-null-sink sink_name=sonos_stream 'sink_properties="device.description=\"Sonos Roam\""' >/dev/null
fi

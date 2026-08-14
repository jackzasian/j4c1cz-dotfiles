#!/bin/bash
# Automated speaker diagnostic for ThinkPad X14 Gen 1
set -u

echo "=== ThinkPad X14 Speaker Test ==="
echo "Machine: $(cat /sys/class/dmi/id/product_name 2>/dev/null) $(cat /sys/class/dmi/id/product_version 2>/dev/null)"
echo "Kernel: $(uname -r)"
echo

echo "--- Kernel autoconfig ---"
journalctl -k --no-pager 2>/dev/null | grep -iE 'ALC257|speaker_outs' | tail -3

echo
echo "--- Running speaker init ---"
sudo /home/jackz/.local/bin/thinkpad-x14-speaker-init.sh

echo
echo "--- Default sink ---"
wpctl status 2>/dev/null | sed -n '/Settings/,/Video/p' | head -5
pactl set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo 2>/dev/null || true
wpctl set-volume 59 1.0 2>/dev/null || true
wpctl set-mute 59 0 2>/dev/null || true

echo
echo "--- Codec state during playback ---"
rm -f /tmp/x14-sine.wav
ffmpeg -y -f lavfi -i sine=f=880:d=2 -ar 48000 -ac 2 /tmp/x14-sine.wav >/dev/null 2>&1
(aplay -D plughw:0,0 /tmp/x14-sine.wav >/dev/null 2>&1 &)
sleep 0.4
grep -A14 'Node 0x02' /proc/asound/card0/codec#0 | grep -E 'Node|Converter|Amp-Out vals'
grep -A12 'Node 0x14' /proc/asound/card0/codec#0 | grep -E 'Node|Pin-ctls|Amp-Out vals'
grep -A12 'Node 0x21' /proc/asound/card0/codec#0 | grep -E 'Node|Pin-ctls|Connection'
wait

echo
echo "--- Playing test tones (listen now) ---"
for i in 1 2 3; do
  echo "Tone $i/3..."
  paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null || aplay -D plughw:0,0 /tmp/x14-sine.wav 2>/dev/null
  sleep 0.5
done

echo
stream=$(grep -A6 'Node 0x02' /proc/asound/card0/codec#0 | grep 'Converter:' || true)
if echo "$stream" | grep -q 'stream=1'; then
  echo "SOFTWARE: PASS — digital audio reaches speaker DAC"
else
  echo "SOFTWARE: FAIL — no DAC stream during playback"
fi

spk_out=$(grep -A12 'Node 0x14' /proc/asound/card0/codec#0 | grep 'Pin-ctls' || true)
hp_pin=$(grep -A12 'Node 0x21' /proc/asound/card0/codec#0 | grep 'Pin-ctls' || true)
echo "Speaker pin: $spk_out"
echo "Headphone pin: $hp_pin"

echo
echo "If SOFTWARE: PASS but still silent, the physical speaker amp needs a kernel quirk (17aa:513d)."
echo "Workarounds: wired headphones, Bluetooth (Super+Alt+O to switch output)."

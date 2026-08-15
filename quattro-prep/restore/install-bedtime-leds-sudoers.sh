#!/bin/bash
# Run this yourself, interactively (needs your fingerprint/password).
#
# Written 2026-08-16 after the bedtime-mode flicker debugging: the
# `hyprctl keyword` -> `hyprctl eval` fix (already live in
# ~/.local/bin/bedtime-mode) fixed the flicker itself. This is the smaller,
# separate fix for the LED half — `sudo -n bedtime-led-ctl ...` needs this
# rule to stop silently failing with "a password is required" (confirmed in
# the journal at 19:59 and 20:06 today). post-migration-root-tasks.sh
# (2026-08-15) already ran its own 3 steps — this is a standalone addition,
# not a rerun of that file.
set -euo pipefail

echo "Installing the bedtime-led-ctl sudoers drop-in (already syntax-validated)"
sudo visudo -cf ~/dotfiles/quattro-prep/etc-sudoers.d/20-jackz-bedtime-leds
sudo install -m 0440 -o root -g root ~/dotfiles/quattro-prep/etc-sudoers.d/20-jackz-bedtime-leds /etc/sudoers.d/
echo "installed. Verify with: bedtime-mode toggle   (twice, to go dark then back light — LEDs should actually change now, not just the screen)"

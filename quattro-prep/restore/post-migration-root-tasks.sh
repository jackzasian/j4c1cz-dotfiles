#!/bin/bash
# Run this yourself, in an interactive terminal (needs your fingerprint/password —
# an agent can't authenticate these). Safe to run pieces individually too.
#
# Written 2026-08-15 after a post-Quattro verification pass found these three
# root-owned items still open. Everything else in the runbook's §7 checklist
# was already done or fixed non-interactively this session.
set -euo pipefail

echo "1/3 — installing the proxy env_keep sudoers drop-in (already syntax-validated)"
sudo visudo -cf ~/dotfiles/quattro-prep/etc-sudoers.d/10-jackz-proxy-env
sudo install -m 0440 -o root -g root ~/dotfiles/quattro-prep/etc-sudoers.d/10-jackz-proxy-env /etc/sudoers.d/
echo "installed."

echo
echo "2/3 — restoring snapper retention (Quattro's snapper.sh reset it to the 5/5 stock default)"
echo "  before:"; grep -E 'NUMBER_LIMIT|TIMELINE_LIMIT' /etc/snapper/configs/root
sudo sed -i \
  -e 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="50"/' \
  -e 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="10"/' \
  -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="10"/' \
  -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="10"/' \
  -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' \
  -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="10"/' \
  -e 's/^TIMELINE_LIMIT_QUARTERLY=.*/TIMELINE_LIMIT_QUARTERLY="0"/' \
  -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="10"/' \
  /etc/snapper/configs/root
echo "  after:"; grep -E 'NUMBER_LIMIT|TIMELINE_LIMIT' /etc/snapper/configs/root

echo
echo "3/3 — fresh snapshot + full backup, now that the machine is verified stable"
sudo snapper -c root create -d "post-quattro-stable-$(date +%F)"
sudo snapper -c root list | tail -5
~/bin/backup-thinkpad-to-mac all

echo
echo "Done. ufw status verbose is worth a manual glance too (needs your sudo, not scripted here)."

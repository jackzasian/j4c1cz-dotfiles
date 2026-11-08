# AW510M RGB access and startup repair

Applied 2026-11-08. User confirmed lights off after scheduled night command. Preserve white/day 07:00 and off/night 19:00 Asia/Shanghai.

Replaced /etc/udev/rules.d/99-alienware-aw510m.rules with 70-alienware-aw510m.rules: uaccess before 73-seat-late, matches only vendor0461/product4e9e/interface02 via imported properties. Removed root RUN of user-writable ~/.local/bin/aw510m-lights; requests user service instead. Original root rule backed up in /var/backups/aw510m-20261108. Verified new jackz rw ACL, user service Result=success, physical lights-off confirmation.

Added user timer drop-in 95-startup-apply.conf after timezone drop-in; restored monotonic activation trigger previously cleared by OnCalendar reset. User device request triggered the service on rule reprocessing; full unplug/replug has not been tested. No mouse input settings changed.

Rollback requires restoring the saved root rule (contains old security defect, prefer forward repair) and removing only the new startup drop-in. Reload udev and user systemd afterward.

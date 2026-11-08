# Security follow-up — parent integration

The original live-activation batch was executed twice with authenticated root access. Both attempts captured firewall/SSH evidence successfully. Remount, then a full unmount/mount, returned success but retained fmask/dmask=0022. Validation caught this; both automatic rollbacks restored the original fstab and mounted ESP. The cause of retained live masks is not established. No reboot was performed.

The revised `root-security-batch.py` only stages fmask/dmask=0077 in fstab for next boot. It never unmounts/remounts the live ESP. Its administrator authentication is currently pending; do not describe the exposure as repaired until execution and subsequent reboot checks succeed. Guard checks passed before execution. The reviewed original fstab SHA remains pinned. A successful run produces a root-only backup and guarded persistent-config rollback script.

Authenticated evidence from `/var/backups/security-esp-20261108-hcss7wl0`: UFW active, default deny incoming/routed; existing LAN/tailnet sharing scopes retained. Effective sshd output has UsePAM=yes, PermitRootLogin=no, PasswordAuthentication=no, KbdInteractiveAuthentication=no, PubkeyAuthentication=yes, AllowTcpForwarding=no, X11Forwarding=no. Syntax check succeeded. No firewall/SSH changes were justified or made. This does not prove external reachability, tailnet ACLs, or tunnel authentication.

After the next user-initiated reboot, verify `/boot` uses fmask/dmask=0077 and `test ! -r /boot/loader/random-seed` as jackz. Do not read the seed contents. No reboot is scheduled by this task.

The original preparer's report follows as historical evidence; its execution/remount claims are superseded by the above.

---

# Security configuration handoff — 2026-11-08

Prepared only; privileged batch has NOT run. Parent owns authentication and integration. No live configuration, package, Flatpak, scanner policy, Stay Awake schedule, mouse rule, TPM or firmware changes. No reboot. No changes to the main audit or dotfiles. No credentials requested or stored.

## Parent execution

Review `root-security-batch.py`, then include this invocation in the parent's authenticated batch:

```sh
/usr/bin/python3 -I /home/jackz/.t3/scratch/2026-11-08-check-after-reboot-if-everything-d4934b5c/security-fixes/root-security-batch.py --apply
```

For inspection only, omit `--apply`. Prefer copying the reviewed script into the parent's root-owned staging directory before execution. This is a one-shot artifact, not a sudoers grant or installed privileged wrapper. The parent should pin the reviewed file hash from `SHA256SUMS` when staging. Do not run with Python optimization flags (guards use assertions).

The batch captures UFW verbose status, iptables/ip6tables and nft rules when available, sshd syntax and effective policy, representative LAN/tailnet/other Match contexts, and listeners. Each status is printed; failures and stderr are retained. Inspect failures explicitly: collection errors do not prevent the independent ESP fix and are NOT a clean security verdict. All output/backups go to a unique root-only `/var/backups/security-esp-20261108-*` directory, announced by the script. It does not output keys, seed contents, or token-bearing process command lines.

Only mutation: exact reviewed `/etc/fstab` boot entry changes fmask/dmask 0022 → 0077, then remounts `/boot` with those masks and reloads systemd unit definitions. Guarded against changed fstab SHA, unexpected source/filesystem/masks/ownership. Other fstab bytes unchanged. Before applying, validates the candidate fstab. After applying, verifies effective masks, root ownership, no group/other permissions on ESP/seed, and inability of jackz to read the seed. Root boot-update hooks remain able to access the ESP; limine-snapper-sync runs as root. Firmware reads the filesystem without Linux's mount masks. No actual boot/update cycle tested.

Backups: original fstab metadata/content, old mount options, candidate, diagnostics. On apply failure, automatic rollback restores original fstab only if it still equals this batch's candidate, then restores original masks. Check rollback command exit codes; failed rollback is retained in logs. A generated root-only `rollback.sh` supports later rollback, also refusing to overwrite a subsequently edited fstab. Rollback intentionally restores the old exposure. No firewall rollback is necessary because no firewall rule changes are included.

## Confirmed current facts

- ESP `/dev/nvme0n1p1`, UUID `6EDE-2EF9`, vfat, fmask/dmask 0022. `/boot` and `/boot/loader/random-seed` both root-owned 755. Current local entropy-file disclosure is confirmed by permissions; seed contents were not read. This is the concrete fix in the batch, not evidence of host compromise.
- `/usr/bin/sudo -n ufw status verbose` and `sshd -T` still require authentication. This is an evidence-access gap, not an SSH authentication vulnerability. Readable SSH configuration already requires publickey, disables password/keyboard-interactive/root login, restricts users to jackz, and enables PAM. Batch closes effective-policy inspection gap once run; inspect Match contexts and any additional Match rules before certifying all connections.
- Fixed, root-owned `/usr/local/sbin/security-backup-metadata` accepted its authorized no-argument call. It validates root ownership, symlinks and writable ancestors and exports a fixed configuration allowlist. Its archive is retained locally as `root-metadata.tar`. No other privileged wrapper was executed. Lynis wrapper source is isolated/no-argument, but a full scan was unnecessary and not run. Old raw wildcard Lynis grants and user-owned LocalSend sudo hook are absent from current sudo listing. Existing updater grants were not used or modified.
- Saved UFW rules allow all input on tailscale0 (both IP families), with explicit redundant SSH/Syncthing tailnet rules. LocalSend 53317 TCP/UDP is scoped to `enp0s20f0u4u4u1`, source `10.69.10.0/24`; this interface currently has `10.69.10.152/24`. KDE Connect 1714–1764 and SSH are source-limited to `10.69.10.0/24`. SMB source rules include `10.67.1.0/24`, `10.69.10.0/24`, `100.64.0.0/10`; no current port 445 listener observed. IPv6 saved sharing allows are tailnet-only. Docker DNS allows are interface-bound. Waydroid forwarding allows remain. Preserve these until live-chain and access-path review.
- LocalSend, KDE Connect, Syncthing and SSH wildcard listeners persist. UFW saved rules do not prove live filtering; Docker/Tailscale chain precedence, tailnet ACLs, external reachability and Cloudflare tunnel authentication remain unverified. Broad tailnet trust is a deliberate existing boundary, not confirmed public exposure. No safe evidence-supported firewall tightening is justified before the authenticated capture.
- Syncthing UI 8384, proxy/controller 7897/9097, Ollama 11434, ADB 5037 and sampled developer listeners are loopback. Other listeners bind tailnet addresses. Wildcard UDP includes discovery and outgoing QUIC sockets; wildcard socket presence alone is not an unauthenticated service or public-exposure finding.
- Daily scanner still has `SECURITY_SCAN_READ_ONLY=1`. Today's report is DEGRADED, not clean. Omarchy remains untouched at the requested version. Stay Awake and its physical-access tradeoff are explicitly accepted and unchanged.

## Stale versus unresolved scanner findings

The supplied prior audit documents version-aware stale PAM, OpenSSL, reviewed systemd and libxml2-shell matches; these are inherited audit conclusions, not fresh upstream verification in this configuration-only task. Other package advisory groups, exact remaining libxml2 mappings, weekly application/container coverage and firmware currency remain unresolved. Package-name scanner alerts alone are not confirmed present vulnerabilities. No package/Flatpak fixes were attempted. The new OpenSSH advisory discussed in the prior audit was not established as applicable to this glibc/PAM host; root effective-policy evidence is still pending.

## Checks and limits

`python3 -I security-fixes/check-batch.py` passed syntax, exact minimal fstab transformation, and rejection of empty, duplicated, wrong-filesystem and unexpected-mask inputs. Reviewed failure/rollback paths and root-owned backup boundary. Actual remount, root-only collection and rollback have not run; parent must inspect results. No unprivileged live fix was supported by current evidence. These are private local audit artifacts, not a standalone software project; no Git repository exists here and nothing was published.

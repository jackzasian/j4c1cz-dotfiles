#!/usr/bin/python3 -I
"""Parent-reviewed root batch. Default: inspect. --apply: ESP masks for next boot only."""
import hashlib
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile

EXPECTED = '61bc19cd697aaaba0ed7a05f729451c20425fa5de302a27d929c0410e4293829'
ENV = {'PATH': '/usr/bin', 'HOME': '/root', 'LC_ALL': 'C'}

def sha(data):
    return hashlib.sha256(data).hexdigest()

def candidate(data):
    lines = data.decode().splitlines(keepends=True)
    found = 0
    for i, line in enumerate(lines):
        fields = line.split()
        if not fields or line.lstrip().startswith('#') or len(fields) < 4:
            continue
        if fields[1] != '/boot':
            continue
        assert fields[0] == 'UUID=6EDE-2EF9' and fields[2] == 'vfat', 'Unexpected ESP'
        opts = fields[3].split(',')
        assert opts.count('fmask=0022') == opts.count('dmask=0022') == 1
        assert not any(o.startswith(('uid=', 'gid=', 'umask=')) for o in opts)
        lines[i] = re.sub(r'(?<=fmask=)0022|(?<=dmask=)0022', '0077', line)
        found += 1
    assert found == 1, 'Expected exactly one ESP entry'
    return ''.join(lines).encode()

def main():
    assert os.geteuid() == 0, 'Run through parent authenticated root batch'
    assert sys.argv[1:] in ([], ['--apply']), 'Only --apply is supported'
    os.umask(0o077)
    os.chdir('/')
    os.environ.clear()
    os.environ.update(ENV)
    for p in (Path('/var'), Path('/var/backups'), Path('/etc'), Path('/etc/fstab')):
        s = p.lstat()
        assert not stat.S_ISLNK(s.st_mode) and s.st_uid == 0 and not s.st_mode & 0o022, str(p)
    backup = Path(tempfile.mkdtemp(prefix='security-esp-20261108-', dir='/var/backups'))
    print(f'Root-only evidence and rollback directory: {backup}', flush=True)
    def run(name, args, required=True):
        result = subprocess.run(args, env=ENV, stdin=subprocess.DEVNULL,
                                capture_output=True, timeout=45)
        (backup / (name + '.txt')).write_bytes(result.stdout + b'\nSTDERR:\n' + result.stderr)
        print(f'{name}: rc={result.returncode}', flush=True)
        if required and result.returncode:
            raise RuntimeError(f'{name} failed; see {backup}')
        return result.stdout.decode()
    run('ufw', ['/usr/bin/ufw', 'status', 'verbose'], False)
    for tool in ('iptables-save', 'ip6tables-save'):
        if shutil.which(tool):
            run(tool, ['/usr/bin/' + tool], False)
    if shutil.which('nft'):
        run('nft', ['/usr/bin/nft', 'list', 'ruleset'], False)
    run('sshd-syntax', ['/usr/bin/sshd', '-t'], False)
    run('sshd-effective', ['/usr/bin/sshd', '-T'], False)
    # Representative Match contexts, not proof of every possible Match branch.
    for name, address in [('lan', '10.69.10.1'), ('tailnet', '100.100.100.100'), ('other', '192.0.2.1')]:
        run('sshd-' + name, ['/usr/bin/sshd', '-T', '-C',
            f'user=jackz,host=client,addr={address},laddr=10.69.10.11,lport=22'], False)
    run('listeners', ['/usr/bin/ss', '-lntup'], False)
    if not sys.argv[1:]:
        return
    assert not Path('/var/lib/pacman/db.lck').exists(), 'Package transaction active'
    fstab = Path('/etc/fstab')
    original = fstab.read_bytes()
    assert sha(original) == EXPECTED, 'fstab changed since review; stop and re-review'
    proposed = candidate(original)
    source = run('esp-source', ['/usr/bin/findmnt', '-rn', '-o', 'SOURCE,FSTYPE', '--mountpoint', '/boot']).strip()
    assert source == '/dev/nvme0n1p1 vfat', 'Unexpected current mount'
    options = run('esp-options', ['/usr/bin/findmnt', '-rn', '-o', 'OPTIONS', '--mountpoint', '/boot']).strip()
    assert 'fmask=0022' in options.split(',') and 'dmask=0022' in options.split(',')
    assert 'rw' in options.split(',') and not any(o.startswith(('uid=', 'gid=')) for o in options.split(','))
    shutil.copy2(fstab, backup / 'fstab.before')
    (backup / 'fstab.after').write_bytes(proposed)
    (backup / 'mount-options.before').write_text(options + '\n')
    run('fstab-verify', ['/usr/bin/findmnt', '--verify', '--tab-file', str(backup / 'fstab.after')])
    def replace(data):
        fd, path = tempfile.mkstemp(prefix='.fstab-security-', dir='/etc')
        try:
            with os.fdopen(fd, 'wb') as f:
                f.write(data); f.flush(); os.fsync(f.fileno())
            shutil.copystat(backup / 'fstab.before', path)
            os.replace(path, fstab)
        finally:
            if os.path.exists(path): os.unlink(path)
    # Manual rollback is deliberately guarded against overwriting later fstab edits.
    rollback = f'''#!/bin/bash
set -euo pipefail
export PATH=/usr/bin
[[ $EUID == 0 ]]
cd /
[[ $(sha256sum /etc/fstab | cut -d ' ' -f1) == {sha(proposed)} ]]
cp --preserve=all {backup}/fstab.before /etc/fstab
systemctl daemon-reload
findmnt --mountpoint /boot
'''
    (backup / 'rollback.sh').write_text(rollback)
    (backup / 'rollback.sh').chmod(0o700)
    changed = False
    try:
        assert fstab.read_bytes() == original, 'Concurrent fstab edit'
        replace(proposed)
        changed = True
        run('daemon-reload', ['/usr/bin/systemctl', 'daemon-reload'])
        assert fstab.read_bytes() == proposed
        run('fstab-live-verify', ['/usr/bin/findmnt', '--verify', '--tab-file', '/etc/fstab'])
        run('esp-live-options', ['/usr/bin/findmnt', '-rn', '-o', 'OPTIONS', '--mountpoint', '/boot'])
        print('PASS: persistent ESP masks staged for next boot. Live permissions unchanged; reboot verification required. Firewall/SSH unchanged.')
    except BaseException:
        if changed and fstab.read_bytes() == proposed:
            replace(original)
            run('rollback-reload', ['/usr/bin/systemctl', 'daemon-reload'], False)
        raise

if __name__ == '__main__':
    main()

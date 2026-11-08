#!/usr/bin/python3 -I
"""Unprivileged checks; never invokes batch.main()."""
import ast
import importlib.util
from pathlib import Path
p = Path(__file__).with_name('root-security-batch.py')
ast.parse(p.read_text())
s = importlib.util.spec_from_file_location('batch', p)
m = importlib.util.module_from_spec(s)
s.loader.exec_module(m)
f = Path('/etc/fstab').read_bytes()
assert m.sha(f) == m.EXPECTED, 'Live fstab changed: re-review batch'
assert m.candidate(f) == f.replace(b'fmask=0022,dmask=0022', b'fmask=0077,dmask=0077')
for bad in (b'', f + f, f.replace(b'vfat', b'ext4'), f.replace(b'dmask=0022', b'dmask=0000')):
    try:
        m.candidate(bad)
    except AssertionError:
        pass
    else:
        raise AssertionError('Malformed input accepted')
print('PASS: syntax, exact two-mask-only diff, empty/duplicate/wrong-filesystem/wrong-mask rejection')

"""Verify by default. Parent coordinates activation; --apply writes, never reloads."""
from pathlib import Path
import hashlib, json, os, shutil, sys, tempfile
BASE=Path(__file__).resolve().parent
CONFIG=Path.home()/'.config/omarchy'
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None
records=json.loads((BASE/'files.json').read_text())
context=json.loads((BASE/'package-context.json').read_text())
for path, expected in context.items():
    if digest(Path(path)) != expected:
        sys.exit('REFUSED: packaged source changed; rebase and retest before activation: '+path)
for item in records:
    if digest(CONFIG/item['path']) != item['sha256_before']:
        sys.exit('REFUSED: live file changed since staging: '+item['path'])
print('PASS: packaged sources and all live target files match the reviewed baseline.')
if sys.argv[1:] != ['--apply']:
    if sys.argv[1:]: sys.exit('Usage: python apply.py [--apply]')
    sys.exit(0)
# shell.json last. The parent must coordinate this batch with its activation
# window: live plugin watchers can react before all these files are installed.
for item in records:
    dest=CONFIG/item['path']; source=BASE/'staged'/item['path']
    dest.parent.mkdir(parents=True,exist_ok=True)
    fd,name=tempfile.mkstemp(prefix='.'+dest.name+'.',dir=dest.parent)
    os.close(fd)
    try:
        shutil.copyfile(source,name)
        os.chmod(name,dest.stat().st_mode & 0o777 if dest.exists() else 0o644)
        os.replace(name,dest)
    finally:
        if os.path.exists(name): os.unlink(name)
print('Installed staged files. No reload/restart requested by this script.')

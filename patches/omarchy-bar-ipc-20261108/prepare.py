from pathlib import Path
import json, shutil, hashlib, re, difflib
BASE = Path(__file__).resolve().parent
CONFIG = Path.home()/'.config/omarchy'
OUT = BASE/'staged'
BACK = BASE/'backup'
records = []
assert not (CONFIG/'bar/ipc/Registry.qml').exists(), 'Already installed; rebase from the saved baseline instead of preparing again'

def save(rel, data):
    target = CONFIG/rel
    old = target.read_bytes() if target.exists() else None
    if old is not None:
        backup = BACK/rel
        backup.parent.mkdir(parents=True, exist_ok=True)
        if backup.exists():
            assert backup.read_bytes() == old, f'Baseline changed: {rel}'
        else: backup.write_bytes(old)
    dest = OUT/rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data if isinstance(data, bytes) else data.encode())
    records.append({'path':str(rel), 'sha256_before': hashlib.sha256(old).hexdigest() if old is not None else None})

for p in (BASE/'source/shared').iterdir():
    save(Path('bar/ipc')/p.name, p.read_bytes())

# Only live entry points that own IPC; services, tests and vendored lint stubs are excluded.
direct = [
'agx.screen-time/qml/BarWidget.qml','crmne.omacal/BarWidget.qml',
'io.github.mnsosa.backup-history/BarWidget.qml','omaconnect/BarWidget.qml','omaplug/BarWidget.qml',
*[f'jackz.{name}/Panel.qml' for name in ('agents','bluetooth','monitor','network','power','tailscale','weather')],
'robzolkos.github/Panel.qml']
basepanels = [
'djjeane.docker-monitor/Panel.qml','doghouse-mike.omatasknotes/Panel.qml',
'io.github.ilyazar.syncthing/hosts/omarchy/OmarchyPanel.qml',
'jankeesvw.notification-center/Panel.qml','bt.codecs/Panel.qml',
'jackzasian.eq/plugin/Panel.qml','jackz.audio/Panel.qml',
'stappmus.activity-monitor/Panel.qml',
]
import os
for rel in direct + basepanels:
    path = Path('plugins')/rel
    text = (CONFIG/path).read_text()
    imp = os.path.relpath(CONFIG/'bar/ipc', (CONFIG/path).parent)
    text = f'import "{imp}" as LocalIpc\n'+text
    if rel in direct:
        assert text.count('IpcHandler {') == 1, rel
        text = text.replace('IpcHandler {', 'LocalIpc.OwnedIpcHandler {')
    else:
        assert 'manageIpc:' not in text, rel
        match = re.search(r'\bid: (\w+)', text)
        assert match
        root = match[1]
        text = text[:match.end()] + f'\n  manageIpc: ipcLease.selected\n  LocalIpc.IpcLease {{ id: ipcLease; target: {root}.ipcTarget }}' + text[match.end():]
    save(path, text)

# Supported widget clones, copying only their declared entry points. Indicator
# implementations stay package-backed because they do not need modification.
stock = Path('/usr/share/omarchy/shell/plugins/bar/widgets')
for name, ident in [('Indicators','indicators'),('SystemUpdate','system-update')]:
    manifest = json.loads((stock/f'{name}.manifest.json').read_text())
    manifest['id'] = f'jackz.{ident}'
    manifest['name'] = 'My '+manifest['name']
    manifest['omarchy'] = {'clonedFrom':f'omarchy.{ident}'}
    text = (stock/f'{name}.qml').read_text()
    text = 'import "../../bar/ipc" as LocalIpc\n'+text.replace('IpcHandler {','LocalIpc.OwnedIpcHandler {')
    text = text.replace('Qt.resolvedUrl("../indicators/" + indicatorSlot.indicatorId + ".qml")',
                        'Qt.resolvedUrl("file:///usr/share/omarchy/shell/plugins/bar/indicators/" + indicatorSlot.indicatorId + ".qml")')
    save(Path('plugins')/f'jackz.{ident}'/f'{name}.qml', text)
    save(Path('plugins')/f'jackz.{ident}'/'manifest.json', json.dumps(manifest,indent=2)+'\n')

save(Path('bar/modules/desktop-tools.qml'), (BASE/'source/desktop-tools.qml').read_bytes())
config = json.loads((CONFIG/'shell.json').read_text())
for entries in config['bar']['layout'].values():
    for entry in entries:
        if entry['id'] == 'desktop-tools':
            assert entry['type'] == 'command'
            entry['type'] = 'qml'
        elif entry['id'] in ('omarchy.indicators','omarchy.system-update'):
            entry['id'] = entry['id'].replace('omarchy.','jackz.',1)
for ident in ('omarchy.indicators','omarchy.system-update'):
    if ident not in config['disabledPlugins']: config['disabledPlugins'].append(ident)
save(Path('shell.json'), json.dumps(config,indent=2,ensure_ascii=False)+'\n')
(BASE/'files.json').write_text(json.dumps(records,indent=2)+'\n')
patch = ''
for rec in records:
    rel = rec['path']
    old = (BACK/rel).read_text().splitlines(True) if (BACK/rel).exists() else []
    new = (OUT/rel).read_text().splitlines(True)
    patch += ''.join(difflib.unified_diff(old,new,fromfile='before/'+rel,tofile='after/'+rel))
(BASE/'changes.patch').write_text(patch)
print(f'Staged {len(records)} files; live configuration untouched')

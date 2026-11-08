from pathlib import Path
import shutil, json, subprocess, os
BASE=Path(__file__).resolve().parent
RUN=BASE/'compile-runtime'
RUN.mkdir(exist_ok=True)
for name in ('Commons','Ui'):
    p=RUN/name
    if not p.exists(): p.symlink_to(Path('/usr/share/omarchy/shell')/name,target_is_directory=True)
config=RUN/'config'
if config.exists(): shutil.rmtree(config)
shutil.copytree(BASE/'staged',config,dirs_exist_ok=True)
def dependencies(live,dest):
    for item in live.iterdir():
        if item.name in ('.git','node_modules','tests','lint','.venv'): continue
        target=dest/item.name
        if target.exists():
            if target.is_dir() and not target.is_symlink() and item.is_dir(): dependencies(item,target)
        else:
            if item.is_dir():
                target.mkdir(); dependencies(item,target)
            else: shutil.copy2(item,target)
for directory in (config/'plugins').iterdir():
    live=Path.home()/'.config/omarchy/plugins'/directory.name
    if live.exists(): dependencies(live,directory)
paths=[(config/r['path']).as_uri() for r in json.loads((BASE/'files.json').read_text()) if r['path'].endswith('.qml')]
(RUN/'shell.qml').write_text('''import QtQuick
import Quickshell
ShellRoot {
 Component.onCompleted: {
  var paths = '''+json.dumps(paths)+'''
  for (var i=0; i<paths.length; i++) {
   var component = Qt.createComponent(Qt.resolvedUrl(paths[i]))
   console.log("COMPILE", paths[i], component.status === Component.Ready ? "PASS" : component.errorString())
  }
 }
 Timer { interval: 50; running: true; onTriggered: Qt.quit() }
}''')
env=dict(os.environ,QT_QPA_PLATFORM='wayland')
p=subprocess.run(['quickshell','-p',str(RUN/'shell.qml'),'--no-color'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
(BASE/'compile.log').write_text(p.stdout)
lines=[line for line in p.stdout.splitlines() if 'COMPILE' in line]
assert p.returncode==0 and len(lines)==len(paths),p.stdout
fail=[line for line in lines if not line.endswith('PASS')]
assert not fail, p.stdout
print(f'PASS: all {len(paths)} staged QML files compile against actual installed imports and plugin dependencies.')

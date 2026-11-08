from pathlib import Path
import subprocess, os, re, json, shutil
BASE=Path(__file__).resolve().parent
RUN=BASE/'test-runtime'
RUN.mkdir(exist_ok=True)
for name in ('Commons','Ui'):
    p=RUN/name
    if not p.exists(): p.symlink_to(Path('/usr/share/omarchy/shell')/name, target_is_directory=True)
shutil.copytree(BASE/'source/shared',RUN/'ipc',dirs_exist_ok=True)
shutil.copy(BASE/'source/desktop-tools.qml',RUN/'DesktopTools.qml')
env=dict(os.environ,QT_QPA_PLATFORM='offscreen')
env.pop('WAYLAND_DISPLAY',None)

def run(qml, tag):
    (RUN/'shell.qml').write_text(qml)
    p=subprocess.run(['quickshell','-p',str(RUN/'shell.qml'),'--no-color'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=10)
    (BASE/f'{tag}.log').write_text(p.stdout)
    assert p.returncode==0, p.stdout
    assert 'ERROR' not in p.stdout,p.stdout
    return p.stdout

prefix='''import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import "ipc" as LocalIpc
ShellRoot {
 id: root
'''
stop=''' Timer { interval: 150; running: true; onTriggered: Qt.quit() }
}'''
# Actual packaged Panel base, instantiated twice as it is on two bars.
baseline=run(prefix+''' Panel { ipcTarget: "regression.panel" }
 Panel { ipcTarget: "regression.panel" }
'''+stop,'baseline-ipc')
assert 'another handler is registered for target regression.panel' in baseline,baseline
fixed=run(prefix+''' Panel { id: panelA; ipcTarget: "regression.panel"; manageIpc: a.selected
 LocalIpc.IpcLease { id: a; target: panelA.ipcTarget } }
 Panel { id: panelB; ipcTarget: "regression.panel"; manageIpc: b.selected
 LocalIpc.IpcLease { id: b; target: panelB.ipcTarget } }
'''+stop,'fixed-panel')
assert 'WARN' not in fixed,fixed
# Verify the host's actual injection function against its actual custom-command
# component, then the replacement. No external commands run in this harness.
bar=Path('/usr/share/omarchy/shell/plugins/bar/Bar.qml').read_text()
def block(text,start):
    at=text.index(start); begin=text.index('{',at); level=1; i=begin+1
    while level:
        level += (text[i]=='{')-(text[i]=='}'); i+=1
    return text[at:i]
inject=block(bar,'function injectProps()')
custom=block(bar,'component CustomCommandModule:')
settings=json.loads((Path.home()/'.config/omarchy/shell.json').read_text())['bar']['layout']['left'][0]
common=''' property bool vertical: false
 property int barSize: 26
 property string fontFamily: "monospace"
 property color barForeground: "white"
 property color urgent: "red"
 property bool foregroundAnimationEnabled: false
 property var activeItem: widget
 property bool firstParty: true
 property string moduleName: "desktop-tools"
 property var moduleSettings: '''+json.dumps(settings)+'''
 property string pluginApiId: ""
 property bool registered: false
 function entryId(entry) { return entry.id }
 function entrySettings(entry) { return entry }
 function run(command) { console.log("ACTION", command) }
'''+inject+''' Component.onCompleted: { injectProps(); widget.pressed(Qt.LeftButton) }
'''
baseline=run(prefix+common+custom+'\n CustomCommandModule { id: widget; entry: root.moduleSettings }\n'+stop,'baseline-command')
assert 'Cannot assign to read-only property "moduleName"' in baseline,baseline
fixed=run(prefix+common+'\n DesktopTools { id: widget }\n'+stop,'fixed-command')
assert 'WARN' not in fixed and 'ACTION '+settings['onClick'] in fixed,fixed
# Check direct handlers' real IPC discovery and transfer, not only bindings.
qml=prefix+''' property var first
 property var second
 Component { id: factory; LocalIpc.OwnedIpcHandler {
   target: "regression.direct"
   function ping(): string { return "pong" }
   function retire(): void { destroy() }
 } }
 Component.onCompleted: {
   first=factory.createObject(root); second=factory.createObject(root)
   console.log("OWNERS", first.enabled, second.enabled)
 }
 Timer { interval: 8000; running: true; onTriggered: Qt.quit() }
}'''
(RUN/'shell.qml').write_text(qml)
p=subprocess.Popen(['quickshell','-p',str(RUN/'shell.qml'),'--no-color'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
output=[]
try:
    for line in p.stdout:
        output.append(line)
        if 'Configuration Loaded' in line: break
    def ipc(method):
        result=subprocess.run(['quickshell','ipc','-p',str(RUN/'shell.qml'),'call','regression.direct',method],env=env,text=True,capture_output=True,timeout=3)
        assert result.returncode==0,(result.stdout,result.stderr)
        return result.stdout
    assert 'pong' in ipc('ping')
    ipc('retire')
    assert 'pong' in ipc('ping')
finally:
    p.terminate(); output.append(p.communicate(timeout=3)[0])
log=''.join(output)
(BASE/'fixed-direct.log').write_text(log)
assert 'WARN' not in log and 'OWNERS true false' in log,log
print('PASS: actual duplicate Panel warning reproduced; two leased panels clean; actual Bar injectProps readonly warning reproduced; replacement injects settings and dispatches exact Desktop Tools command; real IPC ping survives owner destruction.')

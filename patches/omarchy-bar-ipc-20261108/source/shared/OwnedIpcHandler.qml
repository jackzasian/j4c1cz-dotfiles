import QtQml
import Quickshell.Io
import "."

IpcHandler {
  id: root
  enabled: Registry.owner(target) === root
  Component.onCompleted: Registry.add(root)
  Component.onDestruction: Registry.remove(root)
}

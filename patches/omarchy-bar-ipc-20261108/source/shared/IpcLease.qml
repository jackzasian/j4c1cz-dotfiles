import QtQml
import "."

QtObject {
  id: root
  property string target: ""
  readonly property bool selected: Registry.owner(target) === root
  Component.onCompleted: Registry.add(root)
  Component.onDestruction: Registry.remove(root)
}

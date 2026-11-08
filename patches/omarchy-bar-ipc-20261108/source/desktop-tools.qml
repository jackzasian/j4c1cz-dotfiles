import QtQuick
import qs.Ui

WidgetButton {
  id: root
  property string moduleName: "desktop-tools"
  property var settings: ({})
  text: String(settings.text || "")
  tooltipText: String(settings.tooltip || "")
  horizontalMargin: Number(settings.horizontalMargin ?? 7.5)
  verticalPadding: Number(settings.verticalPadding ?? 6)
  fontSize: Number(settings.fontSize ?? 12)
  onPressed: function(button) {
    var key = button === Qt.RightButton ? "onRightClick"
      : button === Qt.MiddleButton ? "onMiddleClick" : "onClick"
    var command = String(settings[key] || "")
    if (command && bar) bar.run(command)
  }
}

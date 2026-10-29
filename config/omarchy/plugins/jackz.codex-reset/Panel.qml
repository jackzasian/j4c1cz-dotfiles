import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import "Countdown.js" as Countdown

Item {
  id: root
  property var bar: null
  property var settings: ({})
  property bool menuOnly: false
  property var forecast: ({})
  property double nowMs: Date.now()
  readonly property bool old: forecast.stale === true || !forecast.fetchedAt || nowMs - Date.parse(forecast.fetchedAt) > 900000
  readonly property var signal: forecast.signal || ({})
  readonly property double deadline: signal.active === true && signal.deadline ? Date.parse(signal.deadline) : NaN
  readonly property string countdown: Countdown.format(deadline, nowMs)
  readonly property string odds: typeof forecast.p24 === "number" ? "~" + forecast.p24 + "%/24h" : "?"
  readonly property string label: (countdown || (signal.active === true ? "signal" : odds)) + (old ? " *" : "")
  readonly property string details: "Potential global reset · " + (old ? "STALE / unavailable\n" : "")
    + "Community forecast: " + odds + (typeof forecast.p48 === "number" ? " · ~" + forecast.p48 + "%/48h" : "")
    + "\nConfidence: " + (forecast.confidence || "unknown")
    + "\n" + (signal.active === true ? "Active announcement: " + signal.summary : "No active reset announcement")
    + (signal.deadline ? "\nAnnounced deadline (may land earlier): " + signal.deadline : "")
    + "\nLast reported reset: " + (forecast.lastResetAt || "unknown")
    + "\nSource updated: " + (forecast.updatedAt || "unknown")
    + "\nForecast only; your account reset timer is on the Codex chip."
    + "\nData: codex-reset.com · Click to open"

  implicitWidth: menuOnly ? 0 : button.implicitWidth
  implicitHeight: button.implicitHeight

  Timer {
    interval: 300000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!fetch.running) fetch.running = true
  }
  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }
  Process {
    id: fetch
    command: [Quickshell.env("HOME") + "/.local/bin/omarchy-codex-reset-forecast"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          if (parsed && typeof parsed === "object") root.forecast = parsed
        } catch (e) { root.forecast = Object.assign({}, root.forecast, {stale: true}) }
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.forecast = Object.assign({}, root.forecast, {stale: true})
    }
  }
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    visible: !root.menuOnly
    text: root.label
    tooltipText: root.details
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) Quickshell.execDetached(["xdg-open", "https://codex-reset.com/"])
      else if (mouseButton === Qt.RightButton && !fetch.running) fetch.running = true
    }
  }
}

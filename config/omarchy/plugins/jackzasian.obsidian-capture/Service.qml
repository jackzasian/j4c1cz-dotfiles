import QtQuick
import Quickshell
import Quickshell.Io

// One-time wiring for the obsidian-capture CLI: symlinks into ~/.local/bin,
// omarchy-menu entries, and Hyprland keybindings.
//
// install.sh --plugin is idempotent and exits fast when everything is already
// in place, so re-running it at every shell start is safe and cheap.
Item {
    id: root

    function pluginDir() {
        var url = Qt.resolvedUrl(".").toString()
        var path = url.replace(/^file:\/\//, "")
        if (path.charAt(path.length - 1) !== "/") path += "/"
        return path
    }

    Process {
        id: wireProc
        stdout: StdioCollector {
            id: wireOut
            waitForEnd: true
        }
        onExited: function(code) {
            console.log("obsidian-capture wiring exit:", code)
        }
    }

    Component.onCompleted: {
        wireProc.command = ["bash", root.pluginDir() + "install.sh", "--plugin"]
        wireProc.running = true
    }
}
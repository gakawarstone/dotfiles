import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

RowLayout {
    id: root
    spacing: 8

    property double lastDown: 0
    property double lastUp: 0
    property string downSpeed: "0 B/s"
    property string upSpeed: "0 B/s"

    function formatSpeed(bytes) {
        if (bytes < 1024) return bytes.toFixed(0) + " B/s";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB/s";
        return (bytes / (1024 * 1024)).toFixed(1) + " MB/s";
    }

    Process {
        id: netInfo
        command: ["sh", "-c", "grep -vE 'lo|face' /proc/net/dev | awk '{d+=$2; u+=$10} END {print d, u}'"]
        running: false
        stdout: StdioCollector {
            id: netCollector
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                let parts = netCollector.text.trim().split(/\s+/);
                if (parts.length === 2) {
                    let currentDown = parseFloat(parts[0]);
                    let currentUp = parseFloat(parts[1]);

                    if (root.lastDown > 0) {
                        root.downSpeed = formatSpeed(currentDown - root.lastDown);
                        root.upSpeed = formatSpeed(currentUp - root.lastUp);
                    }

                    root.lastDown = currentDown;
                    root.lastUp = currentUp;
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netInfo.running = true
    }

    RowLayout {
        spacing: 4
        Text {
            text: "󰇚"
            font.pixelSize: 18
            color: Theme.green
            font.family: "MonaspiceKr Nerd Font"
        }
        Text {
            text: root.downSpeed
            color: Theme.text
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }
    }

    RowLayout {
        spacing: 4
        Text {
            text: "󰕒"
            font.pixelSize: 18
            color: Theme.red
            font.family: "MonaspiceKr Nerd Font"
        }
        Text {
            text: root.upSpeed
            color: Theme.text
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }
    }
}

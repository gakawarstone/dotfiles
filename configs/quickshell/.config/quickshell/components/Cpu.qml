import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

RowLayout {
    id: root
    spacing: 8

    property string usage: "0"

    Process {
        id: cpuInfo
        command: ["sh", "-c", "vmstat 1 2 | tail -1 | awk '{print 100 - $15}'"]
        running: true
        stdout: StdioCollector {
            id: cpuCollector
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.usage = cpuCollector.text.trim();
            }
        }
    }

    Timer {
        interval: 5000 // 5 seconds is probably enough for CPU
        running: true
        repeat: true
        onTriggered: cpuInfo.running = true
    }

    Text {
        text: "󰻠"
        font.pixelSize: 18
        color: "#fab387"
        font.family: "MonaspiceKr Nerd Font"
    }

    Text {
        text: root.usage + "%"
        color: "#cdd6f4"
        font.pixelSize: 14
        font.family: "MonaspiceKr Nerd Font"
    }
}
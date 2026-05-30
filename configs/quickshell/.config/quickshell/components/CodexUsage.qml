import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

MouseArea {
    id: root
    Layout.fillHeight: true
    implicitWidth: layout.implicitWidth
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    property bool menuOpen: false
    property string usage: "--"
    property string detail: "No Codex usage snapshot"
    property string statusColor: "muted"
    property int primaryUsed: 0
    property int primaryLeft: 0
    property int secondaryUsed: 0
    property int secondaryLeft: 0
    property string primaryReset: "?"
    property string secondaryReset: "?"

    function accentColor() {
        if (statusColor === "red") return Theme.red
        if (statusColor === "yellow") return Theme.yellow
        if (statusColor === "green") return Theme.green
        return Theme.overlay2
    }

    Process {
        id: codexUsage
        command: ["sh", "-c", "python3 \"$HOME/.config/quickshell/scripts/codex-usage.py\""]
        running: true
        stdout: StdioCollector {
            id: codexCollector
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.usage = "--"
                root.detail = "Codex usage unavailable"
                root.statusColor = "muted"
                return
            }

            try {
                const data = JSON.parse(codexCollector.text.trim())
                root.usage = data.text || "--"
                root.detail = data.detail || "No Codex usage snapshot"
                root.statusColor = data.color || "muted"
                root.primaryUsed = data.primary_used || 0
                root.primaryLeft = data.primary || 0
                root.secondaryUsed = data.secondary_used || 0
                root.secondaryLeft = data.secondary || 0
                root.primaryReset = data.primary_reset || "?"
                root.secondaryReset = data.secondary_reset || "?"
            } catch (error) {
                root.usage = "--"
                root.detail = "Codex usage parse failed"
                root.statusColor = "muted"
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: codexUsage.running = true
    }

    onClicked: menuOpen = !menuOpen

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        Text {
            text: "󰚩"
            font.pixelSize: 18
            color: root.accentColor()
            font.family: "MonaspiceKr Nerd Font"
        }

        Text {
            text: root.usage
            color: Theme.text
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }
    }

    CodexUsagePopup {
        visible: root.menuOpen
        anchorItem: root
        statusColor: root.statusColor
        primaryUsed: root.primaryUsed
        primaryLeft: root.primaryLeft
        secondaryUsed: root.secondaryUsed
        secondaryLeft: root.secondaryLeft
        primaryReset: root.primaryReset
        secondaryReset: root.secondaryReset

        onVisibleChanged: {
            if (!visible) root.menuOpen = false
        }
    }
}

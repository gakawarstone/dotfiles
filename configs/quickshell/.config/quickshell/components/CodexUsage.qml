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
    property bool available: false
    property string statusColor: "muted"
    property bool burnTime: false
    property int primaryUsed: 0
    property int primaryLeft: 0
    property int secondaryUsed: 0
    property int secondaryLeft: 0
    property string primaryReset: "?"
    property string secondaryReset: "?"
    property bool reserveAvailable: false
    property bool reserveAllowed: false
    property int reserveUsed: 0
    property int reserveLeft: 0
    property string reserveReset: "?"
    property bool reserveLimitReached: false

    function markUnavailable(message) {
        available = false
        usage = "--"
        detail = message
        statusColor = "muted"
        burnTime = false
        primaryUsed = 0
        primaryLeft = 0
        secondaryUsed = 0
        secondaryLeft = 0
        primaryReset = "?"
        secondaryReset = "?"
        reserveAvailable = false
        reserveAllowed = false
        reserveUsed = 0
        reserveLeft = 0
        reserveReset = "?"
        reserveLimitReached = false
    }

    function accentColor() {
        if (statusColor === "red") return Theme.red
        if (statusColor === "yellow") return Theme.yellow
        if (statusColor === "green") return Theme.green
        if (statusColor === "luna") return Theme.mauve
        return Theme.overlay2
    }

    function handleResult(exitCode, output) {
        if (exitCode !== 0) {
            root.markUnavailable("Codex usage unavailable")
            return
        }

        try {
            const data = JSON.parse(output.trim())
            if (data.ok === false) {
                root.markUnavailable("Codex usage unavailable")
                return
            }

            root.usage = data.text || "--"
            root.detail = data.detail || "No Codex usage snapshot"
            root.statusColor = data.color || "muted"
            root.burnTime = data.burn_time === true
            root.primaryUsed = data.primary_used || 0
            root.primaryLeft = data.primary || 0
            root.secondaryUsed = data.secondary_used || 0
            root.secondaryLeft = data.secondary || 0
            root.primaryReset = data.primary_reset || "?"
            root.secondaryReset = data.secondary_reset || "?"
            root.reserveAvailable = data.reserve_available === true
            root.reserveAllowed = data.reserve_allowed === true
            root.reserveUsed = data.reserve_used || 0
            root.reserveLeft = data.reserve || 0
            root.reserveReset = data.reserve_reset || "?"
            root.reserveLimitReached = data.reserve_limit_reached === true
            root.available = true
        } catch (error) {
            root.markUnavailable("Codex usage parse failed")
        }
    }

    Process {
        id: codexUsage
        command: ["sh", "-c", "python3 \"$HOME/.config/quickshell/scripts/codex-usage.py\""]
        running: true
        stdout: StdioCollector {
            id: codexCollector
        }
        onExited: (exitCode) => root.handleResult(exitCode, codexCollector.text)
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
            text: root.burnTime ? "󰈸" : "󰚩"
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
        available: root.available
        detail: root.detail
        statusColor: root.statusColor
        primaryUsed: root.primaryUsed
        primaryLeft: root.primaryLeft
        secondaryUsed: root.secondaryUsed
        secondaryLeft: root.secondaryLeft
        primaryReset: root.primaryReset
        secondaryReset: root.secondaryReset
        reserveAvailable: root.reserveAvailable
        reserveAllowed: root.reserveAllowed
        reserveUsed: root.reserveUsed
        reserveLeft: root.reserveLeft
        reserveReset: root.reserveReset
        reserveLimitReached: root.reserveLimitReached

        onVisibleChanged: {
            if (!visible) root.menuOpen = false
        }
    }
}

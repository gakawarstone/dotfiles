import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

MouseArea {
    id: root
    Layout.fillHeight: true
    implicitWidth: layout.implicitWidth
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    property bool menuOpen: false
    property bool ready: false
    property string state: "disconnected"
    property string errorMessage: ""
    readonly property bool busy: terminalProcess.running || disconnectProcess.running
    readonly property string helper: Quickshell.shellPath("scripts/hsfl-vpn.py")
    readonly property string vpnFont: "MonaspiceKr Nerd Font"
    readonly property string statusText: busy || state === "connecting" ? "Connecting…"
        : state === "connected" ? "Connected" : "Disconnected"

    function refresh() {
        if (!statusProcess.running) statusProcess.running = true;
    }

    function runAction() {
        errorMessage = "";
        if (state === "connected") {
            disconnectProcess.running = true;
        } else {
            terminalProcess.command = ["kitty", "--title", "HS Flensburg VPN", "-e",
                "python3", helper, ready ? "connect" : "install"];
            terminalProcess.running = true;
        }
    }

    onClicked: {
        menuOpen = !menuOpen;
        if (menuOpen) refresh();
    }

    Process {
        id: statusProcess
        command: ["python3", root.helper, "status"]
        running: true
        stdout: StdioCollector { id: statusOutput }
        stderr: StdioCollector { id: statusError }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.state = "unavailable";
                root.errorMessage = statusError.text.trim() || "Cannot read VPN status.";
                return;
            }
            try {
                const status = JSON.parse(statusOutput.text);
                root.ready = status.ready;
                root.state = status.state;
            } catch (error) {
                root.state = "unavailable";
                root.errorMessage = "Cannot read VPN status.";
            }
        }
    }

    Process {
        id: terminalProcess
        stderr: StdioCollector { id: terminalError }
        onExited: exitCode => {
            if (exitCode !== 0)
                root.errorMessage = terminalError.text.trim() || "VPN action cancelled or failed. Try again.";
            root.refresh();
        }
    }

    Process {
        id: disconnectProcess
        command: ["python3", root.helper, "disconnect"]
        stderr: StdioCollector { id: disconnectError }
        onExited: exitCode => {
            if (exitCode !== 0)
                root.errorMessage = disconnectError.text.trim() || "Could not disconnect VPN.";
            root.refresh();
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 6

        Text {
            text: "󰌾"
            font.family: root.vpnFont
            font.pixelSize: 18
            color: root.busy || root.state === "connecting" ? Theme.yellow
                : root.state === "connected" ? Theme.green : Theme.overlay0
        }

        Text {
            text: "HSFL"
            font.family: root.vpnFont
            font.pixelSize: 14
            color: Theme.text
        }
    }

    PopupWindow {
        id: popup
        visible: root.menuOpen
        color: "transparent"
        implicitWidth: 340
        implicitHeight: content.implicitHeight
        anchor.item: root
        anchor.rect.x: root.width - width
        anchor.rect.y: root.height + 5

        Rectangle {
            id: content
            width: popup.width
            implicitHeight: column.implicitHeight + 32
            color: Theme.base
            border.color: Theme.surface0
            border.width: 1
            radius: 8

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "HS Flensburg VPN"
                        font.family: root.vpnFont
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.text
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "×"
                        font.pixelSize: 22
                        color: Theme.overlay0
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.menuOpen = false
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "vpn.hs-flensburg.de\nHSFL-Studierende"
                    color: Theme.overlay2
                    font.family: root.vpnFont
                    font.pixelSize: 12
                }

                Text {
                    Layout.fillWidth: true
                    text: root.state === "unavailable" ? "VPN unavailable"
                        : root.busy ? "Continue in the VPN terminal" : root.statusText
                    color: root.state === "connected" ? Theme.green : Theme.text
                    font.family: root.vpnFont
                    font.pixelSize: 14
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.state !== "connected"
                    text: root.ready
                        ? "Enter your university username and password in the terminal. Passwords are not saved."
                        : "Install OpenConnect and its NetworkManager plugin first. The terminal will ask for your sudo password."
                    wrapMode: Text.WordWrap
                    color: Theme.overlay2
                    font.family: root.vpnFont
                    font.pixelSize: 12
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.errorMessage !== ""
                    text: root.errorMessage
                    wrapMode: Text.WrapAnywhere
                    color: Theme.red
                    font.family: root.vpnFont
                    font.pixelSize: 12
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 5
                    color: actionArea.enabled ? (actionArea.containsMouse ? Theme.surface2 : Theme.surface0) : Theme.surface0
                    opacity: actionArea.enabled ? 1 : 0.5

                    Text {
                        anchors.centerIn: parent
                        text: root.busy ? "In progress…" : root.state === "connected"
                            ? "Disconnect" : root.ready ? "Connect" : "Install VPN support"
                        color: Theme.text
                        font.family: root.vpnFont
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.busy && root.state !== "connecting" && root.state !== "unavailable"
                        onClicked: root.runAction()
                    }
                }
            }
        }
    }
}

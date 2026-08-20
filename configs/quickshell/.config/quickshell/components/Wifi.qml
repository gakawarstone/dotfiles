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
    property string ssid: "Disconnected"
    property bool isEthernet: false

    function refresh() {
        if (!wifiInfo.running) wifiInfo.running = true;
    }

    onClicked: menuOpen = !menuOpen

    Process {
        id: wifiInfo
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device | grep -m 1 '^ethernet:connected' || nmcli -t -f active,ssid dev wifi | grep -m 1 '^yes'"]
        running: true
        stdout: StdioCollector { id: wifiCollector }

        onExited: exitCode => {
            const cleanText = wifiCollector.text.trim();
            if (exitCode === 0 && cleanText.startsWith("ethernet:connected:")) {
                const parts = cleanText.split(":");
                root.ssid = parts[2] || "Ethernet";
                root.isEthernet = true;
            } else if (exitCode === 0 && cleanText.startsWith("yes:")) {
                const parts = cleanText.split(":");
                root.ssid = parts[1] || "Connected";
                root.isEthernet = false;
            } else {
                root.ssid = "Disconnected";
                root.isEthernet = false;
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        Text {
            text: root.ssid === "Disconnected" ? "󰖪" : (root.isEthernet ? "󰈀" : "󰖩")
            font.pixelSize: 18
            color: root.ssid === "Disconnected" ? Theme.red : (root.isEthernet ? Theme.green : Theme.blue)
            font.family: "MonaspiceKr Nerd Font"
        }

        Text {
            visible: text !== ""
            text: root.isEthernet ? "" : root.ssid
            color: Theme.text
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }
    }

    WifiPopup {
        visible: root.menuOpen
        anchorItem: root

        onNetworkChanged: root.refresh()
        onVisibleChanged: {
            if (!visible) root.menuOpen = false;
        }
    }
}

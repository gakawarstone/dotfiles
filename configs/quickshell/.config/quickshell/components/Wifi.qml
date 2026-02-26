import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

RowLayout {
    id: root
    spacing: 8

    property string ssid: "Disconnected"
    property string bars: ""
    property bool isEthernet: false

    Process {
        id: wifiInfo
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device | grep '^ethernet:connected' | head -n 1 || nmcli -t -f active,ssid,bars dev wifi | grep '^yes'"]
        running: true
        stdout: StdioCollector {
            id: wifiCollector
        }
        onExited: (exitCode) => {
            const cleanText = wifiCollector.text.trim();
            if (exitCode === 0) {
                if (cleanText.startsWith("ethernet:connected:")) {
                    const parts = cleanText.split(":");
                    root.ssid = parts[2] || "Ethernet";
                    root.bars = "";
                    root.isEthernet = true;
                } else if (cleanText.startsWith("yes:")) {
                    const parts = cleanText.split(":");
                    if (parts.length >= 3) {
                        root.ssid = parts[1];
                        root.bars = parts[2];
                        root.isEthernet = false;
                    }
                } else {
                    root.ssid = "Disconnected";
                    root.bars = "";
                    root.isEthernet = false;
                }
            } else {
                root.ssid = "Disconnected";
                root.bars = "";
                root.isEthernet = false;
            }
        }
    }

    Timer {
        interval: 10000 // 10 seconds
        running: true
        repeat: true
        onTriggered: wifiInfo.running = true
    }

    Component.onCompleted: {
        wifiInfo.running = true;
    }

    Text {
        text: root.ssid === "Disconnected" ? "󰖪" : (root.isEthernet ? "󰈀" : "󰖩")
        font.pixelSize: 18
        color: root.ssid === "Disconnected" ? "#f38ba8" : (root.isEthernet ? "#a6e3a1" : "#89b4fa")
        font.family: "MonaspiceKr Nerd Font"
    }

    Text {
        text: root.isEthernet ? "" : root.ssid
        color: "#cdd6f4"
        font.pixelSize: 14
        font.family: "MonaspiceKr Nerd Font"
        visible: text !== ""
    }
}

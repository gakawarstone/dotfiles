import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

RowLayout {
    id: root
    spacing: 8

    property string ssid: "Disconnected"
    property string bars: ""

    Process {
        id: wifiInfo
        command: ["sh", "-c", "nmcli -t -f active,ssid,bars dev wifi | grep '^yes'"]
        running: true
        stdout: StdioCollector {
            id: wifiCollector
        }
        onExited: (exitCode) => {
            const cleanText = wifiCollector.text.trim();
            if (exitCode === 0 && cleanText.startsWith("yes:")) {
                const parts = cleanText.split(":");
                if (parts.length >= 3) {
                    root.ssid = parts[1];
                    root.bars = parts[2];
                }
            } else {
                root.ssid = "Disconnected";
                root.bars = "";
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
        text: root.ssid === "Disconnected" ? "󰖪" : "󰖩"
        font.pixelSize: 18
        color: root.ssid === "Disconnected" ? "#f38ba8" : "#89b4fa"
        font.family: "MonaspiceKr Nerd Font"
    }

    Text {
        text: root.ssid
        color: "#cdd6f4"
        font.pixelSize: 14
        font.family: "MonaspiceKr Nerd Font"
    }
}

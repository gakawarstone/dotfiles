import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: popup

    required property var anchorItem
    property string connectionName: "Ethernet"
    property string interfaceName: ""
    property string ipAddress: "--"
    property string gateway: "--"
    property string latency: "--"
    property string packetLoss: "--"
    property real receivedBytes: 0
    property real sentBytes: 0
    property real receiveRate: 0
    property real sendRate: 0
    property real previousReceivedBytes: -1
    property real previousSentBytes: -1
    property double previousSampleTime: 0
    readonly property string popupFont: "MonaspiceKr Nerd Font"

    function formatBytes(bytes) {
        if (!isFinite(bytes) || bytes < 0) return "--";
        if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + " GB";
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB";
        if (bytes >= 1024) return (bytes / 1024).toFixed(1) + " KB";
        return Math.round(bytes) + " B";
    }

    function formatRate(bytesPerSecond) {
        return formatBytes(bytesPerSecond) + "/s";
    }

    function refresh() {
        if (!networkInfo.running) networkInfo.running = true;
        if (popup.gateway !== "--" && !pingInfo.running) pingInfo.running = true;
    }

    color: "transparent"
    width: content.width
    height: content.height
    anchor.item: popup.anchorItem
    relativeX: popup.anchorItem ? popup.anchorItem.width - width : 0
    relativeY: popup.anchorItem ? popup.anchorItem.height + 5 : 0

    onVisibleChanged: {
        if (visible) refresh();
        else {
            previousReceivedBytes = -1;
            previousSentBytes = -1;
            previousSampleTime = 0;
        }
    }

    Process {
        id: networkInfo
        command: ["sh", "-c", "iface=$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$2 == \"ethernet\" && $3 == \"connected\" { print $1; exit }'); [ -n \"$iface\" ] || exit 1; connection=$(nmcli -g GENERAL.CONNECTION device show \"$iface\" | head -n 1); address=$(nmcli -g IP4.ADDRESS device show \"$iface\" | head -n 1 | cut -d/ -f1); gateway=$(nmcli -g IP4.GATEWAY device show \"$iface\" | head -n 1); rx=$(cat \"/sys/class/net/$iface/statistics/rx_bytes\"); tx=$(cat \"/sys/class/net/$iface/statistics/tx_bytes\"); printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$iface\" \"$connection\" \"$address\" \"$gateway\" \"$rx\" \"$tx\""]
        stdout: StdioCollector { id: networkCollector }

        onExited: exitCode => {
            if (exitCode !== 0) {
                popup.interfaceName = "";
                popup.connectionName = "Ethernet";
                popup.ipAddress = "--";
                popup.gateway = "--";
                popup.receiveRate = 0;
                popup.sendRate = 0;
                return;
            }

            const fields = networkCollector.text.trim().split("\t");
            if (fields.length < 6) return;

            const now = Date.now();
            const received = Number(fields[4]);
            const sent = Number(fields[5]);
            if (popup.previousSampleTime > 0 && now > popup.previousSampleTime) {
                const elapsedSeconds = (now - popup.previousSampleTime) / 1000;
                popup.receiveRate = Math.max(0, (received - popup.previousReceivedBytes) / elapsedSeconds);
                popup.sendRate = Math.max(0, (sent - popup.previousSentBytes) / elapsedSeconds);
            }

            popup.interfaceName = fields[0];
            popup.connectionName = fields[1] || "Ethernet";
            popup.ipAddress = fields[2] || "--";
            popup.gateway = fields[3] || "--";
            popup.receivedBytes = received;
            popup.sentBytes = sent;
            popup.previousReceivedBytes = received;
            popup.previousSentBytes = sent;
            popup.previousSampleTime = now;

            if (popup.latency === "--" && !pingInfo.running)
                pingInfo.running = true;
        }
    }

    Process {
        id: pingInfo
        command: ["sh", "-c", "result=$(ping -n -q -c 3 -W 1 \"$1\" 2>/dev/null); loss=$(printf '%s\\n' \"$result\" | sed -n 's/.* \\([0-9.]*%\\) packet loss.*/\\1/p'); latency=$(printf '%s\\n' \"$result\" | awk -F/ '/^(rtt|round-trip)/ { printf \"%.1f ms\", $5 }'); printf '%s\\t%s\\n' \"${latency:---}\" \"${loss:---}\"", "ethernet-ping", popup.gateway]
        stdout: StdioCollector { id: pingCollector }

        onExited: exitCode => {
            const fields = pingCollector.text.trim().split("\t");
            popup.latency = exitCode === 0 && fields[0] ? fields[0] : "--";
            popup.packetLoss = exitCode === 0 && fields[1] ? fields[1] : "--";
        }
    }

    Timer {
        interval: 2000
        running: popup.visible
        repeat: true
        onTriggered: {
            if (!networkInfo.running) networkInfo.running = true;
        }
    }

    Timer {
        interval: 15000
        running: popup.visible
        repeat: true
        onTriggered: {
            if (popup.gateway !== "--" && !pingInfo.running) pingInfo.running = true;
        }
    }

    Rectangle {
        id: content
        implicitWidth: 500
        implicitHeight: 194
        color: Theme.base
        border.color: Theme.blue
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Text {
                    text: "󰈀"
                    color: Theme.blue
                    font.family: popup.popupFont
                    font.pixelSize: 28
                }

                ColumnLayout {
                    spacing: 1

                    Text {
                        text: "Ethernet"
                        color: Theme.text
                        font.family: popup.popupFont
                        font.bold: true
                        font.pixelSize: 18
                    }

                    Text {
                        text: popup.connectionName.toUpperCase()
                        color: Theme.overlay2
                        font.family: popup.popupFont
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 2
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 18
                rowSpacing: 5

                MetricLabel { text: "Ping" }
                MetricValue { text: popup.latency }
                MetricLabel { text: "Packet Loss" }
                MetricValue { text: popup.packetLoss }

                MetricLabel { text: "Receiving" }
                MetricValue { text: popup.formatRate(popup.receiveRate) }
                MetricLabel { text: "Sending" }
                MetricValue { text: popup.formatRate(popup.sendRate) }

                MetricLabel { text: "Downloaded" }
                MetricValue { text: popup.formatBytes(popup.receivedBytes) }
                MetricLabel { text: "Uploaded" }
                MetricValue { text: popup.formatBytes(popup.sentBytes) }

                MetricLabel { text: "IP Address" }
                MetricValue { text: popup.ipAddress }
                MetricLabel { text: "Gateway" }
                MetricValue { text: popup.gateway }
            }
        }
    }

    component MetricLabel: Text {
        Layout.preferredWidth: 120
        color: Theme.overlay2
        font.family: popup.popupFont
        font.pixelSize: 14
    }

    component MetricValue: Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignRight
        color: Theme.text
        font.family: popup.popupFont
        font.pixelSize: 14
    }
}

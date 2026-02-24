import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower

Rectangle {
    id: root
    color: "#1e1e2e"

    property string activeLayout: ".."

    Process {
        id: initLayout
        command: ["sh", "-c", "hyprctl devices | grep -B 3 'main: yes' | grep 'active keymap' | cut -d ':' -f 2 | xargs"]
        running: true
        stdout: StdioCollector {
            id: collector
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                const layoutName = collector.text.trim();
                if (layoutName.toLowerCase().includes("english")) root.activeLayout = "US";
                else if (layoutName.toLowerCase().includes("german")) root.activeLayout = "DE";
                else if (layoutName.toLowerCase().includes("russian")) root.activeLayout = "RU";
                else if (layoutName.length > 0) root.activeLayout = layoutName;
            }
        }
    }

    Process {
        id: switchLayout
        command: ["hyprctl", "switchxkblayout", "all", "next"]
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                const parts = event.data.split(",");
                if (parts.length > 1) {
                    const layoutName = parts[1];
                    if (layoutName.toLowerCase().includes("english")) root.activeLayout = "US";
                    else if (layoutName.toLowerCase().includes("german")) root.activeLayout = "DE";
                    else if (layoutName.toLowerCase().includes("russian")) root.activeLayout = "RU";
                    else root.activeLayout = layoutName;
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 15

        // Left: Arch icon + Workspaces
        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: 15

            Text {
                text: "󰣇"
                font.pixelSize: 22
                color: "#89b4fa"
                font.family: "MonaspiceKr Nerd Font"
            }

            Row {
                spacing: 8
                Repeater {
                    model: Hyprland.workspaces
                    delegate: Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: modelData.active ? "#cba6f7" : (modelData.visible ? "#45475a" : "transparent")
                        border.color: modelData.visible ? "#585b70" : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                            color: modelData.active ? "#11111b" : "#cdd6f4"
                            font.pixelSize: 13
                            font.bold: modelData.active
                            font.family: "MonaspiceKr Nerd Font"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + modelData.name)
                        }
                    }
                }
            }
        }

        // Center: Active Window Title
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            text: Hyprland.activeToplevel ? (Hyprland.activeToplevel.appId || Hyprland.activeToplevel.title) : "Desktop"
            color: "#cdd6f4"
            elide: Text.ElideRight
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }

        // Right: System Info
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

            // Battery
            RowLayout {
                spacing: 8
                visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
                Text {
                    text: {
                        if (!UPower.displayDevice) return "󰂑"
                        if (UPower.displayDevice.state === UPowerDeviceState.Charging) return "󰂄"
                        const p = UPower.displayDevice.percentage * 100
                        if (p <= 10) return "󰁺"
                        if (p <= 20) return "󰁻"
                        if (p <= 30) return "󰁼"
                        if (p <= 40) return "󰁽"
                        if (p <= 50) return "󰁾"
                        if (p <= 60) return "󰁿"
                        if (p <= 70) return "󰂀"
                        if (p <= 80) return "󰂁"
                        if (p <= 90) return "󰂂"
                        return "󰁹"
                    }
                    font.pixelSize: 18
                    color: {
                        if (UPower.displayDevice && (UPower.displayDevice.percentage * 100) < 20) return "#f38ba8"
                        return "#a6e3a1"
                    }
                    font.family: "MonaspiceKr Nerd Font"
                }
                Text {
                    text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
                    color: "#cdd6f4"
                    font.pixelSize: 14
                    font.family: "MonaspiceKr Nerd Font"
                }
            }

            // Keyboard Layout
            Item {
                Layout.preferredWidth: kbRow.implicitWidth
                Layout.fillHeight: true

                RowLayout {
                    id: kbRow
                    anchors.fill: parent
                    spacing: 8
                    Text {
                        text: "󰌌"
                        font.pixelSize: 18
                        color: "#89b4fa"
                        font.family: "MonaspiceKr Nerd Font"
                    }
                    Text {
                        text: root.activeLayout
                        color: "#cdd6f4"
                        font.pixelSize: 14
                        font.family: "MonaspiceKr Nerd Font"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: switchLayout.running = true
                }
            }
        }
    }

    // Bottom border/line
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#313244"
    }
}
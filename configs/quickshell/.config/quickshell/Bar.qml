import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io

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
            text: Hyprland.focusedClient ? Hyprland.focusedClient.title : "Desktop"
            color: "#cdd6f4"
            elide: Text.ElideRight
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }

        // Right: System Info
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

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
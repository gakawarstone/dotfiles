import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Rectangle {
    id: root
    color: "#1e1e2e"

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

            // Clock & Date
            Column {
                Layout.alignment: Qt.AlignRight
                Text {
                    id: clockText
                    property var time: new Date()
                    text: Qt.formatDateTime(time, "HH:mm:ss")
                    color: "#cdd6f4"
                    font.pixelSize: 14
                    font.family: "MonaspiceKr Nerd Font"
                    anchors.right: parent.right

                    Timer {
                        interval: 1000
                        repeat: true
                        running: true
                        onTriggered: clockText.time = new Date()
                    }
                }
                Text {
                    property var time: new Date()
                    text: Qt.formatDateTime(time, "ddd, d MMM")
                    color: "#bac2de"
                    font.pixelSize: 11
                    font.family: "MonaspiceKr Nerd Font"
                    anchors.right: parent.right
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

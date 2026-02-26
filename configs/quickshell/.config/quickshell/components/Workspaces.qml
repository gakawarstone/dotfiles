import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    spacing: 15
    property var screen

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
                property bool isActiveOnThisMonitor: screen && modelData.monitor && modelData.monitor.name === screen.name && modelData.active
                color: isActiveOnThisMonitor ? "#cba6f7" : (modelData.visible ? "#45475a" : "transparent")
                border.color: modelData.visible ? "#585b70" : "transparent"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (modelData.name === "1") return "󰖟";
                        if (modelData.name === "2") return "󰍡";
                        if (modelData.name === "3") return "󰞷";
                        return modelData.name;
                    }
                    color: isActiveOnThisMonitor ? "#11111b" : "#cdd6f4"
                    font.pixelSize: 16
                    font.bold: isActiveOnThisMonitor
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

import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".."

RowLayout {
    spacing: 15
    property var screen

    Text {
        text: "󰣇"
        font.pixelSize: 22
        color: Theme.blue
        font.family: "MonaspiceKr Nerd Font"
    }

    Row {
        spacing: 8
        Repeater {
            model: Hyprland.workspaces
            delegate: Rectangle {
                visible: !modelData.name.startsWith("special:")
                width: visible ? 28 : 0
                height: visible ? 28 : 0
                radius: 14
                property bool isActiveOnThisMonitor: screen && modelData.monitor && modelData.monitor.name === screen.name && modelData.active
                color: isActiveOnThisMonitor ? Theme.mauve : (modelData.visible ? Theme.surface1 : "transparent")
                border.color: modelData.visible ? Theme.surface2 : "transparent"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (modelData.name === "1") return "󰖟";
                        if (modelData.name === "2") return "󰍡";
                        if (modelData.name === "3") return "󰞷";
                        return modelData.name;
                    }
                    color: isActiveOnThisMonitor ? Theme.crust : Theme.text
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

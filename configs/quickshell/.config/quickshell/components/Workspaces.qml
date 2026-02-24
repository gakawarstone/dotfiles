import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
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
                    text: {
                        if (modelData.name === "1") return "󰖟";
                        if (modelData.name === "2") return "󰍡";
                        if (modelData.name === "3") return "󰞷";
                        return modelData.name;
                    }
                    color: modelData.active ? "#11111b" : "#cdd6f4"
                    font.pixelSize: 16
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

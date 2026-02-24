import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

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

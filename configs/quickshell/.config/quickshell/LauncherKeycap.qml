import QtQuick
import "." as Launcher

Rectangle {
    property alias text: caption.text

    implicitWidth: caption.implicitWidth + 14
    implicitHeight: caption.implicitHeight + 7
    color: Launcher.Theme.mantle
    border.color: Launcher.Theme.surface1
    radius: 6

    Text {
        id: caption
        anchors.centerIn: parent
        color: Launcher.Theme.subtext1
        font.family: "MonaspiceKr Nerd Font"
        font.pixelSize: 16
    }
}

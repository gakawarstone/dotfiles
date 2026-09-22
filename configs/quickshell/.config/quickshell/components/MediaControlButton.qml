import QtQuick
import ".."

MouseArea {
    id: control

    required property string icon
    property int iconSize: 18

    implicitWidth: 28
    implicitHeight: 28
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    Text {
        anchors.centerIn: parent
        text: control.icon
        color: !control.enabled ? Theme.overlay0
            : control.containsMouse ? Theme.mauve : Theme.text
        font.family: "MonaspiceKr Nerd Font"
        font.pixelSize: control.iconSize
    }
}

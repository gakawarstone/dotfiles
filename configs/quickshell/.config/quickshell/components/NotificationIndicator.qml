import QtQuick
import QtQuick.Layouts
import ".."

MouseArea {
    id: root

    required property var notificationCenter
    property var screen

    Component.onCompleted: notificationCenter.registerAnchor(root, screen)

    Layout.fillHeight: true
    implicitWidth: layout.implicitWidth
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: notificationCenter.toggle(root, screen)

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        Text {
            text: "󰂚"
            color: Theme.text
            font.family: "MonaspiceKr Nerd Font"
            font.pixelSize: 18
        }

        Text {
            visible: root.notificationCenter.historyCount > 0
            text: root.notificationCenter.historyCount
            color: Theme.text
            font.family: "MonaspiceKr Nerd Font"
            font.pixelSize: 12
        }
    }
}

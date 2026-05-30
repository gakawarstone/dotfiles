import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    property int value: 0
    property color fillColor: Theme.text

    implicitWidth: 110
    implicitHeight: 6

    Rectangle {
        anchors.fill: parent
        color: Theme.surface0
        radius: 3

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
            height: parent.height
            color: root.fillColor
            radius: 3
        }
    }
}

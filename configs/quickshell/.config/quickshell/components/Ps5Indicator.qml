import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

MouseArea {
    implicitWidth: 26
    implicitHeight: logo.height
    Layout.fillHeight: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Ps5Status.refresh()

    Accessible.role: Accessible.Button
    Accessible.name: "PS5 Pro · " + Ps5Status.statusText
    Accessible.onPressAction: Ps5Status.refresh()

    FileView {
        id: mark
        path: Quickshell.shellPath("components/playstation-mark.svg")
        blockLoading: true
    }

    Image {
        id: logo
        anchors.centerIn: parent
        width: 22
        height: 18
        source: "data:image/svg+xml," + encodeURIComponent(mark.text().replace("#fff", Ps5Status.statusColor.toString()))
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
    }
}

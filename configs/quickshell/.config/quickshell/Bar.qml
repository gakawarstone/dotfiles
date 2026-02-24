import Quickshell
import QtQuick
import QtQuick.Layouts
import "./components"

Rectangle {
    id: root
    color: "#1e1e2e"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 15

        // Left: Arch icon + Workspaces
        Workspaces {
            Layout.alignment: Qt.AlignLeft
        }

        // Center: Active Window Title
        WindowTitle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
        }

        // Right: System Info
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

            Battery {}
            KeyboardLayout {}
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

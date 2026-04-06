import Quickshell
import QtQuick
import QtQuick.Layouts
import "."
import "./components"

Rectangle {
    id: root
    color: Theme.base
    property var screen
    property var pomoState

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 15

        // Left: Arch icon + Workspaces
        Workspaces {
            Layout.alignment: Qt.AlignLeft
            screen: root.screen
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

            NetworkSpeed {}
            Pomodoro {
                pomoState: root.pomoState
            }
            Volume {}
            Microphone {}
            Bluetooth {}
            // Wifi {}
            // Cpu {}
            Battery {}
            KeyboardLayout {}
        }
    }

    // Brightness {}

    // Bottom border/line
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.surface0
    }
}

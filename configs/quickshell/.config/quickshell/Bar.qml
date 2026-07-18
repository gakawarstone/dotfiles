import QtQuick
import QtQuick.Layouts
import "."
import "./components"

Rectangle {
    id: root
    color: Theme.base
    property var screen
    property var pomoState
    property var notificationController

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 15

        Workspaces {
            Layout.alignment: Qt.AlignLeft
            screen: root.screen
        }

        WindowTitle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

            NetworkSpeed {}
            CodexUsage {}
            LanMouse {}
            Pomodoro {
                pomoState: root.pomoState
            }
            Volume {}
            Microphone {}
            Bluetooth {}
            Battery {}
            KeyboardLayout {}
            NotificationIndicator {
                notificationCenter: root.notificationController
                screen: root.screen
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.surface0
    }
}

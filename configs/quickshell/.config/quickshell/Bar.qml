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
    property string hostname: ""
    property bool showNetworkSpeed: hostname !== "archlinux"
    property bool showWifi: hostname === "archlinux"
    property bool showPs5: hostname === "archlinux"
    property bool showLanMouse: hostname !== "archlinux"
    property bool showPomodoro: hostname !== "archlinux"
    property bool showNotificationIndicator: hostname !== "archlinux"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 15

        Workspaces {
            Layout.alignment: Qt.AlignLeft
            screen: root.screen
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            Media {
                anchors.centerIn: parent
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

            Loader {
                active: root.showNetworkSpeed
                visible: active
                sourceComponent: NetworkSpeed {}
            }
            CodexUsage {}
            Loader {
                Layout.fillHeight: true
                active: root.showWifi
                visible: active
                sourceComponent: Wifi {}
            }
            HsflVpn {}
            Loader {
                active: root.showPs5
                visible: active
                sourceComponent: Ps5Indicator {}
            }
            Loader {
                Layout.fillHeight: true
                active: root.showLanMouse
                visible: active
                sourceComponent: LanMouse {}
            }
            Loader {
                Layout.fillHeight: true
                active: root.showPomodoro
                visible: active
                sourceComponent: Pomodoro { pomoState: root.pomoState }
            }
            Volume {}
            Microphone {}
            Bluetooth {}
            Battery {}
            KeyboardLayout {}
            Loader {
                Layout.fillHeight: true
                active: root.showNotificationIndicator
                visible: active
                sourceComponent: NotificationIndicator {
                    notificationCenter: root.notificationController
                    screen: root.screen
                }
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

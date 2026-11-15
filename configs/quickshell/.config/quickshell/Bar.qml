import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "."
import "./components"

Rectangle {
    id: root
    color: Theme.base
    property var screen
    property var pomoState
    property var notificationController
    property string hostname: ""

    // Set these properties per host using hostname. See README.md.
    property bool showWorkspaces: true
    property bool showMedia: true
    property bool showNetworkSpeed: hostname !== "archlinux"
    property bool showCodexUsage: true
    property bool showWifi: hostname === "archlinux"
    property bool showHsflVpn: true
    property bool showLanMouse: hostname !== "archlinux"
    property bool showPomodoro: hostname !== "archlinux"
    property bool showVolume: true
    property bool showMicrophone: true
    property bool showBluetooth: true
    property bool showBattery: true
    property bool showKeyboardLayout: true
    property bool showNotificationIndicator: hostname !== "archlinux"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 15

        Workspaces {
            visible: root.showWorkspaces
            Layout.alignment: Qt.AlignLeft
            screen: root.screen
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            Media {
                anchors.centerIn: parent
                visible: root.showMedia && player !== null
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

            NetworkSpeed { visible: root.showNetworkSpeed }
            CodexUsage { visible: root.showCodexUsage }
            Wifi { visible: root.showWifi }
            HsflVpn { visible: root.showHsflVpn }
            LanMouse { visible: root.showLanMouse }
            Pomodoro {
                visible: root.showPomodoro
                pomoState: root.pomoState
            }
            Volume { visible: root.showVolume }
            Microphone { visible: root.showMicrophone }
            Bluetooth { visible: root.showBluetooth }
            Battery { visible: root.showBattery && UPower.displayDevice && UPower.displayDevice.isLaptopBattery }
            KeyboardLayout { visible: root.showKeyboardLayout }
            NotificationIndicator {
                visible: root.showNotificationIndicator
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

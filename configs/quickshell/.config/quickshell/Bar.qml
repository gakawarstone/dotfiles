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
    readonly property bool isLaptop: hostname === "gklaptop"

    // Set these properties per host using hostname. See README.md.
    property bool showWorkspaces: true
    property bool showMedia: true
    property bool showNetworkSpeed: hostname !== "archlinux" && !isLaptop
    property bool showCodexUsage: true
    property bool showWifi: hostname === "archlinux" || isLaptop
    property bool showCpu: isLaptop
    property bool showHsflVpn: true
    property bool showLanMouse: hostname !== "archlinux" && !isLaptop
    property bool showPomodoro: hostname !== "archlinux" && !isLaptop
    property bool showVolume: !isLaptop
    property bool showMicrophone: !isLaptop
    property bool showBluetooth: true
    property bool showBattery: true
    property bool showKeyboardLayout: true
    property bool showNotificationIndicator: hostname !== "archlinux" && !isLaptop

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

            Loader {
                active: root.showNetworkSpeed
                visible: active
                sourceComponent: NetworkSpeed {}
            }
            CodexUsage { visible: root.showCodexUsage }
            Wifi { visible: root.showWifi && !root.isLaptop }
            HsflVpn { visible: root.showHsflVpn }
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
            Volume { visible: root.showVolume }
            Microphone { visible: root.showMicrophone }
            Wifi { visible: root.showWifi && root.isLaptop }
            Loader {
                active: root.showCpu
                visible: active
                sourceComponent: Cpu {}
            }
            Bluetooth { visible: root.showBluetooth }
            Battery { visible: root.showBattery && UPower.displayDevice && UPower.displayDevice.isLaptopBattery }
            KeyboardLayout { visible: root.showKeyboardLayout }
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

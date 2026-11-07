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
    property bool showNetworkSpeed: true
    property bool showCodexUsage: true
    property bool showWifi: false
    property bool showHsflVpn: true
    property bool showLanMouse: true
    property bool showPomodoro: true
    property bool showVolume: true
    property bool showMicrophone: true
    property bool showBluetooth: true
    property bool showBattery: true
    property bool showKeyboardLayout: true
    property bool showNotificationIndicator: true

    // Wait for the hostname binding before starting components.
    property bool componentsReady: false
    Component.onCompleted: componentsReady = true

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 15

        Loader {
            active: root.componentsReady && root.showWorkspaces
            visible: active
            Layout.alignment: Qt.AlignLeft
            sourceComponent: Workspaces { screen: root.screen }
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            Loader {
                anchors.centerIn: parent
                active: root.componentsReady && root.showMedia
                sourceComponent: Media {}
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

            Loader {
                active: root.componentsReady && root.showNetworkSpeed
                visible: active
                sourceComponent: NetworkSpeed {}
            }
            Loader {
                active: root.componentsReady && root.showCodexUsage
                visible: active
                Layout.fillHeight: true
                sourceComponent: CodexUsage {}
            }
            Loader {
                active: root.componentsReady && root.showWifi
                visible: active
                Layout.fillHeight: true
                sourceComponent: Wifi {}
            }
            Loader {
                active: root.componentsReady && root.showHsflVpn
                visible: active
                Layout.fillHeight: true
                sourceComponent: HsflVpn {}
            }
            Loader {
                active: root.componentsReady && root.showLanMouse
                visible: active
                Layout.fillHeight: true
                sourceComponent: LanMouse {}
            }
            Loader {
                active: root.componentsReady && root.showPomodoro
                visible: active
                Layout.fillHeight: true
                sourceComponent: Pomodoro { pomoState: root.pomoState }
            }
            Loader {
                active: root.componentsReady && root.showVolume
                visible: active
                Layout.fillHeight: true
                sourceComponent: Volume {}
            }
            Loader {
                active: root.componentsReady && root.showMicrophone
                visible: active
                Layout.fillHeight: true
                sourceComponent: Microphone {}
            }
            Loader {
                active: root.componentsReady && root.showBluetooth
                visible: active
                Layout.fillHeight: true
                sourceComponent: Bluetooth {}
            }
            Loader {
                active: root.componentsReady && root.showBattery
                visible: active && UPower.displayDevice && UPower.displayDevice.isLaptopBattery
                sourceComponent: Battery {}
            }
            Loader {
                active: root.componentsReady && root.showKeyboardLayout
                visible: active
                Layout.fillHeight: true
                Layout.preferredWidth: item ? item.Layout.preferredWidth : 0
                sourceComponent: KeyboardLayout {}
            }
            Loader {
                active: root.componentsReady && root.showNotificationIndicator
                visible: active
                Layout.fillHeight: true
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

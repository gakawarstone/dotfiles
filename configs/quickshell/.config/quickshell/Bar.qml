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
    // Apply the host state before any component can start.
    property bool componentsReady: false

    Component.onCompleted: componentsReady = true

    BarComponents {
        id: components
        hostname: root.hostname
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 15

        Loader {
            active: root.componentsReady && components.workspaces
            visible: active
            Layout.alignment: Qt.AlignLeft
            sourceComponent: Workspaces { screen: root.screen }
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            Loader {
                anchors.centerIn: parent
                active: root.componentsReady && components.media
                sourceComponent: Media {}
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

            Loader { active: root.componentsReady && components.networkSpeed; visible: active; sourceComponent: NetworkSpeed {} }
            Loader { active: root.componentsReady && components.codexUsage; visible: active; Layout.fillHeight: true; sourceComponent: CodexUsage {} }
            Loader { active: root.componentsReady && components.wifi; visible: active; Layout.fillHeight: true; sourceComponent: Wifi {} }
            Loader { active: root.componentsReady && components.hsflVpn; visible: active; Layout.fillHeight: true; sourceComponent: HsflVpn {} }
            Loader { active: root.componentsReady && components.lanMouse; visible: active; Layout.fillHeight: true; sourceComponent: LanMouse {} }
            Loader {
                active: root.componentsReady && components.pomodoro
                visible: active
                Layout.fillHeight: true
                sourceComponent: Pomodoro { pomoState: root.pomoState }
            }
            Loader { active: root.componentsReady && components.volume; visible: active; Layout.fillHeight: true; sourceComponent: Volume {} }
            Loader { active: root.componentsReady && components.microphone; visible: active; Layout.fillHeight: true; sourceComponent: Microphone {} }
            Loader { active: root.componentsReady && components.bluetooth; visible: active; Layout.fillHeight: true; sourceComponent: Bluetooth {} }
            Loader { active: root.componentsReady && components.battery; visible: active && UPower.displayDevice && UPower.displayDevice.isLaptopBattery; sourceComponent: Battery {} }
            Loader { active: root.componentsReady && components.keyboardLayout; visible: active; Layout.fillHeight: true; Layout.preferredWidth: item ? item.Layout.preferredWidth : 0; sourceComponent: KeyboardLayout {} }
            Loader {
                active: root.componentsReady && components.notificationIndicator
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

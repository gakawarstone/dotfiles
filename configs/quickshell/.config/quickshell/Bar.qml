import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "."
import "./components"
import "BarComponents.js" as BarComponents

Rectangle {
    id: root
    color: Theme.base
    property var screen
    property var pomoState
    property var notificationController
    property string hostname: ""

    function enabled(component) {
        return BarComponents.enabled(hostname, component);
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 15

        Loader {
            active: root.enabled("Workspaces")
            visible: active
            Layout.alignment: Qt.AlignLeft
            sourceComponent: Workspaces { screen: root.screen }
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            Loader {
                anchors.centerIn: parent
                active: root.enabled("Media")
                sourceComponent: Media {}
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

            Loader { active: root.enabled("NetworkSpeed"); visible: active; sourceComponent: NetworkSpeed {} }
            Loader { active: root.enabled("CodexUsage"); visible: active; Layout.fillHeight: true; sourceComponent: CodexUsage {} }
            Loader { active: root.enabled("Wifi"); visible: active; Layout.fillHeight: true; sourceComponent: Wifi {} }
            Loader { active: root.enabled("HsflVpn"); visible: active; Layout.fillHeight: true; sourceComponent: HsflVpn {} }
            Loader { active: root.enabled("LanMouse"); visible: active; Layout.fillHeight: true; sourceComponent: LanMouse {} }
            Loader {
                active: root.enabled("Pomodoro")
                visible: active
                Layout.fillHeight: true
                sourceComponent: Pomodoro { pomoState: root.pomoState }
            }
            Loader { active: root.enabled("Volume"); visible: active; Layout.fillHeight: true; sourceComponent: Volume {} }
            Loader { active: root.enabled("Microphone"); visible: active; Layout.fillHeight: true; sourceComponent: Microphone {} }
            Loader { active: root.enabled("Bluetooth"); visible: active; Layout.fillHeight: true; sourceComponent: Bluetooth {} }
            Loader { active: root.enabled("Battery"); visible: active && UPower.displayDevice && UPower.displayDevice.isLaptopBattery; sourceComponent: Battery {} }
            Loader { active: root.enabled("KeyboardLayout"); visible: active; Layout.fillHeight: true; Layout.preferredWidth: item ? item.Layout.preferredWidth : 0; sourceComponent: KeyboardLayout {} }
            Loader {
                active: root.enabled("NotificationIndicator")
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

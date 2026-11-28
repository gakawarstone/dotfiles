import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "."
import "./components"

ShellRoot {
    id: shellRoot

    FileView {
        id: hostnameFile
        path: "/proc/sys/kernel/hostname"
        blockLoading: true
        printErrors: false
    }

    NotificationCenter {
        id: notificationCenter
    }

    AppLauncher {}
    GameLauncher {}
    EnergyMeter {}
    Ps5LaunchWindow {}

    Pomodoro.TimerLogic {
        id: globalPomoState
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: window
            required property var modelData
            screen: modelData
            visible: modelData.name !== "IPAD" && modelData.name !== "IPHONE"

            WlrLayershell.layer: WlrLayershell.Bottom

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 40
            color: "transparent"

            Bar {
                id: bar
                anchors.fill: parent
                screen: modelData
                hostname: hostnameFile.text().trim()
                pomoState: globalPomoState
                notificationController: notificationCenter

                Component.onCompleted: {
                    if (window.visible) notificationCenter.registerAnchor(bar, modelData)
                }
            }
        }
    }
}

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
    EnergyMeter {}

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
                anchors.fill: parent
                screen: modelData
                hostname: hostnameFile.text().trim()
                pomoState: globalPomoState
                notificationController: notificationCenter
            }
        }
    }
}

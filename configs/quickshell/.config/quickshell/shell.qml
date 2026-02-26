import Quickshell
import Quickshell.Wayland
import QtQuick
import "./components"

ShellRoot {
    id: shellRoot

    // This uses the TimerLogic defined inside Pomodoro.qml
    Pomodoro.TimerLogic {
        id: globalPomoState
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: window
            required property var modelData
            screen: modelData

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
                pomoState: globalPomoState
            }
        }
    }
}

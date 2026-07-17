import Quickshell
import Quickshell.Wayland
import QtQuick
import "."
import "./components"

ShellRoot {
    id: shellRoot

    Pomodoro.TimerLogic {
        id: globalPomoState
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: window
            required property var modelData
            screen: modelData

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
                pomoState: globalPomoState
            }
        }
    }
}

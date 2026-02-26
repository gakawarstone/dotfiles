import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

MouseArea {
    id: root
    Layout.fillHeight: true
    implicitWidth: layout.implicitWidth
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

    property var pomoState

    // This is the shared logic that will be instantiated in shell.qml
    component TimerLogic : Item {
        property int workTime: 15 * 60
        property int restTime: 15 * 60
        property int timeLeft: workTime
        property bool isRunning: false
        property string mode: "work"

        function toggle() {
            isRunning = !isRunning
        }

        function reset() {
            isRunning = false
            mode = "work"
            timeLeft = workTime
        }

        function nextMode() {
            if (mode === "work") {
                mode = "rest"
                timeLeft = restTime
                notifyProcess.command = ["notify-send", "Pomodoro", "Work session finished! Time to rest.", "-i", "timer-symbolic"]
            } else {
                mode = "work"
                timeLeft = workTime
                notifyProcess.command = ["notify-send", "Pomodoro", "Rest finished! Back to work.", "-i", "timer-symbolic"]
            }
            notifyProcess.running = true
        }

        Timer {
            interval: 1000
            running: parent.isRunning
            repeat: true
            onTriggered: {
                if (parent.timeLeft > 0) {
                    parent.timeLeft--
                } else {
                    parent.nextMode()
                }
            }
        }

        Process {
            id: notifyProcess
        }
    }

    onClicked: (mouse) => {
        if (!pomoState) return;
        if (mouse.button === Qt.LeftButton) {
            pomoState.toggle()
        } else if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) {
            pomoState.reset()
        }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        Text {
            text: (pomoState && pomoState.mode === "work") ? "󱎫" : "󱐌"
            font.pixelSize: 18
            color: {
                if (!pomoState || !pomoState.isRunning) return "#fab387" // Peach when paused
                return pomoState.mode === "work" ? "#f38ba8" : "#a6e3a1"
            }
            font.family: "MonaspiceKr Nerd Font"
        }

        Text {
            property int minutes: pomoState ? Math.floor(pomoState.timeLeft / 60) : 0
            property int seconds: pomoState ? pomoState.timeLeft % 60 : 0
            text: minutes.toString().padStart(2, '0') + ":" + seconds.toString().padStart(2, '0')
            color: "#cdd6f4"
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }
    }
}

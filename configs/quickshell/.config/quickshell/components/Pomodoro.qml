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

    property int workTime: 15 * 60
    property int restTime: 15 * 60
    property int timeLeft: workTime
    property bool isRunning: false
    property string mode: "work" // "work" or "rest"

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

    Process {
        id: notifyProcess
    }

    Timer {
        id: timer
        interval: 1000
        running: root.isRunning
        repeat: true
        onTriggered: {
            if (root.timeLeft > 0) {
                root.timeLeft--
            } else {
                root.nextMode()
            }
        }
    }

    onClicked: (mouse) => {
        if (mouse.button === Qt.LeftButton) {
            toggle()
        } else if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) {
            reset()
        }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        Text {
            text: root.mode === "work" ? "󱎫" : "󱐌"
            font.pixelSize: 18
            color: {
                if (!root.isRunning) return "#fab387" // Peach when paused
                return root.mode === "work" ? "#f38ba8" : "#a6e3a1"
            }
            font.family: "MonaspiceKr Nerd Font"
        }

        Text {
            property int minutes: Math.floor(root.timeLeft / 60)
            property int seconds: root.timeLeft % 60
            text: minutes.toString().padStart(2, '0') + ":" + seconds.toString().padStart(2, '0')
            color: "#cdd6f4"
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }
    }
}

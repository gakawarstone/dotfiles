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

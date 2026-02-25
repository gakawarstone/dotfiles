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

    property bool menuOpen: false
    property real volume: 0
    property bool muted: false

    function updateVolume() {
        volumeProcess.running = true;
    }

    Process {
        id: volumeProcess
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return;
                const cleanText = text.trim();
                // Format: "Volume: 0.20" or "Volume: 0.20 [MUTED]"
                const parts = cleanText.split(" ");
                if (parts.length >= 2) {
                    root.volume = parseFloat(parts[1]);
                    root.muted = cleanText.includes("[MUTED]");
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.updateVolume()
    }

    Component.onCompleted: root.updateVolume()

    onClicked: menuOpen = !menuOpen

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        Text {
            text: {
                if (root.muted || root.volume === 0) return "󰝟"
                if (root.volume < 0.33) return "󰕿"
                if (root.volume < 0.66) return "󰖀"
                return "󰕾"
            }
            font.pixelSize: 18
            color: !root.muted ? "#89b4fa" : "#f38ba8"
            font.family: "MonaspiceKr Nerd Font"
        }
    }

    VolumePopup {
        visible: root.menuOpen
        anchorItem: root
        volume: root.volume
        muted: root.muted

        onVisibleChanged: {
            if (!visible) root.menuOpen = false;
        }
        
        onVolumeUpdate: (volume) => {
            root.volume = volume;
        }
        
        onMuteUpdate: (muted) => {
            root.muted = muted;
        }
    }
}

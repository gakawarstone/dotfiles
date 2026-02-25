import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Wayland

PopupWindow {
    id: popup
    
    property var anchorItem
    property real volume: 0
    property bool muted: false

    signal volumeUpdate(real volume)
    signal muteUpdate(bool muted)

    color: "transparent"
    width: content.width
    height: content.height
    
    anchor {
        item: popup.anchorItem
    }

    relativeX: -100
    relativeY: popup.anchorItem ? popup.anchorItem.height + 5 : 0

    Process {
        id: setVolumeProcess
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", popup.volume.toFixed(2)]
    }

    Process {
        id: toggleMuteProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Rectangle {
        id: content
        width: 250
        height: mainColumn.implicitHeight + 20
        color: "#1e1e2e"
        border.color: "#313244"
        border.width: 1
        radius: 8

        ColumnLayout {
            id: mainColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 15
            spacing: 15

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Volume"
                    color: "#cdd6f4"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "MonaspiceKr Nerd Font"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(popup.volume * 100) + "%"
                    color: "#cdd6f4"
                    font.pixelSize: 14
                    font.family: "MonaspiceKr Nerd Font"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#313244"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: {
                        if (popup.muted || popup.volume === 0) return "󰝟"
                        if (popup.volume < 0.33) return "󰕿"
                        if (popup.volume < 0.66) return "󰖀"
                        return "󰕾"
                    }
                    font.pixelSize: 20
                    color: !popup.muted ? "#89b4fa" : "#f38ba8"
                    font.family: "MonaspiceKr Nerd Font"
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            popup.muted = !popup.muted;
                            popup.muteUpdate(popup.muted);
                            toggleMuteProcess.running = true;
                        }
                    }
                }

                // Volume Slider
                Rectangle {
                    id: sliderTrack
                    Layout.fillWidth: true
                    height: 6
                    color: "#313244"
                    radius: 3

                    Rectangle {
                        width: sliderTrack.width * Math.min(popup.volume, 1.0)
                        height: parent.height
                        color: !popup.muted ? "#89b4fa" : "#6c7086"
                        radius: 3
                    }

                    MouseArea {
                        anchors.fill: parent
                        property bool dragging: false
                        
                        function updateVolume(mouse) {
                            let val = Math.max(0, Math.min(1.5, mouse.x / width)); // Allow up to 150%
                            popup.volume = val;
                            popup.volumeUpdate(val);
                            setVolumeProcess.running = true;
                        }

                        onPressed: (mouse) => {
                            dragging = true;
                            updateVolume(mouse);
                        }
                        onPositionChanged: (mouse) => {
                            if (dragging) updateVolume(mouse);
                        }
                        onReleased: dragging = false
                    }
                }
            }
        }
    }
}

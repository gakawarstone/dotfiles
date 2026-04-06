import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Wayland
import ".."

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
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", popup.volume.toFixed(2)]
    }

    Process {
        id: toggleMuteProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }

    Rectangle {
        id: content
        implicitWidth: 250
        implicitHeight: mainColumn.implicitHeight + 30
        color: Theme.base
        border.color: Theme.surface0
        border.width: 1
        radius: 8

        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Microphone"
                    color: Theme.text
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "MonaspiceKr Nerd Font"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(popup.volume * 100) + "%"
                    color: Theme.text
                    font.pixelSize: 14
                    font.family: "MonaspiceKr Nerd Font"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.surface0
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: popup.muted ? "󰍭" : "󰍬"
                    font.pixelSize: 20
                    color: !popup.muted ? Theme.peach : Theme.red
                    font.family: "MonaspiceKr Nerd Font"
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            popup.muteUpdate(!popup.muted);
                            toggleMuteProcess.running = true;
                        }
                    }
                }

                // Volume Slider
                Rectangle {
                    id: sliderTrack
                    Layout.fillWidth: true
                    height: 6
                    color: Theme.surface0
                    radius: 3

                    Rectangle {
                        width: sliderTrack.width * Math.min(popup.volume, 1.0)
                        height: parent.height
                        color: !popup.muted ? Theme.peach : Theme.overlay0
                        radius: 3
                    }

                    MouseArea {
                        anchors.fill: parent
                        property bool dragging: false
                        
                        function updateVolume(mouse) {
                            let val = Math.max(0, Math.min(1.5, mouse.x / width)); // Allow up to 150%
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

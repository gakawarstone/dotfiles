import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: root

    required property var anchorItem
    required property string audioNode
    required property string label
    required property string icon
    required property color accentColor
    property color iconColor: accentColor
    property real volume: 0
    property bool muted: false

    signal volumeUpdate(real volume)
    signal muteUpdate(bool muted)

    anchor.item: root.anchorItem
    relativeX: -100
    relativeY: root.anchorItem ? root.anchorItem.height + 5 : 0
    width: content.width
    height: content.height
    color: "transparent"

    Process {
        id: setVolumeProcess
        command: ["wpctl", "set-volume", root.audioNode, root.volume.toFixed(2)]
    }

    Process {
        id: toggleMuteProcess
        command: ["wpctl", "set-mute", root.audioNode, "toggle"]
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
                    text: root.label
                    color: Theme.text
                    font.bold: true
                    font.family: "MonaspiceKr Nerd Font"
                    font.pixelSize: 16
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(root.volume * 100) + "%"
                    color: Theme.text
                    font.family: "MonaspiceKr Nerd Font"
                    font.pixelSize: 14
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
                    text: root.icon
                    color: root.iconColor
                    font.family: "MonaspiceKr Nerd Font"
                    font.pixelSize: 20

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.muteUpdate(!root.muted);
                            toggleMuteProcess.running = true;
                        }
                    }
                }

                Rectangle {
                    id: sliderTrack
                    Layout.fillWidth: true
                    height: 6
                    color: Theme.surface0
                    radius: 3

                    Rectangle {
                        width: sliderTrack.width * Math.min(root.volume, 1)
                        height: parent.height
                        color: root.muted ? Theme.overlay0 : root.accentColor
                        radius: 3
                    }

                    MouseArea {
                        anchors.fill: parent
                        property bool dragging: false

                        function updateVolume(mouse) {
                            const value = Math.max(0, Math.min(1.5, mouse.x / width));
                            root.volumeUpdate(value);
                            setVolumeProcess.running = true;
                        }

                        onPressed: mouse => {
                            dragging = true;
                            updateVolume(mouse);
                        }
                        onPositionChanged: mouse => {
                            if (dragging) updateVolume(mouse);
                        }
                        onReleased: dragging = false
                    }
                }
            }
        }
    }
}

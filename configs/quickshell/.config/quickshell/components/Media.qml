import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import ".."

MouseArea {
    id: root

    readonly property var players: Mpris.players.values
    property string selectedPlayer: ""
    readonly property MprisPlayer player: {
        const selected = players.find(p => p.dbusName === selectedPlayer);
        return selected || players.find(p => p.isPlaying) || players[0] || null;
    }
    property bool menuOpen: false
    property var levels: [0, 0, 0, 0, 0]

    Layout.fillHeight: true
    implicitWidth: island.implicitWidth
    implicitHeight: island.implicitHeight
    visible: player !== null
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: menuOpen = !menuOpen
    onPlayerChanged: {
        if (!player) menuOpen = false;
    }
    onPlayersChanged: {
        if (!players.some(p => p.dbusName === selectedPlayer)) selectedPlayer = "";
    }

    Process {
        command: ["python3", Quickshell.shellPath("scripts/media-spectrum.py")]
        running: root.player !== null && root.player.isPlaying && root.visible
        stdout: SplitParser {
            onRead: data => {
                const values = data.split(",").map(Number);
                if (values.length === 5 && values.every(Number.isFinite)) root.levels = values;
            }
        }
        onRunningChanged: {
            if (!running) root.levels = [0, 0, 0, 0, 0];
        }
    }

    Rectangle {
        id: island
        anchors.centerIn: parent
        implicitWidth: 240
        implicitHeight: 34
        radius: height / 2
        color: root.containsMouse ? Theme.mantle : Theme.crust
        border.color: root.menuOpen ? Theme.mauve : Theme.surface0
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 9

            Item {
                id: coverItem
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: Theme.surface0
                }

                Text {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: "\uf001"
                    color: root.player && root.player.isPlaying ? Theme.mauve : Theme.overlay1
                    font.family: "MonaspiceKr Nerd Font"
                    font.pixelSize: 14
                }

                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: cover
                    visible: cover.status === Image.Ready

                    maskSource: Rectangle {
                        width: coverItem.width
                        height: coverItem.height
                        radius: 7
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: -2

                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackTitle || root.player.identity : ""
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: "MonaspiceKr Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackArtist : ""
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Theme.overlay1
                    font.family: "MonaspiceKr Nerd Font"
                    font.pixelSize: 9
                }
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 18
                spacing: 3

                Repeater {
                    model: 5

                    Rectangle {
                        required property int index
                        width: 3
                        height: root.player && root.player.isPlaying ? 3 + 14 * root.levels[index] : 7
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.player && root.player.isPlaying ? Theme.mauve : Theme.overlay0

                        Behavior on height {
                            SmoothedAnimation { velocity: 100; maximumEasingTime: 90 }
                        }
                    }
                }
            }
        }
    }

    MediaPopup {
        anchorItem: root
        player: root.player
        players: root.players
        visible: root.menuOpen && root.player !== null
        onPlayerSelected: dbusName => root.selectedPlayer = dbusName
        onVisibleChanged: {
            if (!visible) root.menuOpen = false;
        }
    }
}

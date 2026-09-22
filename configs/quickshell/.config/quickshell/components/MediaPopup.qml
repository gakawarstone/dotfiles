import Quickshell
import QtQuick
import QtQuick.Layouts
import "."
import ".."

PopupWindow {
    id: popup

    required property var anchorItem
    required property var player
    required property var players
    property real shownPosition: 0
    readonly property string popupFont: "MonaspiceKr Nerd Font"

    signal playerSelected(string dbusName)

    function formatTime(seconds) {
        if (!Number.isFinite(seconds) || seconds < 0) return "0:00";
        const wholeSeconds = Math.floor(seconds);
        const minutes = Math.floor(wholeSeconds / 60);
        const remainder = wholeSeconds % 60;
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
    }

    function updatePosition() {
        if (popup.player && !seekArea.dragging)
            popup.shownPosition = popup.player.position;
    }

    anchor {
        item: popup.anchorItem
        rect.x: popup.anchorItem ? (popup.anchorItem.width - popup.implicitWidth) / 2 : 0
        rect.y: popup.anchorItem ? popup.anchorItem.height + 5 : 0
    }
    implicitWidth: content.width
    implicitHeight: content.height
    color: "transparent"

    onPlayerChanged: updatePosition()
    onVisibleChanged: {
        if (visible) updatePosition();
    }

    Timer {
        interval: 1000
        running: popup.visible && popup.player !== null
        repeat: true
        onTriggered: popup.updatePosition()
    }

    Rectangle {
        id: content
        implicitWidth: 380
        implicitHeight: mainColumn.implicitHeight + 30
        color: Theme.base
        border.color: Theme.surface0
        border.width: 1
        radius: 10

        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            anchors.margins: 15
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96
                    radius: 8
                    color: Theme.surface0
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        text: "\uf001"
                        color: Theme.overlay0
                        font.family: popup.popupFont
                        font.pixelSize: 34
                    }

                    Image {
                        anchors.fill: parent
                        source: popup.player ? popup.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        Layout.fillWidth: true
                        text: popup.player ? popup.player.trackTitle || "Nothing playing" : ""
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: Theme.text
                        font.family: popup.popupFont
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: popup.player ? popup.player.trackArtist || popup.player.identity : ""
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: Theme.subtext0
                        font.family: popup.popupFont
                        font.pixelSize: 13
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: popup.player ? popup.player.trackAlbum : ""
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: Theme.overlay1
                        font.family: popup.popupFont
                        font.pixelSize: 12
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 18

                        MediaControlButton {
                            icon: "\uf048"
                            enabled: popup.player && popup.player.canGoPrevious
                            onClicked: popup.player.previous()
                        }

                        MediaControlButton {
                            icon: popup.player && popup.player.isPlaying ? "\uf04c" : "\uf04b"
                            iconSize: 24
                            enabled: popup.player && popup.player.canTogglePlaying
                            onClicked: popup.player.togglePlaying()
                        }

                        MediaControlButton {
                            icon: "\uf051"
                            enabled: popup.player && popup.player.canGoNext
                            onClicked: popup.player.next()
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: popup.player && popup.player.positionSupported
                    && popup.player.lengthSupported && popup.player.length > 0
                spacing: 5

                Rectangle {
                    id: seekTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.surface0

                    Rectangle {
                        width: seekTrack.width * Math.max(0, Math.min(1,
                            popup.shownPosition / Math.max(1, popup.player ? popup.player.length : 1)))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.mauve
                    }

                    MouseArea {
                        id: seekArea
                        anchors.fill: parent
                        anchors.topMargin: -6
                        anchors.bottomMargin: -6
                        enabled: popup.player && popup.player.canSeek
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        property bool dragging: false

                        function updatePosition(mouse) {
                            const ratio = Math.max(0, Math.min(1, mouse.x / width));
                            popup.shownPosition = ratio * popup.player.length;
                        }

                        onPressed: mouse => {
                            dragging = true;
                            updatePosition(mouse);
                        }
                        onPositionChanged: mouse => {
                            if (dragging) updatePosition(mouse);
                        }
                        onReleased: mouse => {
                            updatePosition(mouse);
                            popup.player.position = popup.shownPosition;
                            dragging = false;
                        }
                        onCanceled: dragging = false
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: popup.formatTime(popup.shownPosition)
                        color: Theme.overlay1
                        font.family: popup.popupFont
                        font.pixelSize: 11
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: popup.formatTime(popup.player ? popup.player.length : 0)
                        color: Theme.overlay1
                        font.family: popup.popupFont
                        font.pixelSize: 11
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                visible: popup.players.length > 1
                spacing: 6

                Repeater {
                    model: popup.players

                    delegate: Rectangle {
                        required property var modelData
                        width: Math.min(playerName.implicitWidth + 18, 170)
                        height: 26
                        radius: 6
                        color: popup.player && modelData.dbusName === popup.player.dbusName
                            ? Theme.surface1 : Theme.surface0

                        Text {
                            id: playerName
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            text: modelData.identity
                            color: popup.player && modelData.dbusName === popup.player.dbusName
                                ? Theme.mauve : Theme.subtext0
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                            font.family: popup.popupFont
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.playerSelected(modelData.dbusName)
                        }
                    }
                }
            }
        }
    }
}

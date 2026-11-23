import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import "."

FloatingWindow {
    id: root

    property string game: ""
    property string stage: "idle"
    property string message: ""
    readonly property bool pending: stage === "checking" || stage === "waiting" || stage === "connecting"

    title: "Запуск PS5 Pro"
    visible: false
    color: Theme.base
    implicitWidth: 440
    implicitHeight: 200
    minimumSize: Qt.size(440, 200)
    maximumSize: minimumSize

    IpcHandler {
        target: "ps5-launch"

        function status(game: string, stage: string, message: string): void {
            if (stage === "busy" && root.pending) {
                root.visible = true;
                return;
            }

            const show = root.stage === "idle" || stage === "checking" || stage === "error" || stage === "busy";
            root.game = game;
            root.stage = stage;
            root.message = message;
            if (show)
                root.visible = true;
        }
    }

    Timer {
        interval: 1800
        running: root.stage === "connecting"
        onTriggered: {
            root.visible = false;
            root.stage = "idle";
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Image {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: "components/playstation-mark.svg"
                fillMode: Image.PreserveAspectFit
            }

            Text {
                Layout.fillWidth: true
                text: root.game
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: 22
                font.weight: Font.DemiBold
                color: Theme.text
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: root.message
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            font.pixelSize: 15
            color: root.stage === "error" ? Theme.red : Theme.subtext1
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Rectangle {
                id: track
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                color: Theme.surface0
                radius: 2
                clip: true
                opacity: root.pending ? 1 : 0

                Rectangle {
                    id: segment
                    height: track.height
                    width: track.width / 4
                    radius: track.radius
                    color: Theme.blue

                    SequentialAnimation on x {
                        running: root.visible && root.pending
                        loops: Animation.Infinite
                        NumberAnimation { from: -segment.width; to: track.width; duration: 1350 }
                    }
                }
            }

            Controls.Button {
                id: hideButton
                text: root.pending ? "Скрыть" : "Закрыть"
                implicitWidth: 90
                implicitHeight: 32
                onClicked: root.visible = false

                contentItem: Text {
                    text: hideButton.text
                    color: Theme.text
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: hideButton.down ? Theme.surface2 : hideButton.hovered ? Theme.surface1 : Theme.surface0
                    border.color: hideButton.visualFocus ? Theme.blue : "transparent"
                    radius: 6
                }
            }
        }
    }
}

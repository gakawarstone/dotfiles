import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import "."

ShellRoot {
    id: root

    function quitIfFinished(): void {
        if (!picker.visible && !progress.visible && !launcher.running)
            Qt.quit();
    }

    FloatingWindow {
        id: picker

        readonly property var games: [
            { key: "gta-vi", title: "GTA VI" },
            { key: "fc-27", title: "FC 27" },
            { key: "god-of-war-ragnarok", title: "God of War Ragnarök" },
            { key: "astros-playroom", title: "Astro’s Playroom" }
        ]
        property int selectedIndex: 0
        readonly property var selectedGame: games[selectedIndex]

        title: "Запуск PS5 Pro"
        visible: true
        color: Theme.base
        implicitWidth: 560
        implicitHeight: 304
        minimumSize: Qt.size(560, 304)
        maximumSize: minimumSize
        onVisibleChanged: if (!visible) Qt.callLater(root.quitIfFinished)

        Shortcut {
            sequence: "Escape"
            onActivated: picker.visible = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            enabled: !launcher.running
            spacing: 16

            Text {
                text: "Игры PS5 Pro"
                color: Theme.text
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Controls.ButtonGroup { id: gameGroup }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: picker.games

                    Controls.RadioButton {
                        id: card

                        required property int index
                        required property var modelData
                        readonly property string artworkIcon: DesktopEntries.applications.values
                            .find(entry => entry.id === modelData.key + "-ps5")?.icon ?? ""

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 1
                        Controls.ButtonGroup.group: gameGroup
                        checked: index === picker.selectedIndex
                        onClicked: picker.selectedIndex = index
                        text: modelData.title
                        padding: 9
                        indicator: Item {}

                        background: Rectangle {
                            radius: 8
                            color: card.checked || card.hovered ? Theme.surface0 : Theme.mantle
                            border.color: card.checked || card.visualFocus ? Theme.blue : Theme.surface0
                        }

                        contentItem: RowLayout {
                            spacing: 11

                            Item {
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 64

                                Image {
                                    id: cover
                                    anchors.fill: parent
                                    source: card.artworkIcon ? Quickshell.iconPath(card.artworkIcon) : ""
                                    sourceSize: Qt.size(128, 128)
                                    fillMode: Image.PreserveAspectFit
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
                                    source: "components/playstation-mark.svg"
                                    fillMode: Image.PreserveAspectFit
                                    visible: cover.status !== Image.Ready
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: card.text
                                textFormat: Text.PlainText
                                wrapMode: Text.WordWrap
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: Theme.text
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Controls.Switch {
                    id: frameGeneration
                    text: "Генерация кадров"
                    checked: true
                    palette.windowText: Theme.text
                    palette.text: Theme.text
                    palette.highlight: Theme.blue
                }

                Item { Layout.fillWidth: true }

                Controls.Button {
                    id: launchButton
                    text: "Запустить"
                    implicitWidth: 118
                    implicitHeight: 36
                    onClicked: launcher.running = true

                    contentItem: Text {
                        text: launchButton.text
                        color: Theme.base
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: launchButton.down ? Theme.sapphire : Theme.blue
                        border.color: launchButton.visualFocus ? Theme.text : "transparent"
                    }
                }
            }
        }
    }

    Ps5LaunchWindow {
        id: progress
        onVisibleChanged: {
            if (visible)
                picker.visible = false;
            else
                Qt.callLater(root.quitIfFinished);
        }
    }

    Process {
        id: launcher
        command: [
            "/usr/bin/uv", "run", "--no-project", "--script",
            Quickshell.env("HOME") + "/.local/share/gta-vi-ps5/launch.py",
            picker.selectedGame.key,
            "--frame-generation", frameGeneration.checked ? "on" : "off",
            "--progress-instance", Quickshell.instanceId
        ]
        onExited: (exitCode, exitStatus) => {
            if ((exitCode !== 0 || exitStatus !== 0) && progress.stage !== "error" && progress.stage !== "busy") {
                const game = picker.selectedGame;
                progress.updateStatus(game.title, game.key + "-ps5", "error", "Не удалось запустить игру.");
            }
            Qt.callLater(root.quitIfFinished);
        }
    }
}

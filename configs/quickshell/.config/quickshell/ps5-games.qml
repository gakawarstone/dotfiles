import Quickshell
import Quickshell.Io
import Quickshell.Widgets
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
            // The GTA VI shortcut artwork includes a narrow purple frame.
            { key: "gta-vi", title: "GTA VI", coverScale: 1.055 },
            { key: "fc-27", title: "FC 27" },
            { key: "god-of-war-ragnarok", title: "God of War Ragnarök" },
            { key: "astros-playroom", title: "Astro’s Playroom" }
        ]
        title: "Запуск PS5 Pro"
        visible: true
        color: Theme.base
        implicitWidth: 1008
        implicitHeight: 358
        minimumSize: Qt.size(implicitWidth, implicitHeight)
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

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Игры PS5 Pro"
                    color: Theme.text
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }

                Controls.Switch {
                    id: frameGeneration
                    text: "Генерация кадров"
                    checked: true
                    horizontalPadding: 11
                    verticalPadding: 7
                    spacing: 10
                    hoverEnabled: true

                    contentItem: Text {
                        text: frameGeneration.text
                        rightPadding: track.width + frameGeneration.spacing
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.text
                    }

                    background: Rectangle {
                        radius: 8
                        color: frameGeneration.hovered ? Theme.surface0 : Theme.mantle
                        border.color: frameGeneration.visualFocus ? Theme.blue : Theme.surface0
                    }

                    indicator: Rectangle {
                        id: track
                        implicitWidth: 34
                        implicitHeight: 18
                        x: frameGeneration.width - width - frameGeneration.rightPadding
                        y: (frameGeneration.height - height) / 2
                        radius: height / 2
                        color: frameGeneration.checked ? Qt.alpha(Theme.blue, 0.22) : Theme.surface1

                        Rectangle {
                            x: 3 + frameGeneration.visualPosition * (track.width - width - 6)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: width
                            radius: width / 2
                            color: frameGeneration.checked ? Theme.blue : Theme.overlay1

                            Behavior on x { NumberAnimation { duration: 120 } }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                uniformCellSizes: true

                Repeater {
                    model: picker.games

                    Controls.Button {
                        id: card

                        required property var modelData
                        readonly property string artworkIcon: DesktopEntries.applications.values
                            .find(entry => entry.id === modelData.key + "-ps5")?.icon ?? ""

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: modelData.title
                        padding: 0
                        horizontalPadding: 0
                        background: null
                        hoverEnabled: true
                        onClicked: {
                            launcher.game = modelData;
                            launcher.running = true;
                        }

                        contentItem: ColumnLayout {
                            spacing: 10

                            ClippingRectangle {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 232
                                Layout.preferredHeight: Layout.preferredWidth
                                radius: 10
                                color: Theme.surface0
                                contentUnderBorder: true
                                border.width: card.hovered || card.visualFocus ? 2 : 0
                                border.color: Theme.blue
                                opacity: card.down ? 0.85 : 1

                                Image {
                                    id: cover
                                    anchors.fill: parent
                                    source: card.artworkIcon ? Quickshell.iconPath(card.artworkIcon) : ""
                                    sourceSize: Qt.size(512, 512)
                                    fillMode: Image.PreserveAspectCrop
                                    scale: card.modelData.coverScale ?? 1
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: 36
                                    height: 36
                                    source: "components/playstation-mark.svg"
                                    fillMode: Image.PreserveAspectFit
                                    visible: cover.status !== Image.Ready
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: card.text
                                textFormat: Text.PlainText
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: Theme.text
                            }
                        }
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
        property var game: null
        command: game ? [
            "/usr/bin/uv", "run", "--no-project", "--script",
            Quickshell.env("HOME") + "/.local/share/gta-vi-ps5/launch.py",
            game.key,
            "--frame-generation", frameGeneration.checked ? "on" : "off",
            "--progress-instance", Quickshell.instanceId
        ] : []
        onExited: (exitCode, exitStatus) => {
            if ((exitCode !== 0 || exitStatus !== 0) && progress.stage !== "error" && progress.stage !== "busy") {
                progress.updateStatus(game.title, game.key + "-ps5", "error", "Не удалось запустить игру.");
            }
            Qt.callLater(root.quitIfFinished);
        }
    }
}

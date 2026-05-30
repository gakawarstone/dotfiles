import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import ".."

PopupWindow {
    id: popup

    property var anchorItem
    property string statusColor: "muted"
    property int primaryUsed: 0
    property int primaryLeft: 0
    property int secondaryUsed: 0
    property int secondaryLeft: 0
    property string primaryReset: "?"
    property string secondaryReset: "?"
    readonly property string popupFont: "MonaspiceKr Nerd Font"

    function barColor(value) {
        if (value > 50) return Theme.green
        if (value > 25) return Theme.yellow
        return Theme.red
    }

    color: "transparent"
    width: content.width
    height: content.height

    anchor {
        item: popup.anchorItem
    }

    relativeX: -120
    relativeY: popup.anchorItem ? popup.anchorItem.height + 5 : 0

    Rectangle {
        id: content
        implicitWidth: 300
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

            Text {
                text: "Codex"
                color: Theme.text
                font.pixelSize: 16
                font.bold: true
                font.family: popup.popupFont
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.surface0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.preferredWidth: 58
                        text: "5 hour"
                        color: Theme.text
                        font.pixelSize: 14
                        font.family: popup.popupFont
                    }

                    UsageBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        Layout.alignment: Qt.AlignVCenter
                        value: popup.primaryLeft
                        fillColor: popup.barColor(popup.primaryLeft)
                    }

                    Text {
                        Layout.preferredWidth: 36
                        text: popup.primaryLeft + "%"
                        color: Theme.text
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: 14
                        font.family: popup.popupFont
                    }

                }

                Text {
                    Layout.fillWidth: true
                    text: "reset in " + popup.primaryReset
                    color: Theme.text
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: 14
                    font.family: popup.popupFont
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.preferredWidth: 58
                        text: "Week"
                        color: Theme.text
                        font.pixelSize: 14
                        font.family: popup.popupFont
                    }

                    UsageBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        Layout.alignment: Qt.AlignVCenter
                        value: popup.secondaryLeft
                        fillColor: popup.barColor(popup.secondaryLeft)
                    }

                    Text {
                        Layout.preferredWidth: 36
                        text: popup.secondaryLeft + "%"
                        color: Theme.text
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: 14
                        font.family: popup.popupFont
                    }

                }

                Text {
                    Layout.fillWidth: true
                    text: "reset " + popup.secondaryReset
                    color: Theme.text
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: 14
                    font.family: popup.popupFont
                }
            }
        }
    }
}

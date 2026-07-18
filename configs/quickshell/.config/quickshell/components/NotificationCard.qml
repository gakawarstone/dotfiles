import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string appName: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property string timestamp: ""
    property int urgency: 1
    property var closeAction
    property bool outlined: true
    property bool interactive: true

    readonly property color accentColor: urgency === 2 ? Theme.red : (urgency === 0 ? Theme.overlay1 : Theme.mauve)

    implicitHeight: content.implicitHeight + 24
    color: interactive && mouseArea.containsMouse ? Theme.surface0 : (outlined ? Theme.base : "transparent")
    border.color: outlined ? accentColor : "transparent"
    border.width: outlined ? 1 : 0
    radius: outlined ? 8 : 4

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.interactive && root.closeAction) root.closeAction()
        }
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            Layout.alignment: Qt.AlignTop
            color: Theme.surface0
            radius: 8

            Text {
                anchors.centerIn: parent
                text: "󰂚"
                color: root.accentColor
                font.family: "MonaspiceKr Nerd Font"
                font.pixelSize: 24
            }

            Image {
                anchors.fill: parent
                anchors.margins: 7
                source: root.appIcon ? Quickshell.iconPath(root.appIcon, true) : ""
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.summary || root.appName || "Notification"
                    color: Theme.text
                    elide: Text.ElideRight
                    font.family: "MonaspiceKr Nerd Font"
                    font.pixelSize: 18
                    font.bold: true
                }

                Text {
                    visible: root.timestamp.length > 0
                    text: root.timestamp
                    color: Theme.overlay1
                    font.family: "MonaspiceKr Nerd Font"
                    font.pixelSize: 13
                }

                Text {
                    text: "󰅖"
                    color: closeMouse.containsMouse ? Theme.red : Theme.overlay1
                    font.family: "MonaspiceKr Nerd Font"
                    font.pixelSize: 18

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            mouse.accepted = true
                            if (root.closeAction) root.closeAction()
                        }
                    }
                }
            }

            Text {
                visible: root.appName.length > 0 && root.appName !== root.summary
                text: root.appName
                color: root.accentColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                font.family: "MonaspiceKr Nerd Font"
                font.pixelSize: 14
            }

            Text {
                visible: root.body.length > 0
                text: root.body
                textFormat: Text.PlainText
                color: Theme.subtext0
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                Layout.fillWidth: true
                font.family: "MonaspiceKr Nerd Font"
                font.pixelSize: 16
            }
        }
    }
}

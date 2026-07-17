import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
    id: root

    required property string namespace
    required property string label
    required property string icon
    required property color accentColor
    property color iconColor: accentColor
    property color barColor: accentColor
    property real value: 0

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: root.namespace
    exclusiveZone: -1
    visible: false
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function trigger() {
        hideAnimation.stop();
        if (!visible || hideAnimation.running || content.opacity < 1) {
            visible = true;
            showAnimation.restart();
        }
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: hideAnimation.restart()
    }

    ParallelAnimation {
        id: showAnimation
        NumberAnimation { target: content; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }
        NumberAnimation { target: content; property: "scale"; to: 1; duration: 500; easing.type: Easing.OutBack }
    }

    ParallelAnimation {
        id: hideAnimation
        NumberAnimation { target: content; property: "opacity"; from: 1; to: 0; duration: 200; easing.type: Easing.InCubic }
        NumberAnimation { target: content; property: "scale"; from: 1; to: 0.9; duration: 200; easing.type: Easing.InCubic }
        onFinished: root.visible = false
    }

    Rectangle {
        id: content
        anchors.centerIn: parent
        implicitWidth: 260
        implicitHeight: 80
        opacity: 0
        scale: 0.9
        color: Theme.base
        border.color: root.accentColor
        border.width: 2
        radius: 16

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Text {
                text: root.icon
                color: root.iconColor
                font.family: "MonaspiceKr Nerd Font"
                font.pixelSize: 32
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.label
                        color: Theme.text
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 16
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Math.round(root.value * 100) + "%"
                        color: Theme.text
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 16
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    color: Theme.surface0
                    radius: 3

                    Rectangle {
                        width: parent.width * Math.min(root.value, 1)
                        height: parent.height
                        color: root.barColor
                        radius: 3
                    }
                }
            }
        }
    }
}

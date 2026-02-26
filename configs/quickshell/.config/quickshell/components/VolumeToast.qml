import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: toast
    
    WlrLayershell.layer: WlrLayershell.Overlay
    exclusiveZone: -1
    WlrLayershell.namespace: "volume-toast"
    
    property real volume: 0
    property bool muted: false
    
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
        if (!visible) {
            visible = true;
            showAnimation.restart();
        } else if (hideAnimation.running || content.opacity < 1.0) {
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
        onFinished: toast.visible = false
    }

    Rectangle {
        id: content
        anchors.centerIn: parent
        opacity: 0
        scale: 0.9
        
        implicitWidth: 260
        implicitHeight: 80
        
        color: "#1e1e2e"
        border.color: "#89b4fa"
        border.width: 2
        radius: 16
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Text {
                text: {
                    if (toast.muted || toast.volume === 0) return "󰝟"
                    if (toast.volume < 0.33) return "󰕿"
                    if (toast.volume < 0.66) return "󰖀"
                    return "󰕾"
                }
                font.pixelSize: 32
                color: !toast.muted ? "#89b4fa" : "#f38ba8"
                font.family: "MonaspiceKr Nerd Font"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Volume"
                        color: "#cdd6f4"
                        font.pixelSize: 16
                        font.family: "MonaspiceKr Nerd Font"
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Math.round(toast.volume * 100) + "%"
                        color: "#cdd6f4"
                        font.pixelSize: 16
                        font.family: "MonaspiceKr Nerd Font"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    color: "#313244"
                    radius: 3

                    Rectangle {
                        width: parent.width * Math.min(toast.volume, 1.0)
                        height: parent.height
                        color: !toast.muted ? "#89b4fa" : "#6c7086"
                        radius: 3
                    }
                }
            }
        }
    }
}

import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

MouseArea {
    id: root

    required property string audioNode
    required property string label
    required property string icon
    required property color accentColor
    property color mutedIconColor: Theme.red
    property color popupMutedIconColor: mutedIconColor
    property real volume: 0
    property bool muted: false
    property bool startup: true
    property bool menuOpen: false

    Layout.fillHeight: true
    implicitWidth: iconText.implicitWidth
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onVolumeChanged: {
        if (!startup && !menuOpen) toast.trigger();
    }
    onMutedChanged: {
        if (!startup && !menuOpen) toast.trigger();
    }
    onClicked: menuOpen = !menuOpen
    Component.onCompleted: volumeProcess.running = true

    Process {
        id: volumeProcess
        command: ["wpctl", "get-volume", root.audioNode]
        stdout: StdioCollector {
            onTextChanged: {
                const output = text.trim();
                if (!output) return;

                const value = parseFloat(output.split(" ")[1]);
                if (isNaN(value)) return;

                root.volume = value;
                root.muted = output.includes("[MUTED]");
                root.startup = false;
            }
        }
    }

    Timer {
        interval: root.menuOpen ? 200 : 500
        running: true
        repeat: true
        onTriggered: volumeProcess.running = true
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        text: root.icon
        color: root.muted ? root.mutedIconColor : root.accentColor
        font.family: "MonaspiceKr Nerd Font"
        font.pixelSize: 18
    }

    StatusToast {
        id: toast
        namespace: root.label.toLowerCase() + "-toast"
        label: root.label
        icon: root.icon
        accentColor: root.accentColor
        iconColor: root.muted ? root.mutedIconColor : root.accentColor
        barColor: root.muted ? Theme.overlay0 : root.accentColor
        value: root.volume
    }

    AudioPopup {
        visible: root.menuOpen
        anchorItem: root
        audioNode: root.audioNode
        label: root.label
        icon: root.icon
        accentColor: root.accentColor
        iconColor: root.muted ? root.popupMutedIconColor : root.accentColor
        volume: root.volume
        muted: root.muted

        onVisibleChanged: {
            if (!visible) root.menuOpen = false;
        }
        onVolumeUpdate: volume => root.volume = volume
        onMuteUpdate: muted => root.muted = muted
    }
}

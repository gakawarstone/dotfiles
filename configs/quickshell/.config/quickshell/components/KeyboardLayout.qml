import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import ".."

Item {
    id: root
    Layout.preferredWidth: kbRow.implicitWidth
    Layout.fillHeight: true

    property string activeLayout: ".."

    Process {
        id: initLayout
        command: ["sh", "-c", "hyprctl devices | grep -B 3 'main: yes' | grep 'active keymap' | cut -d ':' -f 2 | xargs"]
        running: true
        stdout: StdioCollector {
            id: collector
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                const layoutName = collector.text.trim();
                if (layoutName.toLowerCase().includes("english")) root.activeLayout = "🇺🇸";
                else if (layoutName.toLowerCase().includes("german")) root.activeLayout = "🇩🇪";
                else if (layoutName.toLowerCase().includes("russian")) root.activeLayout = "🇷🇺";
                else if (layoutName.length > 0) root.activeLayout = layoutName;
            }
        }
    }

    Process {
        id: switchLayout
        command: ["hyprctl", "switchxkblayout", "all", "next"]
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                const parts = event.data.split(",");
                if (parts.length > 1) {
                    const layoutName = parts[1];
                    if (layoutName.toLowerCase().includes("english")) root.activeLayout = "🇺🇸";
                    else if (layoutName.toLowerCase().includes("german")) root.activeLayout = "🇩🇪";
                    else if (layoutName.toLowerCase().includes("russian")) root.activeLayout = "🇷🇺";
                    else root.activeLayout = layoutName;
                }
            }
        }
    }

    RowLayout {
        id: kbRow
        anchors.fill: parent
        spacing: 8
        Text {
            text: root.activeLayout
            color: Theme.text
            font.pixelSize: 20
            font.family: "MonaspiceKr Nerd Font"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: switchLayout.running = true
    }
}

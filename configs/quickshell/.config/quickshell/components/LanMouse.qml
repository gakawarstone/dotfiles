import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

MouseArea {
    id: root
    Layout.fillHeight: true
    implicitWidth: layout.implicitWidth
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    property bool running: false
    property bool active: false
    property string client: "gklaptop"
    property string position: "bottom"
    property string fifo: "/tmp/quickshell-lan-mouse.fifo"
    property string log: "/tmp/quickshell-lan-mouse.log"
    property string pidFile: "/tmp/quickshell-lan-mouse.pid"

    function workflowCommands() {
        return "emulation status\ncapture status\nport 4242\nconnect " + position + " " + client + "\nactivate 0\n";
    }

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            stopProcess.running = true;
        } else if (root.running) {
            activateProcess.running = true;
        } else {
            startProcess.running = true;
        }
    }

    Process {
        id: statusProcess
        command: ["sh", "-c", "pidfile='" + root.pidFile + "'; log='" + root.log + "'; if [ -s \"$pidfile\" ] && kill -0 \"$(cat \"$pidfile\")\" 2>/dev/null; then printf running; if [ -r \"$log\" ] && grep -q 'activated client' \"$log\"; then printf ' active'; fi; else printf stopped; fi"]
        running: true
        stdout: StdioCollector { id: statusCollector }
        onExited: () => {
            const state = statusCollector.text.trim();
            root.running = state.indexOf("running") === 0;
            root.active = state.indexOf("active") !== -1;
        }
    }

    Process {
        id: startProcess
        command: ["sh", "-c", "fifo='" + root.fifo + "'; log='" + root.log + "'; pidfile='" + root.pidFile + "'; if [ -s \"$pidfile\" ] && kill -0 \"$(cat \"$pidfile\")\" 2>/dev/null; then :; else rm -f \"$fifo\"; mkfifo \"$fifo\"; : > \"$log\"; (while true; do cat \"$fifo\"; done | lan-mouse --capture-backend layer-shell -f cli > \"$log\" 2>&1) & echo $! > \"$pidfile\"; fi; sleep 0.2; printf '%s' '" + root.workflowCommands() + "' > \"$fifo\""]
        onExited: () => statusProcess.running = true
    }

    Process {
        id: activateProcess
        command: ["sh", "-c", "fifo='" + root.fifo + "'; [ -p \"$fifo\" ] && printf 'activate 0\n' > \"$fifo\""]
        onExited: () => statusProcess.running = true
    }

    Process {
        id: stopProcess
        command: ["sh", "-c", "pidfile='" + root.pidFile + "'; fifo='" + root.fifo + "'; [ -s \"$pidfile\" ] && kill \"$(cat \"$pidfile\")\" 2>/dev/null || true; rm -f \"$pidfile\" \"$fifo\""]
        onExited: () => statusProcess.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: statusProcess.running = true
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        Text {
            text: "󰍽"
            font.pixelSize: 18
            color: !root.running ? Theme.red : (root.active ? Theme.green : Theme.yellow)
            font.family: "MonaspiceKr Nerd Font"
        }

        Text {
            text: root.running ? (root.active ? root.position + " " + root.client : "lan mouse") : "lan off"
            color: Theme.text
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }
    }
}

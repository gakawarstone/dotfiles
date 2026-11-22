pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property string state: "checking"
    readonly property string statusText: state === "ready" ? "On"
        : state === "standby" ? "Rest Mode"
        : state === "unreachable" ? "No reply" : "Checking"
    readonly property color statusColor: state === "ready" ? Theme.green
        : state === "standby" ? Theme.peach : Theme.subtext0

    function refresh() {
        if (!probe.running)
            probe.running = true;
    }

    function updateState(nextState) {
        if (state === nextState)
            return;

        const notify = state !== "checking";
        state = nextState;
        if (notify) {
            const hints = "{'x-ps5-pro-accent': <'" + statusColor.toString() + "'>}";
            Quickshell.execDetached([
                "gdbus", "call", "--session", "--timeout", "3",
                "--dest", "org.freedesktop.Notifications",
                "--object-path", "/org/freedesktop/Notifications",
                "--method", "org.freedesktop.Notifications.Notify",
                "PS5 Pro", "0", "ps5-pro", "PS5 Pro", statusText, "[]", hints, "6000"
            ]);
        }
    }

    Process {
        id: probe
        command: ["/usr/bin/python3", Quickshell.shellPath("scripts/ps5-status.py")]
        running: true
        stdout: StdioCollector { id: output }
        onExited: exitCode => {
            const status = output.text.trim();
            root.updateState(exitCode === 0 && (status === "ready" || status === "standby")
                ? status : "unreachable");
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}

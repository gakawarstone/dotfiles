import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root
    
    property real brightness: 0
    property int maxBrightness: 1
    property bool startup: true

    function updateBrightness() {
        brightnessProcess.running = true;
    }

    Process {
        id: maxBrightnessProcess
        command: ["brightnessctl", "max"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                const val = parseInt(text.trim());
                if (!isNaN(val)) root.maxBrightness = val;
            }
        }
    }

    Process {
        id: brightnessProcess
        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onTextChanged: {
                const val = parseInt(text.trim());
                if (!isNaN(val)) {
                    const newBrightness = val / root.maxBrightness;
                    if (!root.startup && Math.abs(newBrightness - root.brightness) > 0.01) {
                        root.brightness = newBrightness;
                        toast.trigger();
                    } else if (root.startup) {
                        root.brightness = newBrightness;
                        root.startup = false;
                    }
                }
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.updateBrightness()
    }

    BrightnessToast {
        id: toast
        brightness: root.brightness
    }
}

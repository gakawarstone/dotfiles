import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import ".."

RowLayout {
    spacing: 8
    visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
    property bool showEstimate: true

    function formatTime(minutes) {
        if (!minutes || minutes < 0) return ""
        const total = Math.round(minutes)
        const hours = Math.floor(total / 60)
        const mins = total % 60
        if (hours <= 0) return `${mins}m`
        return `${hours}h ${mins}m`
    }

    Text {
        text: {
            if (!UPower.displayDevice) return "󰂑"
            if (UPower.displayDevice.state === UPowerDeviceState.Charging) return "󰂄"
            const p = UPower.displayDevice.percentage * 100
            if (p <= 10) return "󰁺"
            if (p <= 20) return "󰁻"
            if (p <= 30) return "󰁼"
            if (p <= 40) return "󰁽"
            if (p <= 50) return "󰁾"
            if (p <= 60) return "󰁿"
            if (p <= 70) return "󰂀"
            if (p <= 80) return "󰂁"
            if (p <= 90) return "󰂂"
            return "󰁹"
        }
        font.pixelSize: 18
        color: {
            if (UPower.displayDevice && (UPower.displayDevice.percentage * 100) < 20) return Theme.red
            return Theme.green
        }
        font.family: "MonaspiceKr Nerd Font"
    }
    Text {
        text: {
            if (!UPower.displayDevice) return ""
            const rawPct = UPower.displayDevice.percentage * 100
            const pct = Math.round(rawPct)
            if (showEstimate && UPower.displayDevice.state === UPowerDeviceState.Discharging && rawPct > 20) {
                // Approximate time to 20% from UPower's time-to-empty estimate.
                const secondsToEmpty = UPower.displayDevice.timeToEmpty ? UPower.displayDevice.timeToEmpty : 0
                const minutesToTwenty = secondsToEmpty > 0
                    ? (secondsToEmpty / 60) * ((rawPct - 20) / rawPct)
                    : 0
                const time = formatTime(minutesToTwenty)
                if (time) return `${pct}% · ${time} to 20%`
            }
            return pct + "%"
        }
        color: Theme.text
        font.pixelSize: 14
        font.family: "MonaspiceKr Nerd Font"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: showEstimate = !showEstimate
    }
}

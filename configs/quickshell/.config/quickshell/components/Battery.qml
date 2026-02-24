import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

RowLayout {
    spacing: 8
    visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
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
            if (UPower.displayDevice && (UPower.displayDevice.percentage * 100) < 20) return "#f38ba8"
            return "#a6e3a1"
        }
        font.family: "MonaspiceKr Nerd Font"
    }
    Text {
        text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
        color: "#cdd6f4"
        font.pixelSize: 14
        font.family: "MonaspiceKr Nerd Font"
    }
}

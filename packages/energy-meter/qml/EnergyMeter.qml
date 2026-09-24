import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "."

Scope {
    id: root

    property bool open: false
    property var reading: ({ status: "no_data" })
    property var buckets: []
    property var points: []
    property string period: "day"
    property string error: ""
    property string saveMessage: ""
    property bool settingsOpen: false
    property var selectedScreen: null
    readonly property string cli: (Quickshell.env("HOME") || "") + "/.local/bin/omaenergy"
    readonly property string fontName: "MonaspiceKr Nerd Font"
    readonly property var activeScreen: {
        const monitor = Hyprland.focusedMonitor
        for (let i = 0; monitor && i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === monitor.name)
                return Quickshell.screens[i]
        }
        return Quickshell.screens[0] ?? null
    }
    readonly property var recentBuckets: buckets.slice().reverse()
    readonly property real maxBucket: Math.max(0.001, ...buckets.map(row => Number(row.kwh) || 0))
    readonly property real chartSpan: points.length > 1 ? Math.max(60, Number(points[points.length - 1].ts) - Number(points[0].ts)) : 86400
    readonly property string chartPeriod: chartSpan < 7200
        ? "LAST " + Math.max(1, Math.round(chartSpan / 60)) + " MIN"
        : "LAST " + Math.max(1, Math.round(chartSpan / 3600)) + " H"

    function money(value) {
        const amount = Number(value) || 0
        const decimals = Math.max(0, Math.min(4, Number(reading.cost_decimals) || 0))
        return (reading.currency_symbol || reading.currency || "") + amount.toFixed(decimals)
    }

    function readJson(output) {
        try { return JSON.parse(output) } catch (e) { return null }
    }

    function refresh() {
        if (!open) return
        if (!nowProcess.running) nowProcess.running = true
        if (!bucketsProcess.running) {
            bucketsProcess.command = [cli, period, "--json"]
            bucketsProcess.running = true
        }
        if (!chartProcess.running) chartProcess.running = true
    }

    function show() {
        selectedScreen = activeScreen
        open = true
        refresh()
    }

    function hide() {
        open = false
        settingsOpen = false
    }

    function setPeriod(value) {
        if (period === value) return
        period = value
        buckets = []
        if (!bucketsProcess.running) {
            bucketsProcess.command = [cli, period, "--json"]
            bucketsProcess.running = true
        }
    }

    IpcHandler {
        target: "energy-meter"
        function toggle() { root.open ? root.hide() : root.show() }
        function close() { root.hide() }
    }

    Timer {
        interval: 5000
        running: root.open
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: nowProcess
        command: [root.cli, "now", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.readJson(text)
                if (data && typeof data === "object") {
                    root.reading = data
                    root.error = ""
                } else {
                    root.error = "Cannot read Energy Meter data"
                }
            }
        }
        onExited: code => { if (code !== 0) root.error = "Energy Meter backend is unavailable" }
    }

    Process {
        id: bucketsProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.readJson(text)
                root.buckets = data && Array.isArray(data.buckets) ? data.buckets : []
            }
        }
    }

    Process {
        id: chartProcess
        command: [root.cli, "chart", "--hours", "24", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.readJson(text)
                root.points = data && Array.isArray(data.points) ? data.points : []
                chart.requestPaint()
            }
        }
    }

    Process {
        id: saveProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.readJson(text)
                if (data && data.status === "ok") {
                    root.saveMessage = "Saved. History has been recalculated."
                    root.refresh()
                }
            }
        }
        onExited: code => {
            if (code !== 0) root.saveMessage = "Could not save settings"
        }
    }

    FloatingWindow {
        id: window
        screen: root.selectedScreen
        visible: root.open
        title: "Energy Meter"
        color: Theme.base
        implicitWidth: 650
        implicitHeight: 670
        minimumSize: Qt.size(540, 490)
        onClosed: root.hide()

        Rectangle {
            anchors.fill: parent
            color: Theme.base

            RowLayout {
                z: 1
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 22
                anchors.rightMargin: 22
                width: 38
                height: 36
                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 36
                    color: settingsMouse.containsMouse ? Theme.surface0 : "transparent"
                    radius: 5
                    Text {
                        anchors.centerIn: parent
                        text: root.settingsOpen ? "" : ""
                        color: Theme.text
                        font.family: root.fontName
                        font.pixelSize: 21
                    }
                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.settingsOpen = !root.settingsOpen
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                anchors.topMargin: 10
                anchors.bottomMargin: 22
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.settingsOpen
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        spacing: 14
                        Text {
                            text: ""
                            color: Theme.mauve
                            font.family: root.fontName
                            font.pixelSize: 27
                        }
                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: root.reading.status === "ok" ? Math.round(Number(root.reading.watts)) + " W" : "— W"
                                color: Theme.text
                                font.family: root.fontName
                                font.pixelSize: 38
                                font.weight: Font.DemiBold
                            }
                            Text {
                                visible: root.reading.status !== "ok"
                                text: root.error || "No samples yet. Start the omaenergy service."
                                color: Theme.yellow
                                font.family: root.fontName
                                font.pixelSize: 12
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 18
                        Layout.preferredHeight: 10
                        color: Theme.surface1
                        radius: 2
                        Row {
                            anchors.fill: parent
                            clip: true
                            Rectangle {
                                width: parent.width * (Number(root.reading.cpu_w) || 0) / Math.max(1, Number(root.reading.watts) || 0)
                                height: parent.height
                                color: Theme.blue
                            }
                            Rectangle {
                                width: parent.width * (Number(root.reading.gpu_w) || 0) / Math.max(1, Number(root.reading.watts) || 0)
                                height: parent.height
                                color: Theme.lavender
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        spacing: 18
                        Repeater {
                            model: [
                                { label: "CPU", value: root.reading.cpu_w || 0, color: Theme.blue },
                                { label: "GPU", value: root.reading.gpu_w || 0, color: Theme.lavender },
                                { label: "rest", value: root.reading.rest_w || 0, color: Theme.overlay1, estimated: true }
                            ]
                            delegate: RowLayout {
                                required property var modelData
                                spacing: 5
                                Rectangle {
                                    Layout.preferredWidth: 7
                                    Layout.preferredHeight: 7
                                    radius: 4
                                    color: modelData.color
                                }
                                Text {
                                    text: modelData.label + " " + Math.round(Number(modelData.value)) + " W" + (modelData.estimated ? " *est" : "")
                                    color: Theme.subtext0
                                    font.family: root.fontName
                                    font.pixelSize: 12
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 18
                        Layout.preferredHeight: 1
                        color: Theme.surface1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 18
                        Text {
                            text: root.points.length > 1 ? root.chartPeriod : "LAST 24H"
                            color: Theme.subtext0
                            font.family: root.fontName
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 226
                        Layout.topMargin: 8

                        Canvas {
                            id: chart
                            anchors.fill: parent
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                const samples = root.points
                                if (samples.length < 2) return
                                const start = Number(samples[0].ts)
                                const values = samples.map(point => Number(point.w) || 0)
                                const low = Math.min(...values)
                                const high = Math.max(...values)
                                const padding = Math.max(5, (high - low) * 0.22)
                                const floor = Math.max(0, low - padding)
                                const ceiling = high + padding
                                function x(i) { return Math.max(0, Math.min(width, (Number(samples[i].ts) - start) / root.chartSpan * width)) }
                                function y(i) { return 8 + (ceiling - values[i]) / Math.max(1, ceiling - floor) * (height - 20) }
                                ctx.fillStyle = Theme.blue.toString()
                                ctx.globalAlpha = 0.12
                                ctx.beginPath()
                                ctx.moveTo(x(0), height - 2)
                                for (let i = 0; i < samples.length; i++) ctx.lineTo(x(i), y(i))
                                ctx.lineTo(x(samples.length - 1), height - 2)
                                ctx.closePath()
                                ctx.fill()
                                ctx.globalAlpha = 1
                                ctx.strokeStyle = Theme.blue.toString()
                                ctx.lineWidth = 2
                                ctx.beginPath()
                                for (let i = 0; i < samples.length; i++) {
                                    if (i === 0) ctx.moveTo(x(i), y(i))
                                    else ctx.lineTo(x(i), y(i))
                                }
                                ctx.stroke()
                                ctx.fillStyle = Theme.overlay1.toString()
                                ctx.font = "11px '" + root.fontName + "'"
                                ctx.fillText(Math.round(ceiling) + " W", 3, 14)
                                ctx.fillText(Math.round(floor) + " W", 3, height - 5)
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.points.length < 2
                            text: "Waiting for chart data"
                            color: Theme.overlay1
                            font.family: root.fontName
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        Layout.preferredHeight: 1
                        color: Theme.surface1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 14
                        spacing: 6
                        Repeater {
                            model: [ { value: "day", label: "Day" }, { value: "week", label: "Week" }, { value: "month", label: "Month" }, { value: "year", label: "Year" } ]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.preferredWidth: 92
                                Layout.preferredHeight: 38
                                color: root.period === modelData.value ? Theme.surface1 : "transparent"
                                border.color: Theme.surface1
                                border.width: 1
                                radius: 4
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: Theme.text
                                    font.family: root.fontName
                                    font.pixelSize: 14
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setPeriod(modelData.value)
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: 10
                        clip: true
                        spacing: 3
                        model: root.recentBuckets
                        delegate: Item {
                            required property var modelData
                            width: ListView.view.width
                            height: 34
                            RowLayout {
                                anchors.fill: parent
                                spacing: 12
                                Text {
                                    Layout.preferredWidth: 115
                                    text: modelData.label
                                    textFormat: Text.PlainText
                                    color: Theme.subtext0
                                    font.family: root.fontName
                                    font.pixelSize: 12
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 4
                                    color: Theme.surface1
                                    radius: 2
                                    Rectangle {
                                        width: parent.width * Math.min(1, Number(modelData.kwh) / root.maxBucket)
                                        height: parent.height
                                        color: Theme.blue
                                        radius: 2
                                    }
                                }
                                Text {
                                    Layout.preferredWidth: 76
                                    horizontalAlignment: Text.AlignRight
                                    text: Number(modelData.kwh).toFixed(3) + " kWh"
                                    color: Theme.text
                                    font.family: root.fontName
                                    font.pixelSize: 12
                                }
                                Text {
                                    Layout.preferredWidth: 68
                                    horizontalAlignment: Text.AlignRight
                                    text: root.money(modelData.cost)
                                    textFormat: Text.PlainText
                                    color: Theme.text
                                    font.family: root.fontName
                                    font.pixelSize: 12
                                }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.buckets.length === 0
                            text: "No history yet"
                            color: Theme.overlay1
                            font.family: root.fontName
                            font.pixelSize: 12
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 22
                    visible: root.settingsOpen
                    spacing: 12

                    Text {
                        text: "Settings"
                        color: Theme.text
                        font.family: root.fontName
                        font.pixelSize: 22
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Price changes apply to the complete recorded history."
                        color: Theme.overlay1
                        font.family: root.fontName
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        text: "ELECTRICITY PRICE / kWh"
                        color: Theme.subtext0
                        font.family: root.fontName
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: 112
                            Layout.preferredHeight: 34
                            color: Theme.surface0
                            radius: 4
                            TextInput {
                                id: tariffField
                                anchors.fill: parent
                                anchors.margins: 7
                                text: root.reading.tariff === undefined ? "" : String(root.reading.tariff)
                                color: Theme.text
                                font.family: root.fontName
                                font.pixelSize: 14
                                validator: RegularExpressionValidator { regularExpression: /^(?:[0-9]+(?:[.,][0-9]*)?)?$/ }
                                verticalAlignment: TextInput.AlignVCenter
                                Keys.onReturnPressed: saveButton.save()
                            }
                        }
                        Text {
                            text: root.reading.currency || "EUR"
                            color: Theme.overlay1
                            font.family: root.fontName
                            font.pixelSize: 12
                        }
                        Rectangle {
                            id: saveButton
                            function save() {
                                if (saveProcess.running || tariffField.text.trim() === "") return
                                root.saveMessage = ""
                                saveProcess.command = [root.cli, "config", "tariff=" + tariffField.text.trim().replace(",", "."), "--json"]
                                saveProcess.running = true
                            }
                            Layout.preferredWidth: 70
                            Layout.preferredHeight: 34
                            color: Theme.surface1
                            radius: 4
                            Text { anchors.centerIn: parent; text: "Save"; color: Theme.text; font.family: root.fontName; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: saveButton.save() }
                        }
                    }
                    Text {
                        text: root.saveMessage
                        color: root.saveMessage.startsWith("Could not") ? Theme.red : Theme.green
                        font.family: root.fontName
                        font.pixelSize: 12
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "CPU and GPU are measured. The rest of the computer and power supply loss are estimates. Calibrate them with omaenergy config."
                        color: Theme.overlay1
                        font.family: root.fontName
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            enabled: root.open
            onActivated: root.hide()
        }
    }
}

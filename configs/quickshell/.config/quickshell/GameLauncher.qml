pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import "."

Scope {
    id: root

    readonly property string controllerAddress: "40:8E:2C:45:CD:30"
    readonly property var targetScreen: Quickshell.screens.find(screen => screen.model === "LG ULTRAGEAR") ?? null
    readonly property bool connected: Bluetooth.devices.values.some(device =>
        device.address.toUpperCase() === controllerAddress && device.connected)
    readonly property bool available: targetScreen !== null && connected
    readonly property var desktopGames: {
        const launchers = ["steam", "heroic", "ru.linux_gaming.PortProton", "ps5-games", "suyu"]
        const ps5Games = ["gta-vi-ps5", "fc-27-ps5", "god-of-war-ragnarok-ps5", "astros-playroom-ps5"]
        return DesktopEntries.applications.values.filter(app =>
            !app.noDisplay && app.categories.includes("Game") && !launchers.includes(app.id)
            && !/steam:\/\/rungameid\/\d{1,10}(?:\s|$)/.test(app.execString)
        ).map(app => ({
            id: app.id,
            name: app.name,
            source: app.id.endsWith("-ps5") ? "PS5 Pro" : "",
            artwork: ps5Games.includes(app.id) ? Qt.resolvedUrl("artwork/ps5/" + app.id + ".jpg") : "",
            ps5Key: ps5Games.includes(app.id) ? app.id.slice(0, -4) : "",
            icon: app.icon,
            application: app,
        }))
    }
    readonly property var games: {
        const local = desktopGames
        const lastPlayed = game => Math.max(Number(recent[game.id]) || 0, game.lastPlayed || 0)
        return steamGames === null ? [] : steamGames.concat(local)
            .sort((a, b) => lastPlayed(b) - lastPlayed(a) || a.name.localeCompare(b.name))
    }
    property bool open: false
    property var steamGames: null
    property var recent: ({})
    property var confirmedGame: null
    readonly property bool launchInProgress: confirmPoster.running || ps5Pending
    property string ps5Stage: ""
    property string ps5Message: ""
    readonly property bool ps5Pending: ["checking", "waiting", "connecting"].includes(ps5Stage)
    readonly property bool ps5StreamVisible: ps5Stage === "connecting" && ToplevelManager.toplevels.values.some(window =>
        window.appId === "chiaki-ng-framegen" && window.fullscreen && !ps5Launch.existingStreams.includes(window))

    onPs5StreamVisibleChanged: {
        if (ps5StreamVisible)
            Qt.callLater(root.finishPs5Handoff)
    }
    onAvailableChanged: {
        if (available)
            show()
        else if (!launchInProgress || !targetScreen)
            open = false
    }
    Component.onCompleted: if (available) show()

    function show(): void {
        if (!targetScreen || open)
            return
        if (launchInProgress) {
            open = true
            return
        }
        resetPoster()
        setPs5Status("", "")
        recent = readHistory()
        steamGames = null
        open = true
        library.running = true
    }

    function readHistory() {
        try {
            const data = JSON.parse(history.text() || "{}")
            if (data && typeof data === "object" && !Array.isArray(data))
                return data
        } catch (error) {
            console.warn("Could not read game launch history:", error)
        }
        return {}
    }

    function move(delta: int): void {
        if (!games.length || launchInProgress || collapsePoster.running)
            return
        setPs5Status("", "")
        list.currentIndex = (list.currentIndex + delta + games.length) % games.length
    }

    function launch(): void {
        const game = games[list.currentIndex]
        if (!open || !game || focusMonitor.running || launchInProgress || collapsePoster.running)
            return
        if (game.ps5Key && ps5Launch.running) {
            setPs5Status("busy", "Уже открыт сеанс PS5 Pro.")
            return
        }
        const updated = Object.assign({}, readHistory(), { [game.id]: Date.now() })
        history.setText(JSON.stringify(updated) + "\n")
        confirmedGame = game
        if (game.ps5Key) {
            ps5Launch.game = game
            ps5Launch.existingStreams = ToplevelManager.toplevels.values
                .filter(window => window.appId === "chiaki-ng-framegen")
            setPs5Status("checking", "Запускаю игру на PS5 Pro…")
        }
        confirmPoster.restart()
    }

    function dispatchConfirmedGame(): void {
        const game = confirmedGame
        if (!game.ps5Key)
            open = false
        if (targetScreen) {
            focusMonitor.game = game
            focusMonitor.running = true
        } else {
            startGame(game)
        }
    }

    function startGame(game): void {
        if (game.ps5Key)
            ps5Launch.running = true
        else if (game.application)
            game.application.execute()
        else
            Quickshell.execDetached(game.command)
    }

    function resetPoster(): void {
        collapsePoster.stop()
        preview.expansion = 0
        confirmedGame = null
    }

    function setPs5Status(stage: string, message: string): void {
        ps5Message = message
        ps5Stage = stage
        if ((stage === "error" || stage === "busy") && confirmedGame)
            collapsePoster.restart()
    }

    function finishPs5Handoff(): void {
        open = false
        setPs5Status("", "")
    }

    SequentialAnimation {
        id: confirmPoster
        NumberAnimation {
            target: preview
            property: "expansion"
            to: 1
            duration: 420
            easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: root.confirmedGame?.ps5Key ? 0 : 150 }
        ScriptAction { script: root.dispatchConfirmedGame() }
    }

    NumberAnimation {
        id: collapsePoster
        target: preview
        property: "expansion"
        to: 0
        duration: 300
        easing.type: Easing.InOutCubic
        onFinished: root.confirmedGame = null
    }

    FileView {
        id: history
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state")
            + "/quickshell-game-history.json"
        blockLoading: true
        blockWrites: true
        atomicWrites: true
        printErrors: false
        onSaveFailed: error => console.warn("Could not save game launch history:", error)
    }

    Process {
        id: library
        command: ["python3", Quickshell.shellPath("scripts/game-library.py")]
        stdout: StdioCollector { id: libraryOutput }
        onExited: exitCode => {
            if (root.open) {
                root.steamGames = exitCode === 0 ? JSON.parse(libraryOutput.text) : []
                list.currentIndex = root.games.length ? 0 : -1
                list.positionViewAtBeginning()
            }
        }
    }

    Process {
        id: focusMonitor
        property var game
        command: root.targetScreen ? ["hyprctl", "eval",
            "hl.dispatch(hl.dsp.focus({ monitor = " + JSON.stringify(root.targetScreen.name) + " }))"] : []
        onExited: root.startGame(game)
    }

    Process {
        id: ps5Launch
        property var game: null
        property var existingStreams: []
        readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share"
        command: game ? [
            "/usr/bin/uv", "run", "--no-project", "--script",
            dataHome + "/gta-vi-ps5/launch.py", game.ps5Key,
            "--progress-instance", Quickshell.instanceId, "--progress-target", "game-menu-ps5"
        ] : []
        onExited: (exitCode, exitStatus) => {
            if (!root.ps5Pending)
                return
            if (exitCode !== 0 || exitStatus !== 0)
                root.setPs5Status("error", "Не удалось запустить игру на PS5 Pro.")
            else
                root.finishPs5Handoff()
        }
    }

    Process {
        running: root.open && root.connected
        command: ["python3", Quickshell.shellPath("scripts/xbox-menu-input.py"), root.controllerAddress]
        stdout: SplitParser {
            onRead: action => {
                if (!root.open)
                    return
                switch (action) {
                case "up": root.move(-1); break
                case "down": root.move(1); break
                case "launch": root.launch(); break
                case "close": root.open = false; break
                }
            }
        }
    }

    IpcHandler {
        target: "game-launcher"
        function open(): void { root.show() }
        function close(): void { root.open = false }
    }

    IpcHandler {
        target: "game-menu-ps5"
        function gameStatus(game: string, desktopId: string, stage: string, message: string): void {
            if (ps5Launch.running && root.ps5Pending && ps5Launch.game.id === desktopId)
                root.setPs5Status(stage, message)
        }
    }

    PanelWindow {
        screen: root.targetScreen
        visible: root.open && root.targetScreen !== null
        color: Theme.base
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "quickshell-game-launcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Item {
            id: scene
            anchors.fill: parent

            ColumnLayout {
                id: browser
                anchors.fill: parent
                opacity: 1 - preview.expansion
                anchors.margins: Math.round(Math.min(parent.width, parent.height) * 0.05)
                spacing: 28

                Text {
                    id: heading
                    Layout.fillWidth: true
                    text: "Игры"
                    color: Theme.text
                    font.pixelSize: 56
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    id: gameRow
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 36

                    ListView {
                        id: list
                        Layout.preferredWidth: Math.min(620, browser.width * 0.36)
                        Layout.fillHeight: true
                        model: root.games
                        enabled: !root.launchInProgress && !collapsePoster.running
                        spacing: 8
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: 0
                        highlightResizeDuration: 0
                        highlight: Rectangle {
                            radius: 14
                            color: Theme.surface0
                            border.color: Theme.mauve
                            border.width: 2
                        }

                        delegate: Item {
                            id: row
                            required property int index
                            required property var modelData
                            width: ListView.view.width
                            height: 72

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 22
                                anchors.rightMargin: 22
                                verticalAlignment: Text.AlignVCenter
                                text: row.modelData.name
                                color: row.ListView.isCurrentItem ? Theme.text : Theme.subtext1
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                font.pixelSize: 26
                                font.weight: row.ListView.isCurrentItem ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.setPs5Status("", "")
                                    list.currentIndex = row.index
                                    root.launch()
                                }
                            }
                        }

                        Text {
                            anchors.top: parent.top
                            visible: list.count === 0
                            text: library.running ? "Загружаю игры…" : "Игры не найдены"
                            color: Theme.subtext1
                            font.pixelSize: 24
                        }
                    }

                    Item {
                        id: previewSlot
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }

                Text {
                    text: "↑ ↓  Выбор       A  Запустить       B  Закрыть"
                    color: Theme.subtext1
                    font.pixelSize: 24
                }
            }

            Rectangle {
                id: preview
                readonly property var game: root.confirmedGame ?? root.games[list.currentIndex]
                property real expansion: 0
                x: (browser.x + gameRow.x + previewSlot.x) * (1 - expansion)
                y: (browser.y + gameRow.y + previewSlot.y) * (1 - expansion)
                width: previewSlot.width + (scene.width - previewSlot.width) * expansion
                height: previewSlot.height + (scene.height - previewSlot.height) * expansion
                visible: !!game
                color: Theme.mantle
                clip: true

                Image {
                    id: artwork
                    anchors.fill: parent
                    source: preview.game?.artwork || ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 1920
                    asynchronous: true
                }

                Image {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.38
                    height: width
                    visible: artwork.status !== Image.Ready && source.toString() !== ""
                    source: preview.game?.icon ? Quickshell.iconPath(preview.game.icon) : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.40; color: "transparent" }
                        GradientStop { position: 1; color: Theme.crust }
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 40 + 32 * preview.expansion
                    spacing: 10

                    Text {
                        visible: text !== ""
                        text: preview.game?.source || ""
                        color: Theme.mauve
                        font.pixelSize: 22
                        font.weight: Font.Medium
                    }

                    Text {
                        width: parent.width
                        text: preview.game?.name || ""
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                        color: Theme.text
                        font.pixelSize: Math.round(44 + 18 * preview.expansion)
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: root.ps5Message || (confirmPoster.running && !root.confirmedGame?.ps5Key ? "Запускаю…" : "")
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        color: root.ps5Stage === "error" ? Theme.red : Theme.text
                        font.pixelSize: 28
                    }

                    Rectangle {
                        id: track
                        visible: root.ps5Pending
                        width: Math.min(parent.width, 320)
                        height: 4
                        radius: 2
                        clip: true
                        color: Theme.surface0

                        Rectangle {
                            id: segment
                            height: track.height
                            width: track.width / 4
                            radius: track.radius
                            color: Theme.blue

                            SequentialAnimation on x {
                                running: root.open && track.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: -segment.width; to: track.width; duration: 1350 }
                            }
                        }
                    }
                }
            }

            Controls.Button {
                id: closeButton
                anchors.right: parent.right
                anchors.rightMargin: browser.anchors.margins
                y: browser.y + (heading.height - height) / 2
                text: root.launchInProgress ? "B  Скрыть" : "Закрыть"
                font.pixelSize: 22
                horizontalPadding: 20
                verticalPadding: 12
                hoverEnabled: true
                onClicked: root.open = false

                contentItem: Text {
                    text: closeButton.text
                    font: closeButton.font
                    color: closeButton.hovered || preview.expansion > 0 ? Theme.text : Theme.subtext1
                }

                background: Rectangle {
                    radius: 10
                    color: closeButton.hovered ? Theme.surface0 : Qt.alpha(Theme.crust, 0.72 * preview.expansion)
                }
            }
        }
    }
}

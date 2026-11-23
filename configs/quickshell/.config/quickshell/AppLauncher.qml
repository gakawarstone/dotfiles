import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "."

Scope {
    id: root

    property bool open: false
    property int selectedIndex: 0
    property string activeMenu: "root"
    property var navigationStack: []
    property var fileItems: []
    property string fileSearchQuery: ""
    readonly property int rowHeight: 68
    readonly property string query: searchField.text.trim()
    readonly property var searchVariants: queryVariants(query)

    // Mapping from the Russian keyboard layout to the US layout, so that
    // typing "кув" (what "red" produces on a Russian keyboard) also matches "red".
    readonly property var cyrToLat: {
        "й":"q","ц":"w","у":"e","к":"r","е":"t","н":"y","г":"u","ш":"i","щ":"o","з":"p","х":"[","ъ":"]",
        "ф":"a","ы":"s","в":"d","а":"f","п":"g","р":"h","о":"j","л":"k","д":"l","ж":";","э":"'",
        "я":"z","ч":"x","с":"c","м":"v","и":"b","т":"n","ь":"m","б":",","ю":".","/":"/"
    }

    function latToCyr() {
        const m = {}
        for (const k in cyrToLat) {
            const v = cyrToLat[k]
            if (v && v.length === 1) m[v] = k
        }
        return m
    }

    function transliterate(text, dir) {
        const map = dir === "lat" ? latToCyr() : cyrToLat
        let out = ""
        for (const ch of text.toLowerCase())
            out += map[ch] !== undefined ? map[ch] : ch
        return out
    }

    function queryVariants(query) {
        const q = query.toLowerCase()
        const variants = [q]
        const toLat = transliterate(q, "cyr")
        if (toLat !== q) variants.push(toLat)
        const toCyr = transliterate(q, "lat")
        if (toCyr !== q) variants.push(toCyr)
        return variants
    }

    readonly property var menuItems: [
        { id: "apps", parent: "root", kind: "menu", icon: "󰀻", label: "Apps", description: "Installed applications" },
        { id: "actions", parent: "root", kind: "menu", icon: "󱓞", label: "Actions", description: "Common desktop actions" },
        { id: "setup", parent: "root", kind: "menu", icon: "", label: "Setup", description: "Edit desktop configuration" },
        { id: "system", parent: "root", kind: "menu", icon: "", label: "System", description: "Lock, suspend, or log out" },
        { id: "energy", parent: "root", kind: "action", icon: "", label: "Energy Meter", description: "Power use and electricity cost", command: "qs ipc call energy-meter toggle" },

        { id: "actions.terminal", parent: "actions", kind: "action", icon: "", label: "Terminal", description: "Open Foot", command: "foot" },
        { id: "actions.files", parent: "actions", kind: "action", icon: "", label: "Files", description: "Open Dolphin", command: "dolphin" },
        { id: "actions.activity", parent: "actions", kind: "action", icon: "󰄨", label: "Activity", description: "Open btop", command: "foot -e btop" },
        { id: "actions.screenshot", parent: "actions", kind: "action", icon: "", label: "Screenshot", description: "Capture an area", command: "screen area" },
        { id: "actions.notifications", parent: "actions", kind: "action", icon: "󰂚", label: "Notifications", description: "Toggle notification center", command: "qs ipc call notifications toggle" },
        { id: "actions.theme", parent: "actions", kind: "action", icon: "󰸌", label: "Toggle theme", description: "Switch between Latte and Mocha", command: "toggle_theme" },

        { id: "setup.hyprland", parent: "setup", kind: "action", icon: "", label: "Hyprland", description: "Edit hyprland.lua", command: "foot -e nvim ~/.config/hypr/hyprland.lua" },
        { id: "setup.quickshell", parent: "setup", kind: "action", icon: "󰖯", label: "Quickshell", description: "Edit the shell configuration", command: "foot -e nvim ~/.config/quickshell/shell.qml" },

        { id: "system.lock", parent: "system", kind: "action", icon: "", label: "Lock", description: "Lock the session", command: "lock" },
        { id: "system.suspend", parent: "system", kind: "action", icon: "󰒲", label: "Suspend", description: "Suspend the computer", command: "systemctl suspend" },
        { id: "system.logout", parent: "system", kind: "action", icon: "󰍃", label: "Log out", description: "Exit Hyprland", command: "hyprctl dispatch exit" }
    ]

    readonly property var applicationItems: DesktopEntries.applications.values
        .filter(app => !app.noDisplay)
        .map(app => ({
            id: "apps." + app.id,
            parent: "apps",
            kind: "app",
            icon: app.icon,
            label: app.name,
            description: "Application",
            subtitle: [app.genericName, app.comment].map(text => text.trim())
                .find(text => text && text.toLowerCase() !== app.name.toLowerCase()),
            application: app
        }))

    readonly property var allItems: menuItems.concat(applicationItems, fileItems)
    readonly property var displayItems: {
        let items

        if (query) {
            items = allItems.filter(item => {
                if (!isDescendantOf(item, activeMenu))
                    return false
                const hay = [item.label, item.description, item.subtitle, pathFor(item)].join(" ").toLowerCase()
                const hayTranslit = transliterate(hay, "cyr")
                return searchVariants.some(v => hay.includes(v) || hayTranslit.includes(v))
            })
        } else {
            items = allItems.filter(item => item.parent === activeMenu)
        }

        // Prefer the Latin (transliterated) form for sorting when the query is Cyrillic,
        // e.g. "кув" should rank items starting with "red".
        const sortQuery = searchVariants.find(v => /^[a-z0-9]+$/i.test(v)) || query.toLowerCase()

        return items.sort((left, right) => {
            if (!query && activeMenu !== "apps")
                return menuItems.indexOf(left) - menuItems.indexOf(right)
            if ((left.kind === "file") !== (right.kind === "file"))
                return left.kind === "file" ? 1 : -1
            const leftStarts = left.label.toLowerCase().startsWith(sortQuery)
            const rightStarts = right.label.toLowerCase().startsWith(sortQuery)
            if (leftStarts !== rightStarts)
                return leftStarts ? -1 : 1
            return left.label.localeCompare(right.label)
        })
    }

    readonly property var activeScreen: {
        const monitor = Hyprland.focusedMonitor
        for (let i = 0; monitor && i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === monitor.name)
                return Quickshell.screens[i]
        }
        return Quickshell.screens[0] ?? null
    }

    function itemById(id) {
        return menuItems.find(item => item.id === id)
    }

    function isDescendantOf(item, ancestorId) {
        if (ancestorId === "root")
            return true

        let current = item
        while (current && current.parent !== "root") {
            if (current.parent === ancestorId)
                return true
            current = itemById(current.parent)
        }
        return false
    }

    function pathFor(item) {
        const labels = []
        let current = itemById(item.parent)
        while (current) {
            labels.unshift(current.label)
            current = itemById(current.parent)
        }
        return labels.join(" › ")
    }

    function descriptionFor(item) {
        if (item.kind === "file")
            return item.path
        const description = item.subtitle ?? item.description
        const path = query && activeMenu === "root" ? pathFor(item) : ""
        return path ? path + " · " + description : description
    }

    function labelFor(label) {
        const escape = text => text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        if (!query)
            return escape(label)
        const lowerLabel = label.toLowerCase()
        const match = searchVariants.find(variant => lowerLabel.includes(variant))
        if (!match)
            return escape(label)
        const start = lowerLabel.indexOf(match)
        const end = start + match.length
        return escape(label.slice(0, start)) + '<font color="' + Theme.mauve + '"><u>'
            + escape(label.slice(start, end)) + "</u></font>" + escape(label.slice(end))
    }

    function searchFiles() {
        const query = searchField.text.trim()
        if (!open || activeMenu !== "root" || query.length < 2 || query.startsWith("?")) {
            fileSearchQuery = ""
            fileItems = []
            fileSearchProcess.running = false
            return
        }

        if (fileSearchProcess.running) {
            fileSearchProcess.running = false
            return
        }

        fileSearchQuery = query
        fileSearchProcess.command = ["fd", "--type", "file", "--absolute-path", "-i",
                                     "--fixed-strings", "--print0", "--max-results", "100",
                                     "--exclude", ".git", "--exclude", ".cache", "--exclude", "node_modules",
                                     query, Quickshell.env("HOME")]
        fileSearchProcess.running = true
    }

    function menuTitle() {
        const item = itemById(activeMenu)
        return item ? item.label : "Go"
    }

    function show() {
        searchField.text = ""
        activeMenu = "root"
        navigationStack = []
        selectedIndex = 0
        open = true
        Qt.callLater(() => searchField.forceActiveFocus())
    }

    function hide() {
        open = false
    }

    function moveSelection(offset) {
        if (displayItems.length === 0)
            return
        selectedIndex = (selectedIndex + offset + displayItems.length) % displayItems.length
        results.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function enterMenu(id) {
        navigationStack = navigationStack.concat([activeMenu])
        activeMenu = id
        searchField.text = ""
        selectedIndex = 0
    }

    function goBack() {
        if (searchField.text.length > 0) {
            searchField.text = ""
            return
        }
        if (navigationStack.length === 0) {
            hide()
            return
        }

        activeMenu = navigationStack[navigationStack.length - 1]
        navigationStack = navigationStack.slice(0, -1)
        selectedIndex = 0
    }

    function activate(item) {
        if (!item)
            return
        if (item.kind === "menu") {
            enterMenu(item.id)
        } else if (item.kind === "app") {
            item.application.execute()
            hide()
        } else if (item.kind === "file") {
            Qt.openUrlExternally("file://" + item.path.split("/").map(encodeURIComponent).join("/"))
            hide()
        } else {
            actionProcess.command = ["sh", "-lc", item.command]
            actionProcess.running = true
            hide()
        }
    }

    onDisplayItemsChanged: selectedIndex = 0

    Process {
        id: actionProcess
    }

    Timer {
        id: fileSearchTimer
        interval: 180
        onTriggered: root.searchFiles()
    }

    Process {
        id: fileSearchProcess
        stdout: StdioCollector { id: fileSearchOutput }
        onExited: {
            const query = searchField.text.trim()
            if (root.open && root.activeMenu === "root" && query === root.fileSearchQuery) {
                root.fileItems = fileSearchOutput.text.split("\0").filter(path => path.length > 0).map(path => ({
                    id: "file." + path,
                    parent: "root",
                    kind: "file",
                    icon: "󰈔",
                    label: path.slice(path.lastIndexOf("/") + 1),
                    path: path
                }))
            }
            if (root.open && query !== root.fileSearchQuery)
                fileSearchTimer.restart()
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            root.open ? root.hide() : root.show()
        }

        function close() {
            root.hide()
        }
    }

    PanelWindow {
        screen: root.activeScreen
        visible: root.open
        color: "transparent"
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "quickshell-launcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.5)

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }
        }

        Rectangle {
            id: launcherPanel

            readonly property int listInset: 12
            readonly property int rowSpacing: 4
            readonly property int chromeHeight: 4 + header.Layout.preferredHeight + footer.Layout.preferredHeight + 2 * listInset
            readonly property int availableHeight: Math.max(0, parent.height - 32)
            readonly property int rowsThatFit: Math.floor((availableHeight - chromeHeight + rowSpacing) / (root.rowHeight + rowSpacing))
            readonly property int displayRows: Math.max(1, Math.min(10, rowsThatFit, root.displayItems.length))
            readonly property color selectionFill: Qt.tint(Theme.base, Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.13))
            readonly property color selectionBorder: Qt.tint(Theme.surface1, Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.44))
            readonly property color iconFill: Qt.tint(Theme.mantle, Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.15))

            anchors.centerIn: parent
            width: Math.min(640, Math.max(0, parent.width - 32))
            height: Math.min(availableHeight, chromeHeight + displayRows * root.rowHeight + (displayRows - 1) * rowSpacing)
            color: Theme.base
            border.color: Theme.surface1
            radius: 26

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 0

                RowLayout {
                    id: header
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredHeight: 80
                    spacing: 14

                    LauncherKeycap {
                        id: backButton
                        visible: root.activeMenu !== "root"
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        text: "←"
                        Accessible.role: Accessible.Button
                        Accessible.name: "Back"
                        Accessible.onPressAction: root.goBack()

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.goBack()
                        }
                    }

                    Text {
                        visible: !backButton.visible
                        text: ""
                        color: Theme.mauve
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 23
                        Accessible.ignored: true
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Theme.text
                        selectionColor: Theme.mauve
                        selectedTextColor: Theme.base
                        clip: true
                        font.pixelSize: 23
                        verticalAlignment: TextInput.AlignVCenter
                        Accessible.name: placeholder.text
                        onTextChanged: {
                            root.fileItems = []
                            fileSearchTimer.restart()
                        }

                        Text {
                            id: placeholder
                            anchors.fill: parent
                            visible: searchField.text.length === 0
                            text: root.activeMenu === "root" ? "Search apps and files…" : "Search " + root.menuTitle().toLowerCase() + "…"
                            color: Theme.subtext0
                            font: searchField.font
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onEscapePressed: root.goBack()
                        Keys.onUpPressed: root.moveSelection(-1)
                        Keys.onDownPressed: root.moveSelection(1)
                        Keys.onReturnPressed: root.activate(root.displayItems[root.selectedIndex])
                        Keys.onEnterPressed: root.activate(root.displayItems[root.selectedIndex])
                        Keys.onPressed: event => {
                            if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) && searchField.text.length === 0) {
                                root.goBack()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right && searchField.text.length === 0) {
                                root.activate(root.displayItems[root.selectedIndex])
                                event.accepted = true
                            }
                        }
                    }

                    LauncherKeycap { text: "Esc" }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.surface1
                }

                ListView {
                    id: results
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: launcherPanel.listInset
                    model: root.displayItems
                    spacing: launcherPanel.rowSpacing
                    clip: true
                    currentIndex: root.selectedIndex

                    delegate: Rectangle {
                        id: result
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === root.selectedIndex

                        width: results.width
                        height: root.rowHeight
                        color: selected ? launcherPanel.selectionFill : "transparent"
                        border.width: selected ? 1 : 0
                        border.color: launcherPanel.selectionBorder
                        radius: 12

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 14

                            Rectangle {
                                id: resultIcon
                                readonly property bool app: result.modelData.kind === "app"
                                readonly property bool pdfFile: result.modelData.kind === "file" && /\.pdf$/i.test(result.modelData.path)
                                Layout.preferredWidth: 52
                                Layout.preferredHeight: 52
                                radius: 13
                                color: app ? "transparent" : launcherPanel.iconFill

                                ClippingRectangle {
                                    id: appIcon
                                    anchors.centerIn: parent
                                    width: 48
                                    height: 48
                                    visible: resultIcon.app
                                    radius: 13
                                    color: "transparent"
                                    border.width: 0

                                    IconImage {
                                        anchors.fill: parent
                                        source: appIcon.visible ? Quickshell.iconPath(result.modelData.icon, "application-x-executable") : ""
                                        asynchronous: true
                                    }
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 32
                                    height: 38
                                    visible: resultIcon.pdfFile
                                    color: "transparent"
                                    border.color: Theme.mauve
                                    border.width: 1
                                    radius: 4

                                    Text {
                                        anchors.centerIn: parent
                                        text: "PDF"
                                        color: Theme.mauve
                                        font.family: "MonaspiceKr Nerd Font"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }

                                Text {
                                    anchors.fill: parent
                                    visible: !resultIcon.app && !resultIcon.pdfFile
                                    text: result.modelData.icon
                                    color: Theme.mauve
                                    font.family: "MonaspiceKr Nerd Font"
                                    font.pixelSize: 24
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    Layout.fillWidth: true
                                    text: root.labelFor(result.modelData.label)
                                    textFormat: Text.StyledText
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.descriptionFor(result.modelData)
                                    textFormat: Text.PlainText
                                    color: Theme.subtext0
                                    elide: Text.ElideRight
                                    font.pixelSize: 17
                                }
                            }

                            Text {
                                visible: result.modelData.kind === "menu"
                                text: "›"
                                color: result.selected ? Theme.mauve : Theme.subtext0
                                font.family: "MonaspiceKr Nerd Font"
                                font.pixelSize: 20
                            }

                            LauncherKeycap {
                                visible: result.selected && result.modelData.kind !== "menu"
                                text: "↵"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = result.index
                            onClicked: root.activate(result.modelData)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.displayItems.length === 0
                        text: "No matches"
                        color: Theme.subtext0
                        font.pixelSize: 19
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.surface1
                }

                RowLayout {
                    id: footer
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.leftMargin: 17
                    Layout.rightMargin: 17
                    Layout.preferredHeight: 50
                    spacing: 7

                    Text {
                        text: "Go"
                        color: root.activeMenu === "root" ? Theme.subtext0 : Theme.text
                        font.pixelSize: 17
                        Accessible.role: Accessible.Button
                        Accessible.name: "Main menu"
                        Accessible.onPressAction: root.show()

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.show()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.activeMenu !== "root" ? "› " + root.menuTitle() : root.query ? "› Search" : ""
                        color: Theme.subtext0
                        elide: Text.ElideRight
                        font.pixelSize: 17
                    }

                    LauncherKeycap { text: "↑ ↓" }

                    Text {
                        text: "Select"
                        color: Theme.subtext0
                        font.pixelSize: 17
                    }

                    LauncherKeycap {
                        Layout.leftMargin: 5
                        text: "↵"
                    }

                    Text {
                        text: "Open"
                        color: Theme.subtext0
                        font.pixelSize: 17
                    }
                }
            }
        }
    }
}

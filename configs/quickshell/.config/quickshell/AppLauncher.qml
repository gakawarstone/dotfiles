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
    readonly property int rowHeight: searchField.text.length > 0 ? 68 : 58

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
            application: app
        }))

    readonly property var allItems: menuItems.concat(applicationItems)
    readonly property var displayItems: {
        const rawQuery = searchField.text.trim()
        const variants = queryVariants(rawQuery)
        let items

        if (rawQuery) {
            items = allItems.filter(item => {
                if (!isDescendantOf(item, activeMenu))
                    return false
                const hay = (item.label + " " + item.description + " " + pathFor(item)).toLowerCase()
                const hayTranslit = transliterate(hay, "cyr")
                return variants.some(v => hay.includes(v) || hayTranslit.includes(v))
            })
        } else {
            items = allItems.filter(item => item.parent === activeMenu)
        }

        // Prefer the Latin (transliterated) form for sorting when the query is Cyrillic,
        // e.g. "кув" should rank items starting with "red".
        const sortQuery = variants.find(v => /^[a-z0-9]+$/i.test(v)) || rawQuery.toLowerCase()

        return items.sort((left, right) => {
            if (!rawQuery && activeMenu !== "apps")
                return menuItems.indexOf(left) - menuItems.indexOf(right)
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
            anchors.centerIn: parent
            width: Math.min(450, parent.width - 40)
            height: Math.min(600, 86 + Math.max(1, root.displayItems.length) * root.rowHeight + Math.max(0, root.displayItems.length - 1) * 4)
            color: Theme.base
            border.color: Theme.text
            border.width: 2
            radius: 10

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 8

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        color: Theme.text
                        selectionColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
                        clip: true
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 20
                        font.weight: Font.Medium
                        verticalAlignment: TextInput.AlignVCenter

                        Text {
                            anchors.fill: parent
                            visible: searchField.text.length === 0
                            text: root.menuTitle() + "..."
                            color: Theme.text
                            opacity: 0.58
                            font: searchField.font
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
                }

                ListView {
                    id: results
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.displayItems
                    spacing: 4
                    clip: true
                    currentIndex: root.selectedIndex

                    delegate: Rectangle {
                        id: result
                        required property var modelData
                        required property int index

                        width: results.width
                        height: root.rowHeight
                        color: index === root.selectedIndex ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent"
                        radius: 10

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 6

                            Item {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36

                                IconImage {
                                    anchors.fill: parent
                                    visible: result.modelData.kind === "app"
                                    source: visible ? Quickshell.iconPath(result.modelData.icon, "application-x-executable") : ""
                                    asynchronous: true
                                }

                                Text {
                                    anchors.fill: parent
                                    visible: result.modelData.kind !== "app"
                                    text: result.modelData.icon
                                    color: result.index === root.selectedIndex ? Theme.mauve : Theme.text
                                    font.family: "MonaspiceKr Nerd Font"
                                    font.pixelSize: 28
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    Layout.fillWidth: true
                                    text: result.modelData.label
                                    color: result.index === root.selectedIndex ? Theme.mauve : Theme.text
                                    elide: Text.ElideRight
                                    font.family: "MonaspiceKr Nerd Font"
                                    font.pixelSize: 18
                                    font.weight: Font.Medium
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.pathFor(result.modelData)
                                    visible: searchField.text.length > 0 && text.length > 0
                                    color: Theme.text
                                    opacity: 0.52
                                    elide: Text.ElideRight
                                    font.family: "MonaspiceKr Nerd Font"
                                    font.pixelSize: 14
                                }
                            }

                            Text {
                                visible: result.modelData.kind === "menu"
                                text: "›"
                                color: result.index === root.selectedIndex ? Theme.mauve : Theme.text
                                opacity: 0.36
                                font.family: "MonaspiceKr Nerd Font"
                                font.pixelSize: 18
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
                        color: Theme.overlay0
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 17
                    }
                }
            }
        }
    }
}

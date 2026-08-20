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
    readonly property var applications: {
        const query = searchField.text.trim().toLowerCase()
        return DesktopEntries.applications.values
            .filter(app => !app.noDisplay && app.name.toLowerCase().includes(query))
            .sort((left, right) => left.name.localeCompare(right.name))
    }
    readonly property var activeScreen: {
        const monitor = Hyprland.focusedMonitor
        for (let i = 0; monitor && i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === monitor.name)
                return Quickshell.screens[i]
        }
        return Quickshell.screens[0] ?? null
    }

    function show() {
        searchField.text = ""
        selectedIndex = 0
        open = true
        Qt.callLater(() => searchField.forceActiveFocus())
    }

    function hide() {
        open = false
    }

    function moveSelection(offset) {
        if (applications.length === 0)
            return
        selectedIndex = (selectedIndex + offset + applications.length) % applications.length
        results.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function launch(app) {
        if (!app)
            return
        app.execute()
        hide()
    }

    onApplicationsChanged: selectedIndex = 0

    IpcHandler {
        target: "launcher"

        function toggle() {
            root.open ? root.hide() : root.show()
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
            color: "#80000000"

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.max(80, parent.height * 0.16)
            width: Math.min(600, parent.width - 40)
            height: Math.min(500, parent.height - anchors.topMargin - 40)
            color: Theme.base
            border.color: Theme.surface0
            border.width: 1
            radius: 10

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    color: Theme.mantle
                    border.color: searchField.activeFocus ? Theme.mauve : Theme.surface0
                    border.width: 1
                    radius: 7

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        anchors.margins: 12
                        color: Theme.text
                        selectionColor: Theme.surface2
                        clip: true
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 16

                        Text {
                            anchors.fill: parent
                            visible: searchField.text.length === 0
                            text: "Search applications…"
                            color: Theme.overlay0
                            font: searchField.font
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onEscapePressed: root.hide()
                        Keys.onUpPressed: root.moveSelection(-1)
                        Keys.onDownPressed: root.moveSelection(1)
                        Keys.onReturnPressed: root.launch(root.applications[root.selectedIndex])
                        Keys.onEnterPressed: root.launch(root.applications[root.selectedIndex])
                    }
                }

                ListView {
                    id: results
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.applications
                    spacing: 4
                    clip: true
                    currentIndex: root.selectedIndex

                    delegate: Rectangle {
                        id: result
                        required property var modelData
                        required property int index

                        width: results.width
                        height: 54
                        color: index === root.selectedIndex ? Theme.surface0 : "transparent"
                        radius: 7

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            IconImage {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                source: Quickshell.iconPath(result.modelData.icon, "application-x-executable")
                                asynchronous: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: result.modelData.name
                                color: Theme.text
                                elide: Text.ElideRight
                                font.family: "MonaspiceKr Nerd Font"
                                font.pixelSize: 15
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = result.index
                            onClicked: root.launch(result.modelData)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.applications.length === 0
                        text: "No applications found"
                        color: Theme.overlay0
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "."
import "./components"

Scope {
    id: root

    property bool centerOpen: false
    property var activeScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property var activeAnchor: null
    readonly property int historyCount: historyModel.count

    function registerAnchor(anchorItem, screen) {
        if (!activeAnchor) activeAnchor = anchorItem
        if (!activeScreen && screen) activeScreen = screen
    }

    function toggle(anchorItem, screen) {
        if (anchorItem) activeAnchor = anchorItem
        if (screen) activeScreen = screen
        centerOpen = !centerOpen
    }

    function closeCenter() {
        centerOpen = false
    }

    function clearHistory() {
        historyModel.clear()
    }

    function timestamp() {
        return Qt.formatTime(new Date(), "HH:mm")
    }

    function remember(notification) {
        const entry = {
            "notificationId": notification.id,
            "appName": notification.appName || "",
            "appIcon": notification.appIcon || "",
            "summary": notification.summary || "Notification",
            "body": notification.body || "",
            "urgency": notification.urgency,
            "timestamp": timestamp()
        }

        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).notificationId === notification.id) {
                historyModel.set(i, entry)
                return
            }
        }

        historyModel.insert(0, entry)
        if (historyModel.count > 50) historyModel.remove(50, historyModel.count - 50)
    }

    ListModel {
        id: historyModel
        dynamicRoles: true
    }

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: false
        imageSupported: false

        onNotification: notification => {
            notification.tracked = true
            root.remember(notification)
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle() {
            root.toggle(null, null)
        }

        function clear() {
            root.clearHistory()
        }
    }

    PanelWindow {
        id: toastWindow
        screen: root.activeScreen
        visible: notificationServer.trackedNotifications.values.length > 0 && !root.centerOpen
        color: "transparent"
        implicitWidth: 380
        implicitHeight: toastColumn.implicitHeight
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "quickshell-notifications"

        anchors {
            top: true
            right: true
        }

        margins {
            top: 50
            right: 20
        }

        ColumnLayout {
            id: toastColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            Repeater {
                model: notificationServer.trackedNotifications

                delegate: NotificationCard {
                    required property var modelData

                    Layout.fillWidth: true
                    appName: modelData.appName
                    appIcon: modelData.appIcon
                    summary: modelData.summary
                    body: modelData.body
                    urgency: modelData.urgency
                    closeAction: function() { modelData.dismiss() }

                    Timer {
                        interval: modelData.expireTimeout > 0 ? Math.max(2000, Math.min(modelData.expireTimeout, 10000)) : (modelData.urgency === NotificationUrgency.Critical ? 10000 : 6000)
                        running: true
                        onTriggered: modelData.expire()
                    }
                }
            }
        }
    }

    PopupWindow {
        id: centerWindow
        visible: root.centerOpen && root.activeAnchor !== null
        color: "transparent"
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        anchor {
            item: root.activeAnchor
        }

        relativeX: root.activeAnchor ? root.activeAnchor.width - implicitWidth : 0
        relativeY: root.activeAnchor ? root.activeAnchor.height + 5 : 0

        onVisibleChanged: {
            if (!visible) root.centerOpen = false
        }

        Rectangle {
            id: content
            implicitWidth: 400
            implicitHeight: 460
            color: Theme.base
            border.color: Theme.surface0
            border.width: 1
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Notifications"
                        color: Theme.text
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: historyModel.count > 0
                        text: "Clear all"
                        color: clearMouse.containsMouse ? Theme.red : Theme.overlay1
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 11

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearHistory()
                        }
                    }

                    Text {
                        text: "󰅖"
                        color: centerCloseMouse.containsMouse ? Theme.red : Theme.overlay1
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 15

                        MouseArea {
                            id: centerCloseMouse
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeCenter()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.surface0
                }

                ListView {
                    id: historyList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: historyModel
                    spacing: 12
                    clip: true

                    delegate: Item {
                        id: historyDelegate

                        required property int index
                        required property string appName
                        required property string appIcon
                        required property string summary
                        required property string body
                        required property string timestamp
                        required property int urgency

                        width: historyList.width
                        height: card.implicitHeight

                        NotificationCard {
                            id: card
                            anchors.fill: parent
                            appName: historyDelegate.appName
                            appIcon: historyDelegate.appIcon
                            summary: historyDelegate.summary
                            body: historyDelegate.body
                            timestamp: historyDelegate.timestamp
                            urgency: historyDelegate.urgency
                            outlined: true
                            interactive: false
                            closeAction: function() { historyModel.remove(historyDelegate.index) }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: historyModel.count === 0
                        text: "󰂜\nAll caught up"
                        color: Theme.overlay0
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "MonaspiceKr Nerd Font"
                        font.pixelSize: 14
                        lineHeight: 1.6
                    }
                }
            }
        }
    }
}

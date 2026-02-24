import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Wayland

PopupWindow {
    id: popup
    
    property var anchorItem
    property var adapter: Bluetooth.defaultAdapter

    color: "transparent"
    width: content.width
    height: content.height
    
    anchor {
        item: popup.anchorItem
    }

    relativeX: -40
    relativeY: popup.anchorItem ? popup.anchorItem.height + 5 : 0

    Rectangle {
        id: content
        width: 250
        height: mainColumn.implicitHeight + 20
        color: "#1e1e2e"
        border.color: "#313244"
        border.width: 1
        radius: 8

        ColumnLayout {
            id: mainColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Bluetooth"
                    color: "#cdd6f4"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "MonaspiceKr Nerd Font"
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 40
                    height: 20
                    radius: 10
                    color: popup.adapter && popup.adapter.enabled ? "#a6e3a1" : "#45475a"
                    
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: "#1e1e2e"
                        x: popup.adapter && popup.adapter.enabled ? 22 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Behavior on x {
                            NumberAnimation { duration: 200 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (popup.adapter) {
                                popup.adapter.enabled = !popup.adapter.enabled;
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#313244"
            }

            ColumnLayout {
                id: deviceListLayout
                Layout.fillWidth: true
                spacing: 5

                Repeater {
                    model: Bluetooth.devices.values
                    delegate: MouseArea {
                        id: deviceItem
                        Layout.fillWidth: true
                        implicitHeight: 35
                        hoverEnabled: true

                        Rectangle {
                            anchors.fill: parent
                            color: deviceItem.containsMouse ? "#313244" : "transparent"
                            radius: 4
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            
                            Text {
                                text: modelData.connected ? "󰂱" : "󰂯"
                                color: modelData.connected ? "#89b4fa" : "#6c7086"
                                font.pixelSize: 16
                                font.family: "MonaspiceKr Nerd Font"
                            }

                            Text {
                                text: modelData.name || modelData.address
                                color: "#cdd6f4"
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.family: "MonaspiceKr Nerd Font"
                            }

                            Text {
                                visible: modelData.connected && modelData.batteryAvailable
                                text: Math.round(modelData.battery * 100) + "%"
                                color: "#a6e3a1"
                                font.pixelSize: 12
                                font.family: "MonaspiceKr Nerd Font"
                            }
                        }

                        onClicked: {
                            if (modelData.connected) {
                                modelData.disconnect();
                            } else {
                                modelData.connect();
                            }
                        }
                    }
                }

                Text {
                    visible: !Bluetooth.devices.values || Bluetooth.devices.values.length === 0
                    text: "No devices found"
                    color: "#6c7086"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignCenter
                    font.family: "MonaspiceKr Nerd Font"
                }
            }
        }
    }
}

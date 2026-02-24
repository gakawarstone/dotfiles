import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Wayland

MouseArea {
    id: root
    Layout.fillHeight: true
    implicitWidth: layout.implicitWidth
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    property bool menuOpen: false
    property var adapter: Bluetooth.defaultAdapter
    property var connectedDevice: {
        if (!Bluetooth || !Bluetooth.devices || !Bluetooth.devices.values) return null;
        for (let i = 0; i < Bluetooth.devices.values.length; i++) {
            const device = Bluetooth.devices.values[i];
            if (device && device.connected) return device;
        }
        return null;
    }

    onClicked: menuOpen = !menuOpen

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        Text {
            text: !root.adapter || !root.adapter.enabled ? "󰂲" : (root.connectedDevice ? "󰂰" : "󰂯")
            font.pixelSize: 18
            color: !root.adapter || !root.adapter.enabled ? "#f38ba8" : (root.connectedDevice ? "#89b4fa" : "#cdd6f4")
            font.family: "MonaspiceKr Nerd Font"
        }

        Text {
            visible: root.connectedDevice !== null
            text: root.connectedDevice ? root.connectedDevice.name : ""
            color: "#cdd6f4"
            font.pixelSize: 14
            font.family: "MonaspiceKr Nerd Font"
        }
    }

    BluetoothPopup {
        visible: root.menuOpen
        anchorItem: root
        adapter: root.adapter

        onVisibleChanged: {
            if (!visible) root.menuOpen = false;
        }
    }
}

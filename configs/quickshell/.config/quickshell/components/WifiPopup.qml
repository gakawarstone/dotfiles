import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: popup

    property var anchorItem
    property bool wifiEnabled: false
    property bool busy: false
    property var networks: []
    property string passwordSsid: ""
    property string errorMessage: ""
    property string pendingSsid: ""
    property bool pendingPasswordPrompt: false
    property string wifiDevice: ""
    property string actionType: ""
    readonly property string popupFont: "MonaspiceKr Nerd Font"

    signal networkChanged()

    function splitNmcli(line) {
        const fields = [];
        let field = "";
        let escaped = false;
        for (let i = 0; i < line.length; ++i) {
            const character = line[i];
            if (escaped) {
                field += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":") {
                fields.push(field);
                field = "";
            } else {
                field += character;
            }
        }
        fields.push(field);
        return fields;
    }

    function refresh() {
        if (!radioState.running) radioState.running = true;
        if (!deviceState.running) deviceState.running = true;
        if (!scanNetworks.running) scanNetworks.running = true;
    }

    function connectNetwork(ssid, secured, password) {
        popup.pendingSsid = ssid;
        popup.pendingPasswordPrompt = secured && password === "";
        runAction("connect", password === ""
            ? ["nmcli", "device", "wifi", "connect", ssid]
            : ["nmcli", "device", "wifi", "connect", ssid, "password", password]);
    }

    function runAction(type, command) {
        popup.actionType = type;
        popup.errorMessage = "";
        popup.busy = true;
        actionProcess.command = command;
        actionProcess.running = true;
    }

    function isSecured(network) {
        return network.security !== "" && network.security !== "--";
    }

    function submitPassword() {
        if (passwordInput.text !== "")
            connectNetwork(passwordSsid, true, passwordInput.text);
    }

    color: "transparent"
    width: content.width
    height: content.height
    anchor.item: popup.anchorItem
    relativeX: -160
    relativeY: popup.anchorItem ? popup.anchorItem.height + 5 : 0

    onVisibleChanged: {
        if (visible) refresh();
        else {
            passwordSsid = "";
            errorMessage = "";
        }
    }

    Process {
        id: radioState
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector { id: radioCollector }
        onExited: exitCode => {
            popup.wifiEnabled = exitCode === 0 && radioCollector.text.trim() === "enabled";
        }
    }

    Process {
        id: deviceState
        command: ["nmcli", "--terse", "--fields", "DEVICE,TYPE", "device", "status"]
        stdout: StdioCollector { id: deviceCollector }
        onExited: exitCode => {
            popup.wifiDevice = "";
            if (exitCode !== 0) return;
            const lines = deviceCollector.text.trim().split("\n");
            for (let i = 0; i < lines.length; ++i) {
                const fields = popup.splitNmcli(lines[i]);
                if (fields.length >= 2 && fields[1] === "wifi") {
                    popup.wifiDevice = fields[0];
                    break;
                }
            }
        }
    }

    Process {
        id: scanNetworks
        command: ["nmcli", "--terse", "--escape", "yes", "--fields", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector { id: scanCollector }
        onExited: exitCode => {
            if (exitCode !== 0) {
                popup.networks = [];
                return;
            }

            const strongest = {};
            const lines = scanCollector.text.trim().split("\n");
            for (let i = 0; i < lines.length; ++i) {
                const fields = popup.splitNmcli(lines[i]);
                if (fields.length < 4 || fields[1] === "") continue;
                const network = {
                    active: fields[0] === "*",
                    ssid: fields[1],
                    signal: Number(fields[2]) || 0,
                    security: fields.slice(3).join(":")
                };
                if (!strongest[network.ssid] || network.signal > strongest[network.ssid].signal)
                    strongest[network.ssid] = network;
            }

            const result = Object.keys(strongest).map(key => strongest[key]);
            result.sort((left, right) => {
                if (left.active !== right.active) return left.active ? -1 : 1;
                return right.signal - left.signal;
            });
            popup.networks = result.slice(0, 8);
        }
    }

    Process {
        id: actionProcess
        stderr: StdioCollector { id: actionError }
        onExited: exitCode => {
            popup.busy = false;
            if (popup.actionType === "connect" && exitCode === 0) {
                popup.passwordSsid = "";
                passwordInput.text = "";
            } else if (popup.actionType === "connect" && popup.pendingPasswordPrompt) {
                popup.passwordSsid = popup.pendingSsid;
                popup.errorMessage = "Password required";
                passwordInput.forceActiveFocus();
            } else if (exitCode !== 0) {
                const fallback = popup.actionType === "toggle"
                    ? "Could not change Wi-Fi state"
                    : popup.actionType === "disconnect" ? "Could not disconnect" : "Could not connect";
                popup.errorMessage = actionError.text.trim().split("\n")[0] || fallback;
            }
            popup.networkChanged();
            popup.refresh();
        }
    }

    Rectangle {
        id: content
        implicitWidth: 300
        implicitHeight: mainColumn.implicitHeight + 20
        color: Theme.base
        border.color: Theme.surface0
        border.width: 1
        radius: 8

        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Wi-Fi"
                    color: Theme.text
                    font.pixelSize: 16
                    font.bold: true
                    font.family: popup.popupFont
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "󰑐"
                    color: refreshArea.containsMouse ? Theme.blue : Theme.overlay0
                    font.pixelSize: 16
                    font.family: popup.popupFont

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.refresh()
                    }
                }

                Rectangle {
                    width: 40
                    height: 20
                    radius: 10
                    color: popup.wifiEnabled ? Theme.green : Theme.surface1

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: Theme.base
                        x: popup.wifiEnabled ? 22 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on x { NumberAnimation { duration: 200 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !popup.busy
                        onClicked: {
                            popup.runAction("toggle", ["nmcli", "radio", "wifi", popup.wifiEnabled ? "off" : "on"]);
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.surface0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Repeater {
                    model: popup.networks

                    delegate: MouseArea {
                        id: networkItem
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 36
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: popup.wifiEnabled && !popup.busy

                        Rectangle {
                            anchors.fill: parent
                            color: networkItem.containsMouse ? Theme.surface0 : "transparent"
                            radius: 4
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: modelData.signal >= 75 ? "󰤨" : (modelData.signal >= 50 ? "󰤥" : (modelData.signal >= 25 ? "󰤢" : "󰤟"))
                                color: modelData.active ? Theme.blue : Theme.overlay0
                                font.pixelSize: 16
                                font.family: popup.popupFont
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.ssid
                                color: Theme.text
                                elide: Text.ElideRight
                                font.pixelSize: 14
                                font.family: popup.popupFont
                            }

                            Text {
                                visible: popup.isSecured(modelData)
                                text: "󰌾"
                                color: Theme.overlay0
                                font.pixelSize: 13
                                font.family: popup.popupFont
                            }
                        }

                        onClicked: {
                            if (modelData.active && popup.wifiDevice !== "") {
                                popup.runAction("disconnect", ["nmcli", "device", "disconnect", popup.wifiDevice]);
                            } else if (!modelData.active) {
                                popup.connectNetwork(modelData.ssid, popup.isSecured(modelData), "");
                            }
                        }
                    }
                }

                Text {
                    visible: !popup.wifiEnabled || popup.networks.length === 0
                    text: popup.wifiEnabled ? "No networks found" : "Wi-Fi is disabled"
                    color: Theme.overlay0
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignCenter
                    font.family: popup.popupFont
                }
            }

            RowLayout {
                visible: popup.passwordSsid !== ""
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 4
                    color: Theme.surface0

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        selectionColor: Theme.blue
                        echoMode: TextInput.Password
                        clip: true
                        font.pixelSize: 13
                        font.family: popup.popupFont
                        onAccepted: popup.submitPassword()
                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        visible: passwordInput.text === "" && !passwordInput.activeFocus
                        text: "Password for " + popup.passwordSsid
                        color: Theme.overlay0
                        elide: Text.ElideRight
                        font.pixelSize: 13
                        font.family: popup.popupFont
                    }
                }

                Rectangle {
                    id: connectButton
                    implicitWidth: 72
                    height: 32
                    radius: 4
                    color: connectArea.containsMouse ? Theme.blue : Theme.surface1

                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: Theme.text
                        font.pixelSize: 12
                        font.family: popup.popupFont
                    }

                    MouseArea {
                        id: connectArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !popup.busy
                        onClicked: popup.submitPassword()
                    }
                }
            }

            Text {
                visible: popup.errorMessage !== ""
                Layout.fillWidth: true
                text: popup.errorMessage
                color: Theme.red
                wrapMode: Text.Wrap
                font.pixelSize: 11
                font.family: popup.popupFont
            }
        }
    }
}

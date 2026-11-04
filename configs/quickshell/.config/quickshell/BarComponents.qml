import QtQuick

Item {
    id: root
    visible: false

    property string hostname: ""
    property bool workspaces: true
    property bool media: true
    property bool networkSpeed: true
    property bool codexUsage: true
    property bool wifi: false
    property bool hsflVpn: true
    property bool lanMouse: true
    property bool pomodoro: true
    property bool volume: true
    property bool microphone: true
    property bool bluetooth: true
    property bool battery: true
    property bool keyboardLayout: true
    property bool notificationIndicator: true

    // Add a State for each host here. See README.md.
    states: []
}

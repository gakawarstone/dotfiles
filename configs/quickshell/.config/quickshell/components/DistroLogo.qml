import Quickshell.Io
import QtQuick
import ".."

Text {
    FileView {
        id: osRelease
        path: "/etc/os-release"
        preload: true
    }

    text: /^ID=nixos$/m.test(osRelease.text()) ? "" : "󰣇"
    font.pixelSize: 22
    color: Theme.blue
    font.family: "MonaspiceKr Nerd Font"
}

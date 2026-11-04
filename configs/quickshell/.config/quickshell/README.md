# HS Flensburg VPN

Click **HSFL** next to Wi-Fi, then **Install VPN support** on first use.
The Kitty terminal installs `openconnect` and
`networkmanager-vpn-plugin-openconnect` using `sudo pacman -S --needed`.
On older Arch installations the plugin package is called
`networkmanager-openconnect`.

Click **Connect** and enter your university username, e.g. `abcd1234`, and
password in the terminal. The student group `HSFL-Studierende` and server
`https://vpn.hs-flensburg.de` are selected automatically. Close the terminal
or press Ctrl+C to cancel a login. Once connected, the terminal closes and
NetworkManager keeps the tunnel running. Click **Disconnect** to stop it.
The lock turns green when NetworkManager reports an active connection.

The helper creates a system-wide `HS Flensburg VPN` NetworkManager profile
with autoconnect disabled. OpenConnect requires an empty
`connection.permissions` list on NetworkManager 1.58. Existing private HSFL
profiles are repaired before login. Passwords are not saved. Session cookies
are passed to NetworkManager through stdin, with secret storage disabled.
OpenConnect uses normal certificate validation during login.

The tunnel uses MTU 1280. Larger packets were dropped on the HSFL VPN path,
causing HTTPS connections to stall despite a connected VPN and working DNS.
The helper applies this setting to new and existing HSFL profiles before login.

VPN login requires your university credentials. The connection cannot be
verified without them. NetworkManager manages the VPN routes and DNS.

Sources: [university VPN instructions](https://hs-flensburg.de/studium/service/IT-services/vpn)
and [OpenConnect authentication with NetworkManager](https://www.infradead.org/openconnect/nonroot.html).

# Bar components by host

`BarComponents.qml` selects which bar components to load for each Linux
hostname. The hostname comes from `/proc/sys/kernel/hostname` (also printed by
`hostname`). Add a QML `State` for each machine to the `states` list. For
example, replace the placeholders below with your own hostnames and preferred
components:

```qml
states: [
    State {
        name: "desktop"
        when: root.hostname === "your-desktop-hostname"
        PropertyChanges { target: root; wifi: true; networkSpeed: false }
    },
    State {
        name: "laptop"
        when: root.hostname === "your-laptop-hostname"
        PropertyChanges { target: root; wifi: true; lanMouse: false }
    }
]
```

Each state overrides only the listed properties. The boolean properties in
`BarComponents.qml` list all available components and preserve the existing
bar: all are enabled except `wifi`. If no state matches, including when the
hostname cannot be read, those defaults apply. Component positions stay fixed
as in `Bar.qml`. Disabled bar components are not instantiated, but shared
services such as the notification center and Pomodoro timer remain available.
Restart Quickshell after changing this file. This works with the existing Arch
startup commands and does not require a Nix configuration.

To test the host selection, run Qt 6's QML test runner from this directory:

```sh
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/tst_barcomponents.qml
```

The test runner's path may differ on other distributions.

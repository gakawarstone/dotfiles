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

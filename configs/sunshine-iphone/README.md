# iPhone screen

An additional Hyprland output for iPhone 16, with workspace 6, scrolling layout,
scale 3, and no Quickshell bar. It can run alongside the iPad screen.

```bash
bash ~/dotfiles/scripts/install_iphone_screen.sh
```

If Sunshine and jq are already installed, prepare only the user configuration:

```bash
bash ~/dotfiles/scripts/install_iphone_screen.sh --configure-only
iphone-screen on
```

For the default sideways portrait mode and normal landscape, use
[Moonlight](https://apps.apple.com/app/id1000551566). The sideways mode keeps
the desktop vertical and sends its image rotated in a 2556x1179 video frame.
For an upright portrait stream without this workaround, use
[VoidLink Extreme](https://apps.apple.com/app/id6755103808), a paid Sunshine
client with portrait support. Allow local network access. The standard
[Moonlight](https://apps.apple.com/app/id1000551566) iOS app supports landscape
only; its orientation restriction is declared in
[Limelight-Info.plist](https://github.com/moonlight-stream/moonlight-ios/blob/master/Limelight/Limelight-Info.plist).

1. Open `https://localhost:48090` on the computer and create credentials for
   this Sunshine instance. Its pairing state is separate from the iPad profile.
2. Manually add `192.168.178.22:48089` in the client, or use the address printed
   by `iphone-screen on`. Enter the PIN on this instance's PIN page.
3. Choose the resolution matching the active orientation, 60 FPS, HEVC,
   about 20 Mbps, HDR off, and on-screen gamepad controls off.
4. Open **iPhone Desktop**. `Super+6` focuses its workspace;
   `Super+Shift+6` moves a window there.

```bash
iphone-screen on portrait   # 1179x2556, logical desktop 393x852
iphone-screen on landscape  # 2556x1179, logical desktop 852x393
iphone-screen on sideways   # portrait desktop, sideways 2556x1179 stream
iphone-screen off
iphone-screen status
iphone-screen logs
```

`on` defaults to sideways. Keep Moonlight at 2556x1179 and hold the phone
vertically for this mode. Workspace 6 has no gaps, window borders, or shadows.
The portrait desktop is 393x852 logical pixels.

To switch orientation, disconnect the streaming
session, run the corresponding `on` command, change the client's resolution,
and reconnect. Full-screen Landscape matches 2556x1179; for portrait enter
the custom resolution 1179x2556 if no matching preset is available. Unlock
the iPhone's orientation lock when using portrait mode in VoidLink.

The IPHONE output starts at 6300x0, after the iPad output. `off` returns its
workspaces to a physical monitor and stops only `iphone-screen.service`.
Pairing keys and user configuration live in `~/.config/sunshine-iphone`.
The Sunshine base port is 48089 and its local web UI uses 48090.

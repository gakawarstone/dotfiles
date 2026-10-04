# iPad screen

Hyprland + Sunshine + Moonlight for an iPad Air M2 11-inch over Wi-Fi.
The IPAD output is 2360x1640 at 60 Hz, scale 2, to the right of the two
2560x1440 desktop monitors. Workspace 5 belongs to IPAD.

Run inside the existing Hyprland session, as your normal user:

```bash
bash ~/dotfiles/scripts/install_ipad_screen.sh
```

The installer uses the official Sunshine 2026.914.233613 Arch package,
checks its SHA-256, installs dependencies with pacman, and starts the screen.
It asks for sudo only for package installation. Existing configuration files
are preserved on reruns. `--configure-only` prepares user files without sudo.
The existing dotfiles Hyprland directory must be linked to `~/.config/hypr`.

Install [Moonlight Game Streaming](https://apps.apple.com/app/id1000551566)
on the iPad. Allow access to the local network.

1. Open `https://localhost:47990` on the computer. Accept the local self-signed
   certificate and create a Sunshine username and password.
2. In Moonlight, add the computer using the IP printed by `ipad-screen on`.
3. Enter Moonlight's PIN in Sunshine's PIN page.
4. Set Moonlight to Native / Full-screen Landscape, 2360x1640, 60 FPS,
   HEVC, about 25 Mbps, and turn HDR and on-screen gamepad controls off.
5. Open **iPad Desktop**. `Super+5` focuses its workspace;
   `Super+Shift+5` moves the focused window there.

```bash
ipad-screen on
ipad-screen off
ipad-screen status
ipad-screen logs
```

`off` stops only this Sunshine instance, moves the iPad workspaces to HDMI-A-1
(or another physical monitor if absent), then removes the virtual output.
Disconnecting Moonlight alone leaves the virtual screen available until `off`.
The screen is not started automatically after login.

Edit `~/.config/hypr/ipad.lua` to change position or scale, then run `off`/`on`.
Scale 1.25 gives more desktop space; scale 2 gives larger text.
The Sunshine profile, pairing state, and keys live in `~/.config/sunshine-ipad`.
Logs are also available with `journalctl --user -u ipad-screen.service`.

The server uses `capture = wlr`, `encoder = nvenc`, and `output_name = IPAD`.
The web UI accepts only local connections and UPnP is disabled. Both devices
should be on the same LAN, with the iPad on 5/6 GHz Wi-Fi if available.
If another Sunshine instance is running, stop it before `ipad-screen on`.

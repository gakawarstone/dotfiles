# PS5 PRO

PlayStation launcher with local wake-up before opening Chiaki-ng. The script
discovers the paired PS5, sends a wake command when it reports standby, and waits
up to 35 seconds for it to report ready. The launcher leaves existing Chiaki
instances running to protect sessions with other consoles. An existing instance
may occupy the UDP port needed for wake-up, so wake-up may fail until Chiaki is
closed manually. The launcher opens Chiaki even when local wake fails and sends
a notification if it cannot confirm the console is ready.

Install as your normal desktop user:

```bash
bash ~/dotfiles/scripts/install_ps5_pro.sh
```

The installer downloads the official x86_64 weekly Flatpak at commit `a9a2805`,
verifies its SHA-256, and installs it for the current user on branch `master`.
This build includes the PSN certificate-chain recovery fix. The system-wide
stable build can remain installed. The weekly build reports version `1.10.0`,
so the version number alone does not identify the patched build.

Required commands are `flatpak`, `curl`, `sha256sum`, and `python3`. Flatpak
installs the required KDE 6.9 runtime, which is now end-of-life. The bundle is
pinned to the build verified on this machine.

To link only the script, application entry, and icon without downloading Chiaki:

```bash
bash ~/dotfiles/scripts/install_ps5_pro.sh --configure-only
```

Existing files at those destinations are backed up before linking. This package
also works with the repository's `INCLUDED_BINS` and `INCLUDED_CONFIGS` settings.
If `gkdots/config.py` already exists, add the `ps5-pro` entries there manually;
changes to `config.def.py` only apply when bootstrapping a new configuration.
The desktop session needs `~/.local/bin` on `PATH` for the application entry.

Search for **PS5 PRO** in the application launcher. Press **Ctrl+Q** in Chiaki
to disconnect and choose whether to put the console into Rest Mode.

```bash
ps5-pro --check
PS5_PRO_HOST=192.168.178.60 ps5-pro
```

The default console address is `192.168.178.60`. Change it in `bins/ps5-pro`,
or set `PS5_PRO_HOST` in the desktop session if the console's address changes.
The launcher follows the operating system's routing preferences. On this
machine Ethernet has metric 100 and Wi-Fi has metric 600.

Pairing keys and PSN tokens stay in the existing user configuration at
`~/.var/app/io.github.streetpea.Chiaki4deck/config/Chiaki/Chiaki.conf`.
The script reads the first registered console's wake key at runtime. On a new
machine, pair the console in Chiaki before testing wake-up. The PS5 must be in
Rest Mode with network access and network wake enabled.

The PlayStation logo path comes from
[Simple Icons](https://github.com/simple-icons/simple-icons/blob/develop/icons/playstation.svg).
The pinned bundle is available from the
[official weekly release](https://github.com/chiaki-ng/chiaki-ng/releases/tag/weekly-canary-release-a9a2805884cfa83865fdfcc09ca3ddfcd628aa42).

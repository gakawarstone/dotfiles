# eduroam on gklaptop

The laptop imports `modules/services/eduroam.nix` and installs the encrypted NetworkManager
profile from `secrets/eduroam.nmconnection.cfg`. The CA certificate is also
encrypted under `secrets/`. NixOS decrypts them at activation; the helper
decrypts the profile in memory when saving or deploying credentials.

## Save the login and password

Run this in a terminal:

```sh
cd ~/nix
python3 scripts/eduroam.py save
```

Enter the full eduroam identity, normally `name@hs-flensburg.de`, and the
password when prompted. The script writes them to the SOPS-encrypted profile,
then asks for sudo to install the CA certificate and reload the live
NetworkManager profile. The password is
not passed as a command-line argument or stored in shell history. If the sudo
step fails, the encrypted change remains saved; retry deployment with:

```sh
python3 scripts/eduroam.py deploy
```

The encrypted profile is tracked by Git. Commit it if the credentials should
survive a fresh checkout or NixOS rebuild. The decrypted profile is installed
with mode `0600` and contains the saved password. The CA certificate is public
and installed with mode `0644` in a traversable directory so NetworkManager
can read it for the user-owned profile.

## Connect and diagnose in range

```sh
cd ~/nix
python3 scripts/eduroam.py test
```

The test rescans Wi-Fi, checks for `eduroam`, brings up the saved profile,
and reports the device state, reason, IP address, and NetworkManager
connectivity result. It changes the active Wi-Fi connection when eduroam is in
range. If it fails, the script prints a `journalctl` command limited to the
attempt's start time. Use `--interface DEVICE` if auto-detection chooses the
wrong Wi-Fi device.

The profile requires TTLS/PAP, the Flensburg CA certificate, and the
`netauth.hs-flensburg.de` server name. `test` cannot check authentication until
an eduroam access point is in range.

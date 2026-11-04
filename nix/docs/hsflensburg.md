# HS Flensburg on gklaptop

The VPN setup is maintained in the Nix and dotfiles repositories.
`modules/system/base.nix` installs OpenConnect, its NetworkManager plugin,
and the MTU hook. `modules/desktop/hyprland.nix` provides the panel's runtime
commands. The separate `~/dotfiles` checkout contains the Quickshell panel,
VPN helper, and its regression tests.

On a fresh installation, restore the dotfiles checkout using
[the dotfiles guide](dotfiles.md), then apply this configuration:

```sh
cd ~/nix
sudo nixos-rebuild switch --flake .#gklaptop
```

Then connect from the HSFL panel to `vpn.hs-flensburg.de` using the
`HSFL-Studierende` group. The helper creates or repairs the NetworkManager
profile; credentials are entered interactively on each login.

The Quickshell VPN panel lives in the separate `~/dotfiles` checkout. Its
helper must recognize the NixOS plugin path,
`/run/current-system/sw/lib/NetworkManager/VPN/nm-openconnect-service.name`.
`modules/desktop/hyprland.nix` puts Nix-provided `nmcli`, OpenConnect, Python,
and Foot on Quickshell's command path. NixOS dependencies are installed by
rebuilding this configuration; the panel's pacman installer is only for Arch.
If the panel reports **VPN unavailable**, check `systemctl is-active
NetworkManager` and `nmcli general status`, then click **Retry**. Missing VPN
packages and an unavailable service are reported separately.

The VPN gateway negotiates MTU 1390 even when OpenConnect requests 1280.
On this network, GitLab resolves and answers ping but HTTPS stalls at the TLS
handshake with MTU 1390. Setting the tunnel MTU to 1280 restores HTTPS.
`modules/system/base.nix` installs a NetworkManager `vpn-pre-up` hook that
enforces MTU 1280 on this VPN's actual tunnel interface before activation.
It only handles the `HS Flensburg VPN` profile.

The rebuild installs the hook through NixOS's managed `/etc` configuration.
After applying it, reconnect the VPN to run the hook. The same configuration
applies on a fresh installation and after future rebuilds. Verify with
`ip link show tun0` and `curl -I https://gitlab.hs-flensburg.de`; GitLab should
redirect to `/users/sign_in`.

`home/gws/secrets.nix` installs the Git identities and GitLab HTTPS credential.
`home/gws/git.nix` configures the credential helper through Home Manager. The
laptop separately imports `modules/services/eduroam.nix` for Wi-Fi. The identities,
GitLab token, and eduroam profile
come from encrypted files in `secrets/` during NixOS activation. No interactive
GitLab setup step is needed.

The encrypted `secrets/git-default-identity.cfg` becomes `~/.gitconfig` and
includes the encrypted HS Flensburg identity for repositories whose remote
points at `gitlab.hs-flensburg.de`. For HTTPS access, the credential helper
reads the decrypted `secrets/gitlab-hs-flensburg.json` from `/run/secrets/`.
Only `gws` can read these files; their contents are never embedded in the Nix
store. Git commits still record the selected author name and email.

To rotate the GitLab token, edit the encrypted file and rebuild:

```sh
nix shell nixpkgs#sops -c sops secrets/gitlab-hs-flensburg.json
sudo nixos-rebuild switch --flake .#gklaptop
```

The JSON file contains `username` and `token` fields. For GitLab personal
access tokens, `username` is `oauth2`. See [eduroam](eduroam.md) for Wi-Fi
credential updates and connection checks.

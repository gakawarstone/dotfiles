# Secrets with sops-nix

Secrets live encrypted under `secrets/` and are decrypted at activation
into `/run/secrets/`. Never put plaintext secrets in `.nix` files — anything
in the Nix store is world-readable.

## Layout

- `~/.config/sops/age/keys.txt` — personal age key, used for editing. Never commit.
- `.sops.yaml` — maps pubkeys to files under `secrets/`.
- `secrets/wakatime.cfg` — encrypted WakaTime configuration.
- `home/gws/secrets.nix` — declares personal secrets and their destinations, including WakaTime and tgsend.
- `secrets/gitlab-hs-flensburg.json` — encrypted HS Flensburg GitLab credential.
- `secrets/git-default-identity.cfg` and `secrets/hsflensburg-identity.cfg` — encrypted Git identities.
- `home/gws/git.nix` — configures the GitLab credential helper.
- `secrets/ssh-oracle.cfg` — encrypted Oracle SSH connection details.
- `home/gws/ssh.nix` — includes the decrypted SSH configuration from `/run/secrets/ssh-oracle`.
- `modules/services/eduroam.nix` — installs the eduroam profile and CA certificate.
- `modules/system/secrets.nix` — imports the sops-nix NixOS module.

## Usage

Edit or add secrets (opens decrypted in $EDITOR, re-encrypts on save):

    nix shell nixpkgs#sops -c sops \
      --input-type binary --output-type binary secrets/wakatime.cfg

Reference a secret in a module:

    sops.secrets.wakatime = {
      sopsFile = ../../secrets/wakatime.cfg;
      format = "binary";
      path = "/home/gws/.wakatime.cfg";
      owner = "gws";
      group = "users";
      mode = "0600";
    };

Path for use in other config: `config.sops.secrets.wakatime.path`.

Apply and verify:

    sudo nixos-rebuild switch --flake .#gklaptop

The decrypted file is owned by `gws`, readable only by that user, and is not
copied into the Nix store.

Per-secret options: owner/group/mode, `restartUnits`, etc.

## Adding a new host

1. After installing the host:

       ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

2. Add the pubkey to `.sops.yaml` as a new anchor and include it in the
   `creation_rules` key group.
3. Re-encrypt any secret files the host needs (`sops updatekeys secrets/foo.yaml`).

A host can't decrypt secrets encrypted before its key was added.

## Gotchas

- Flakes only see git-tracked files: `git add` new secret files before rebuilding.
- New hosts must be added to `.sops.yaml` *before* they're given secrets.

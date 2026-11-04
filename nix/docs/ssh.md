# Personal SSH configuration

Oracle connection details are stored as an encrypted SSH configuration block in
`secrets/ssh-oracle.cfg`. The file uses the personal and laptop recipients from
`.sops.yaml`.

`home/gws/secrets.nix` decrypts it to `/run/secrets/ssh-oracle`, owned by `gws`
with mode `0600`. Home Manager includes that path in `~/.ssh/config` through
`home/gws/ssh.nix`. The connection details are read by SSH at runtime and are
not embedded in the Nix store.

Connect with the existing alias:

```sh
ssh oracle
```

Edit the encrypted connection details using the repository's tool shell:

```sh
nix develop --command sops --input-type binary --output-type binary secrets/ssh-oracle.cfg
make check
make switch CONFIGURATION=gklaptop
```

The SSH private key referenced by the encrypted configuration must be restored
separately. Changing the current files does not remove addresses from previous
Git commits.

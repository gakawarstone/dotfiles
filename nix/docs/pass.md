# Password store

The laptop imports `modules/services/pass.nix` through `home/gws/nixos.nix`.
It enables the GnuPG agent with terminal pinentry and SSH support, and installs
GnuPG, `pass` with the `pass-otp` extension, and the GitHub CLI.

Use `pass otp <entry>` to generate a one-time password for a stored OTP entry.

Restore your private GPG key from its separate backup, then restart the agent:

```sh
gpg --import private.asc
gpgconf --kill gpg-agent
export GPG_TTY=$(tty)
```

In Fish, set the terminal with `set -gx GPG_TTY (tty)` instead of the Bash
`export` command. Restore your password store separately before using `pass`.
Private keys and the password store are not included in this repository.

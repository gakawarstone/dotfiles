# Zen Browser

Run `make -C configs/zen install` from the repository root to link the custom
UI stylesheet and the preference that enables it into the active Zen profile.
Restart Zen after installing.

The installer supports native and Flatpak Zen profile locations. It refuses to
replace an existing `userChrome.css` or `user.js` file.

On the Arch PC, Home Manager manages the two links for the existing default
profile and keeps their editable sources in `~/dotfiles/configs/zen`. If the
default profile changes, inspect the new profile and update the profile name in
`nix/home/gws/arch-zen.nix` before applying Home Manager. Other profile data is
not managed.

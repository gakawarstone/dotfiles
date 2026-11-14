# Thunderbird Configuration

This directory contains configuration files for Thunderbird.

## Catppuccin Theme Installation

To install the Catppuccin theme for Thunderbird, follow these steps:

The included `mocha-mauve.xpi` is based on [Catppuccin for Thunderbird](https://github.com/catppuccin/thunderbird)
at revision `575ab278460137dba10c1a23d00af0bc583fe509`. Its broken icon files
were replaced with upstream images, the reference to the missing optional
stylesheet was removed, and its version was bumped to `1.0.1`. Its color
settings and add-on ID are unchanged.

On NixOS, Home Manager installs the theme through Thunderbird's extension policy
when the managed Thunderbird starts. It does not manage mail accounts or
profiles. The theme can still be disabled in Thunderbird. On Arch, the module
that installs Thunderbird with Nix is not enabled. A separate way to apply the
theme policy to the Arch-installed Thunderbird is still needed.

### Manual installation
1. Open **Thunderbird**.
2. Go to **Settings** (gear icon) or **Add-ons and Themes** in the menu.
3. Select the **Themes** section on the left sidebar.
4. Click the **gear icon** at the top-right of the "Manage Your Themes" section.
5. Select **Install Add-on From File...**.
6. Select `~/.config/thunderbird/mocha-mauve.xpi`.
7. Click **Add** to confirm.

### Enable the theme
* Once installed, click **Enable** next to the Catppuccin flavor in the list of themes.

# Android Studio Configuration

To fix pixelation in Hyprland (due to XWayland scaling), native Wayland support has been enabled.

## Changes Made
A user-specific VM options file was created at:
`~/.config/Google/AndroidStudio2025.3.2/studio64.vmoptions`

The following line was added to enable the experimental Wayland toolkit:
```
-Dawt.toolkit.name=WLToolkit
```

## How to Verify
Run `hyprctl clients` while Android Studio is open. The output for `jetbrains-studio` should show:
```
xwayland: 0
```
instead of `xwayland: 1`.

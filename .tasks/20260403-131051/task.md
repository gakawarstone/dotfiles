# implement hyprland theme toggle

- STATUS: CLOSED
- PRIORITY: 1

## Plan

### 1. Research & Theme Definition
- [x] Create `latte.conf` for Hyprland with official Catppuccin Latte hex codes.
- [x] Create `latte.ini` for Foot.
- [x] Create `Mocha.qml` and `Latte.qml` for Quickshell by extracting hardcoded colors.

### 2. Implementation Strategy: Symlink Switching
- [x] **Hyprland**:
    - Update `hyprland.conf` to `source = ./theme.conf`.
    - Create a symlink `configs/hyprland/.config/hypr/theme.conf` pointing to `mocha.conf`.
- [x] **Foot**:
    - Update `foot.j2.ini` to `include = ./theme.ini`.
    - Create a symlink `configs/foot/.config/foot/theme.ini` pointing to `mocha.ini`.
- [x] **Quickshell**:
    - Update all components to use a global `Theme` object.
    - Create a symlink `configs/quickshell/.config/quickshell/Theme.qml` pointing to `Mocha.qml`.

### 3. Toggle Script (`bins/toggle_theme`)
- [x] Create `bins/toggle_theme` script to:
    - Detect current theme.
    - Swap symlinks.
    - Reload Hyprland, Waybar, Kitty, and Alacritty.
    - (Optional) Toggle wallpaper.

### 4. Integration & Keybinding
- [x] Add keybinding to `hyprland.conf`: `bind = $mainMod SHIFT, T, exec, toggle_theme`.

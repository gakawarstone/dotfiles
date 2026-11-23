# PS5 PRO with frame generation

```bash
bash ~/dotfiles/scripts/install_ps5_pro_framegen.sh
```

The installer builds the pinned [Chiaki-ng PR #904](https://github.com/chiaki-ng/chiaki-ng/pull/904)
revision and installs **PS5 PRO (Frame Generation)** in the application menu.
The build uses the system C++ toolchain, CMake, Ninja, pkg-config and Chiaki-ng's
native dependencies. It was tested on Arch Linux. The desktop session needs
`~/.local/bin` on `PATH`.

The launcher keeps its settings under `~/.config/chiaki-ng-framegen` by default.
On first install it imports local pairing from an existing Chiaki Flatpak
profile, if available. PSN sign-in uses a separate session. Existing Frame
Generation profiles are kept on reinstall.

Optical Flow is enabled for newly created installation profiles. This revision
requests a 30 FPS Remote Play stream and uses it to generate intermediate frames.

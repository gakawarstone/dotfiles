# Energy Meter on the laptop

The Quickshell window and launcher entry live in `~/dotfiles`. This NixOS
configuration installs their `omaenergy` backend, starts its user sampler, and
grants the `wheel` group read access to package-level RAPL energy counters.
Do not run `~/dotfiles/packages/energy-meter/install.sh` on NixOS: that
installer expects Arch paths and would install a competing user service.

Apply the laptop configuration with `make switch CONFIGURATION=gklaptop`, then
check the sampler:

```sh
systemctl --user status omarchy-energy.service
omaenergy status
omaenergy now
```

Open Win+Space, then choose Energy Meter. The gear sets the electricity price.
Collection starts when the sampler first runs; earlier energy usage cannot be
recovered. If the service cannot read RAPL immediately after a switch, reboot
so the udev rule applies to the device and the `wheel` group membership is
present in the new login session.

The local package pins the same upstream commit as the dotfiles installer and
includes an NVIDIA backend with NVML lifecycle fixes. Failed GPU probes release
NVML immediately; a usable sensor keeps it initialized until process exit. The
NVIDIA library is discovered from the NixOS graphics driver path at runtime.
Mock-based package tests cover probing, retries and cleanup without a GPU;
NVIDIA hardware has not been verified on this laptop.

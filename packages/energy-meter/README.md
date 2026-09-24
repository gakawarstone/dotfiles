# Energy Meter

A Quickshell window for live power, a recent power graph, and energy and cost by day, week, month, or year. Open it from Win+Space. The gear opens the electricity price setting.

## Install

From the repository root:

```sh
./packages/energy-meter/install.sh
```

The installer fetches the pinned [Energy Meter backend](https://github.com/kevzakaria/omarchy-energy-meter), applies `patches/nvidia.patch`, and installs its user service. The patch reads NVIDIA power through NVML and retries GPU detection when the driver loads after the service. The backend needs one `sudo` step to give the `wheel` group read access to the CPU energy counter. It does not add a bar widget.

Check the sampler with `omaenergy now`, then set your actual electricity price with the gear. The default tariff is a placeholder. Collection starts when the service runs; older GPU readings cannot be recovered.

## Files

- `qml/EnergyMeter.qml`: the window. `configs/quickshell/.config/quickshell/EnergyMeter.qml` links here so Quickshell can load it.
- `patches/nvidia.patch`: NVIDIA sensor support for the pinned backend.
- `install.sh`: backend installer.

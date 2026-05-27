# VA-API Hardware Video Acceleration

## Problem
Without VA-API drivers, video playback is decoded entirely in software on the CPU. On this laptop (i5-1135G7 with Intel Iris Xe), this causes:
- High CPU usage during video playback
- Choppy/stuttering video
- System slowdown when watching videos alongside other tasks

## Solution
Install Intel VA-API drivers to enable hardware-accelerated video decoding via Intel Quick Sync Video.

### Install
```bash
sudo pacman -S libva-intel-driver intel-media-driver libva-utils
```

### Verify
```bash
vainfo
```
You should see supported codec profiles like `VAProfileH264Main`, `VAProfileHEVCMain`, `VAProfileVP9Profile0`, etc.

### Packages
- **libva-intel-driver** — Legacy VA-API driver for older Intel GPUs (pre-Gen11)
- **intel-media-driver** — Modern VA-API driver for Gen11+ (Tiger Lake / Iris Xe) — this is the one that matters for this laptop
- **libva-utils** — Provides the `vainfo` command for verification

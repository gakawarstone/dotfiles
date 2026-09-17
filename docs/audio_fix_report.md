# Audio troubleshooting report: ESSX8336 on Huawei MateBook

This report records the steps that resolved silent audio on a system using the ESSX8336 audio codec.

## 1. Initial findings

The file `audio.mp3` was actually an AAC stream in an MP4/DASH container. It was renamed to `audio.m4a` and converted to `test.wav` for player compatibility.

## 2. System analysis

- The system uses the `sof-essx8336` Sound Open Firmware driver.
- PipeWire was sending audio to the Speakers sink, ID `84`, but no sound was heard.
- System volume was set to 100%, and outputs were unmuted.

## 3. Hardware-level diagnosis

The ESSX8336 codec has internal mixer routing separate from the Speaker switch. On this system, the Speaker switch was on, but the DAC-to-mixer paths were disabled.

Inspection with `amixer` showed these switches were off:

- `Left Headphone Mixer Left DAC`
- `Right Headphone Mixer Right DAC`

On this hardware, the Headphone Mixer paths also carry audio to the internal speakers.

## 4. The fix

Install ALSA utilities if they are not present:

```sh
sudo pacman -S alsa-utils
```

Enable the internal DAC-to-mixer paths:

```sh
amixer -c 0 sset "Left Headphone Mixer Left DAC" on
amixer -c 0 sset "Right Headphone Mixer Right DAC" on
```

These commands target ALSA card `0`, as used on the tested system. Card numbers and PipeWire sink IDs may differ on other systems.

## 5. Verification

After enabling these switches, speaker playback via `mpv` worked on the tested system.

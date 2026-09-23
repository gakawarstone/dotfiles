#!/usr/bin/env python3
"""Stream five frequency levels from the default audio output monitor."""

import math
import signal
import struct
import subprocess
import sys


RATE = 16000
SIZE = 1024
HOP = SIZE // 2
BANDS = ((60, 180), (180, 500), (500, 1400), (1400, 3500), (3500, 7000))
GAINS = (1.0, 1.3, 1.8, 2.6, 3.5)
WINDOW = tuple(0.5 - 0.5 * math.cos(2 * math.pi * i / (SIZE - 1)) for i in range(SIZE))


def fft(samples):
    values = [complex(sample * WINDOW[i] / 32768) for i, sample in enumerate(samples)]
    j = 0
    for i in range(1, SIZE):
        bit = SIZE >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            values[i], values[j] = values[j], values[i]

    width = 2
    while width <= SIZE:
        half = width // 2
        step = complex(math.cos(-2 * math.pi / width), math.sin(-2 * math.pi / width))
        for start in range(0, SIZE, width):
            rotation = 1 + 0j
            for offset in range(half):
                a = values[start + offset]
                b = rotation * values[start + offset + half]
                values[start + offset] = a + b
                values[start + offset + half] = a - b
                rotation *= step
        width *= 2
    return values


def band_levels(samples):
    if math.sqrt(sum(sample * sample for sample in samples) / SIZE) < 50:
        return [0.0] * 5

    spectrum = fft(samples)
    levels = []
    for (low, high), gain in zip(BANDS, GAINS):
        first = math.ceil(low * SIZE / RATE)
        last = math.ceil(high * SIZE / RATE)
        power = sum(abs(spectrum[i]) ** 2 for i in range(first, last)) / (last - first)
        levels.append(math.sqrt(power) * 4 / SIZE * gain)
    return levels


def main():
    capture = subprocess.Popen(
        ["parec", "--device=@DEFAULT_MONITOR@", "--format=s16le", "--channels=1",
         f"--rate={RATE}", "--latency-msec=50", "--raw"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    signal.signal(signal.SIGTERM, lambda _signal, _frame: sys.exit(0))
    smoothed = [0.0] * 5
    peak = 0.03
    try:
        chunk = capture.stdout.read(SIZE * 2)
        if len(chunk) != SIZE * 2:
            return
        samples = struct.unpack(f"<{SIZE}h", chunk)

        while True:
            levels = band_levels(samples)
            peak = max(0.03, peak * 0.985, *levels)
            for i, level in enumerate(levels):
                target = min(1.0, math.sqrt(level / peak))
                rate = 0.4 if target > smoothed[i] else 0.14
                smoothed[i] += (target - smoothed[i]) * rate
            print(",".join(f"{level:.3f}" for level in smoothed), flush=True)

            chunk = capture.stdout.read(HOP * 2)
            if len(chunk) != HOP * 2:
                break
            samples = samples[HOP:] + struct.unpack(f"<{HOP}h", chunk)
    finally:
        capture.terminate()
        capture.wait()


if __name__ == "__main__":
    main()

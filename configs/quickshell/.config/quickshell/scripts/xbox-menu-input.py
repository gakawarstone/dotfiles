"""Read the paired Xbox pad through SDL without grabbing the device."""

import ctypes as c
import os
from pathlib import Path
import sys
import time


def controller_index(sdl, address):
    for index in range(sdl.SDL_NumJoysticks()):
        path = sdl.SDL_GameControllerPathForIndex(index)
        if not path:
            continue
        event = Path(os.fsdecode(path)).name
        try:
            unique_id = (Path("/sys/class/input") / event / "device/uniq").read_text()
        except OSError:
            continue
        if unique_id.strip().lower() == address.lower():
            return index
    return None


def send_actions(sdl, pad):
    buttons = {"a": 0, "b": 1, "up": 11, "down": 12}
    left_y = 1
    held = set()
    repeat_at = 0
    ready = False
    while sdl.SDL_GameControllerGetAttached(pad):
        sdl.SDL_GameControllerUpdate()
        pressed = {
            action for action, button in buttons.items()
            if sdl.SDL_GameControllerGetButton(pad, button)
        }
        axis = sdl.SDL_GameControllerGetAxis(pad, left_y)
        if abs(axis) > 16000:
            pressed.add("up" if axis < 0 else "down")
        # Require a neutral pad once, so a held button cannot launch a game on open.
        ready = ready or not pressed
        if ready:
            if "b" in pressed - held:
                print("close", flush=True)
                return
            if "a" in pressed - held:
                print("launch", flush=True)
            direction = next((key for key in ("up", "down") if key in pressed), None)
            now = time.monotonic()
            if direction and (direction not in held or now >= repeat_at):
                print(direction, flush=True)
                repeat_at = now + (0.38 if direction not in held else 0.13)
        held = pressed
        time.sleep(0.016)


def main(address):
    # Use Linux input paths so SDL controllers can be matched to the BlueZ address.
    os.environ["SDL_JOYSTICK_HIDAPI"] = "0"
    os.environ["SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS"] = "1"
    sdl = c.CDLL("libSDL2-2.0.so.0")
    sdl.SDL_GetError.restype = c.c_char_p
    sdl.SDL_GameControllerPathForIndex.restype = c.c_char_p
    sdl.SDL_GameControllerOpen.restype = c.c_void_p
    sdl.SDL_GameControllerGetAttached.argtypes = [c.c_void_p]
    sdl.SDL_GameControllerGetButton.argtypes = [c.c_void_p, c.c_int]
    sdl.SDL_GameControllerGetButton.restype = c.c_uint8
    sdl.SDL_GameControllerGetAxis.argtypes = [c.c_void_p, c.c_int]
    sdl.SDL_GameControllerGetAxis.restype = c.c_int16
    sdl.SDL_GameControllerClose.argtypes = [c.c_void_p]
    if sdl.SDL_Init(0x2000) != 0:  # SDL_INIT_GAMECONTROLLER
        raise RuntimeError(os.fsdecode(sdl.SDL_GetError()))
    try:
        # BlueZ may report a connection before the kernel creates the input node.
        while True:
            sdl.SDL_GameControllerUpdate()
            index = controller_index(sdl, address)
            if index is not None and (pad := sdl.SDL_GameControllerOpen(index)):
                try:
                    send_actions(sdl, pad)
                finally:
                    sdl.SDL_GameControllerClose(pad)
                return
            time.sleep(0.25)
    finally:
        sdl.SDL_Quit()


if __name__ == "__main__":
    main(sys.argv[1])

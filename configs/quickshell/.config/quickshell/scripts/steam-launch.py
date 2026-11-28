"""Launch a Steam game and hand off to its Hyprland window on the menu's monitor."""

from contextlib import contextmanager
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time


WAIT_SECONDS = 300
POLL_SECONDS = 0.3
STEAM_CLIENT = {"steam", "steam.exe", "steamwebhelper", "com.valvesoftware.steam"}


def hyprctl(*args):
    return subprocess.run(["hyprctl", *args], capture_output=True, text=True, timeout=2)


def clients():
    result = hyprctl("-j", "clients")
    result.check_returncode()
    return json.loads(result.stdout)


def game_window(client, app_id):
    title = client["title"].strip().casefold()
    if (not client["mapped"] or client["hidden"] or not title
            or not all(dimension > 0 for dimension in client["size"])):
        return False
    classes = {client["class"].lower(), client["initialClass"].lower()}
    if classes & STEAM_CLIENT:
        return False
    # Proton gives the Rockstar launcher the same Steam class as RDR2.
    if title.startswith("rockstar games"):
        return False
    steam_classes = {name for name in classes if re.fullmatch(r"steam_app_\d+", name)}
    if steam_classes:
        return steam_classes == {f"steam_app_{app_id}"}
    # Native and Wine Wayland windows may use the game's executable as their class.
    try:
        environment = (Path("/proc") / str(client["pid"]) / "environ").read_bytes().split(b"\0")
    except OSError:
        return False
    return any(f"{key}={app_id}".encode() in environment for key in ("SteamGameId", "SteamAppId"))


@contextmanager
def keep_steam_behind_poster(app_id, monitor):
    # Scope the focus rule to menu launches. The compositor timer also clears it
    # if the menu or this helper disappears without running the cleanup.
    owner = os.getpid()
    classes = "|".join(re.escape(name) for name in sorted(STEAM_CLIENT | {f"steam_app_{app_id}"}))
    cleanup = f"""
        local guard = _G.quickshellSteamLaunch
        if guard and guard.owner == {owner} then
            guard.rule:set_enabled(false)
            _G.quickshellSteamLaunch = nil
        end
    """
    try:
        result = hyprctl("eval", f"""
            local previous = _G.quickshellSteamLaunch
            if previous then previous.rule:set_enabled(false) end
            local rule = hl.window_rule({{
                name = "quickshell-steam-launch",
                match = {{ class = {json.dumps(f"(?i)^({classes})$")} }},
                monitor = {json.dumps(monitor + " silent")},
                no_initial_focus = true,
                focus_on_activate = false,
            }})
            _G.quickshellSteamLaunch = {{ owner = {owner}, rule = rule }}
            hl.timer(function() {cleanup} end, {{ timeout = {WAIT_SECONDS * 1000 + 5000}, type = "oneshot" }})
        """)
        if result.returncode != 0 or result.stdout.strip() != "ok":
            raise RuntimeError(result.stdout.strip() or result.stderr.strip())
        yield
    finally:
        hyprctl("eval", cleanup)


def focus_game(client, monitor):
    # Recheck the address and PID together in Hyprland before moving or focusing.
    result = hyprctl("eval", f"""
        local window = hl.get_window({json.dumps("address:" + client["address"])})
        local monitor = hl.get_monitor({json.dumps(monitor)})
        assert(window and window.mapped and not window.hidden and window.accepts_input
            and window.pid == {int(client["pid"])}, "game window is no longer ready")
        assert(monitor, "game monitor is unavailable")
        if window.monitor ~= monitor then
            hl.dispatch(hl.dsp.window.move({{ window = window, monitor = monitor, follow = false }}))
        end
        assert(window.monitor == monitor, "game window did not move to the target monitor")
        hl.dispatch(hl.dsp.focus({{ window = window }}))
        assert(hl.get_active_window() == window, "game window did not receive focus")
    """)
    return result.returncode == 0 and result.stdout.strip() == "ok"


def launch(app_id, monitor, command):
    existing = clients()
    if any(game_window(client, app_id) and focus_game(client, monitor) for client in existing):
        return 0

    with keep_steam_behind_poster(app_id, monitor):
        return wait_for_game(app_id, monitor, command)


def wait_for_game(app_id, monitor, command):
    # Steam can become the long-lived client after a cold start. Let it survive
    # cancellation and keep polling after a successful URI dispatch.
    steam = subprocess.Popen(command, start_new_session=True,
                             stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    deadline = time.monotonic() + WAIT_SECONDS
    previous = set()
    while time.monotonic() < deadline:
        if steam.poll() not in (None, 0):
            return 1
        candidates = set()
        for client in clients():
            if not game_window(client, app_id):
                continue
            key = client["address"], client["pid"]
            if key in previous and focus_game(client, monitor):
                return 0
            candidates.add(key)
        previous = candidates
        time.sleep(POLL_SECONDS)
    return 2


if __name__ == "__main__":
    # Quickshell sends SIGTERM when the user goes back.
    def stop_wait(_signum, _frame):
        sys.exit(1)

    signal.signal(signal.SIGTERM, stop_wait)
    app_id, monitor, *command = sys.argv[1:]
    try:
        sys.exit(launch(app_id, monitor, command))
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)

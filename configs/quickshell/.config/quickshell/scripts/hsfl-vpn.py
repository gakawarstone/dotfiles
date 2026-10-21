#!/usr/bin/env python3
"""HS Flensburg AnyConnect login with a NetworkManager-managed tunnel."""

import argparse
import fcntl
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys

PROFILE = "HS Flensburg VPN"
GATEWAY = "https://vpn.hs-flensburg.de"
GROUP = "HSFL-Studierende"
MTU = 1280
SERVICE = "org.freedesktop.NetworkManager.openconnect"
PLUGIN = Path("/usr/lib/NetworkManager/VPN/nm-openconnect-service.name")


def nmcli(*args):
    return subprocess.check_output(["nmcli", *args], text=True, timeout=15).strip()


def profile_uuid():
    # Use UUIDs for every operation; never activate an unrelated namesake.
    for line in nmcli("-t", "-f", "UUID,TYPE", "connection", "show").splitlines():
        uuid, kind = line.split(":", 1)
        if kind != "vpn":
            continue
        name = nmcli("-g", "connection.id", "connection", "show", "uuid", uuid)
        if name != PROFILE:
            continue
        service = nmcli("-g", "vpn.service-type", "connection", "show", "uuid", uuid)
        if service != SERVICE:
            raise RuntimeError(f"{PROFILE} already exists with a different VPN type.")
        return uuid
    return None


def connection_state(uuid):
    if not uuid:
        return "disconnected"
    active = nmcli("-t", "-f", "UUID,STATE", "connection", "show", "--active")
    for line in active.splitlines():
        active_uuid, state = line.split(":", 1)
        if active_uuid == uuid:
            return "connected" if state == "activated" else "connecting"
    return "disconnected"


def status():
    ready = bool(shutil.which("openconnect")) and PLUGIN.is_file()
    state = connection_state(profile_uuid())
    return {"ready": ready, "state": state}


def ensure_profile():
    uuid = profile_uuid()
    if uuid:
        # OpenConnect cannot activate private profiles on NetworkManager 1.58.
        # Also repair profiles created by earlier versions of this helper.
        permissions = nmcli("-g", "connection.permissions", "connection", "show", "uuid", uuid)
        if permissions:
            nmcli("connection", "modify", "uuid", uuid, "connection.permissions", "")
        # Larger DTLS packets are dropped on this gateway/path, stalling HTTPS.
        nmcli("connection", "modify", "uuid", uuid, "+vpn.data", f"mtu={MTU}")
        return uuid
    nmcli(
        "connection", "add", "type", "vpn", "vpn-type", "openconnect",
        "con-name", PROFILE, "ifname", "*", "connection.autoconnect", "no",
        "connection.permissions", "",
        "vpn.data", f"gateway={GATEWAY},protocol=anyconnect,mtu={MTU},cookie-flags=2,"
        "gateway-flags=2,gwcert-flags=2,resolve-flags=2",
    )
    uuid = profile_uuid()
    if not uuid:
        raise RuntimeError("NetworkManager did not create the VPN profile.")
    return uuid


def parse_auth(output):
    # Parse assignments as data. Never eval output from a network-facing tool.
    values = {}
    for line in output.splitlines():
        key, separator, value = line.partition("=")
        if separator and key in {"COOKIE", "CONNECT_URL", "FINGERPRINT", "RESOLVE"}:
            try:
                tokens = shlex.split(value)
            except ValueError:
                raise RuntimeError("Invalid OpenConnect authentication response.") from None
            if len(tokens) != 1 or "\n" in tokens[0] or "\r" in tokens[0]:
                raise RuntimeError("Invalid OpenConnect authentication response.")
            values[key] = tokens[0]
    if any(not values.get(key) for key in ("COOKIE", "CONNECT_URL", "FINGERPRINT")):
        raise RuntimeError("OpenConnect did not return a complete login session.")
    return values


def connect():
    if not shutil.which("openconnect") or not PLUGIN.is_file():
        raise RuntimeError("Install VPN support from the panel first.")
    uuid = ensure_profile()
    if connection_state(uuid) != "disconnected":
        print("HS Flensburg VPN is already connected or connecting.")
        return
    print(f"{PROFILE}\nServer: {GATEWAY}\nGroup: {GROUP}", flush=True)
    print("Use your university username, e.g. abcd1234, not your email.", flush=True)
    auth = subprocess.run(
        ["openconnect", "--authenticate", "--protocol=anyconnect",
         f"--authgroup={GROUP}", GATEWAY],
        stdout=subprocess.PIPE, text=True, check=True,
    )
    values = parse_auth(auth.stdout)
    secrets = "".join(
        f"vpn.secrets.{name}:{values[key]}\n"
        for name, key in (("cookie", "COOKIE"), ("gateway", "CONNECT_URL"),
                          ("gwcert", "FINGERPRINT"), ("resolve", "RESOLVE"))
        if values.get(key)
    )
    # A pipe keeps the session cookie out of argv, files and shell history.
    subprocess.run(
        ["nmcli", "--wait", "60", "connection", "up", "uuid", uuid,
         "passwd-file", "/dev/stdin"],
        input=secrets, text=True, check=True, timeout=70,
    )


def disconnect():
    uuid = profile_uuid()
    if uuid and connection_state(uuid) != "disconnected":
        nmcli("connection", "down", "uuid", uuid)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("status", "connect", "disconnect", "install"))
    args = parser.parse_args()
    try:
        if args.action == "status":
            print(json.dumps(status()))
            return 0
        # Prevent duplicate logins from multiple screens or panel instances.
        runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
        with open(Path(runtime) / "quickshell-hsfl-vpn.lock", "a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise RuntimeError("Another HS Flensburg VPN action is in progress.") from None
            if args.action == "connect":
                connect()
            elif args.action == "disconnect":
                disconnect()
            else:
                subprocess.run(
                    ["sudo", "pacman", "-S", "--needed", "openconnect",
                     "networkmanager-vpn-plugin-openconnect"], check=True,
                )
                print("VPN support installed. Click Connect in the panel.")
        return 0
    except (RuntimeError, OSError, ValueError, subprocess.SubprocessError) as error:
        # CalledProcessError from authentication must not expose captured cookies.
        message = "VPN command failed. See the output above." if isinstance(
            error, subprocess.SubprocessError
        ) else str(error)
        print(message, file=sys.stderr)
        if sys.stdin.isatty() and args.action in {"connect", "install"}:
            try:
                input("Press Enter to close.")
            except EOFError:
                pass
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())

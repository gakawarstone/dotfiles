#!/usr/bin/env python3
"""Update and test the eduroam profile managed by ~/nix."""

import argparse
import getpass
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime


ROOT = Path(__file__).resolve().parent.parent
SECRET = ROOT / "secrets/eduroam.nmconnection.cfg"
CERT_SECRET = ROOT / "secrets/eduroam-ca-cert.cfg"
UUID = "4010325c-14b4-47eb-af63-9518522eaa62"
PROFILE = f"/etc/NetworkManager/system-connections/eduroam-{UUID}.nmconnection"
CERT_DIR = f"/etc/NetworkManager/eduroam-material/{UUID}"
CERT = f"{CERT_DIR}/ca-cert"


class SetupError(Exception):
    pass


def sops_command():
    if shutil.which("sops"):
        return ["sops"]
    if not shutil.which("nix"):
        raise SetupError("Install sops or nix before saving credentials.")
    return ["nix", "shell", "--inputs-from", str(ROOT), "nixpkgs#sops", "-c", "sops"]


def run_sops(*args, data=None):
    result = subprocess.run(
        [*sops_command(), *args], cwd=ROOT, input=data, capture_output=True
    )
    if result.returncode:
        raise SetupError(result.stderr.decode(errors="replace").strip() or "sops failed")
    return result.stdout


def decrypted_profile():
    return run_sops(
        "decrypt", "--input-type", "json", "--output-type", "binary", str(SECRET)
    )


def decrypted_certificate():
    return run_sops(
        "decrypt", "--input-type", "json", "--output-type", "binary", str(CERT_SECRET)
    )


def keyfile_escape(value):
    if not value or "\0" in value or "\r" in value or "\n" in value:
        raise SetupError("Identity and password must be nonempty single-line values.")
    # GLib key files use backslash escapes. Keep leading spaces unambiguous.
    if value.startswith(" ") or value.endswith(" "):
        raise SetupError("Identity and password cannot start or end with a space.")
    return value.replace("\\", "\\\\").replace("\t", "\\t")


def update_profile(profile, identity, password):
    text = profile.decode("utf-8")
    if f"uuid={UUID}" not in text or "\n[802-1x]\n" not in "\n" + text:
        raise SetupError("The encrypted profile is not the expected eduroam connection.")
    match = re.search(r"(?ms)^\[802-1x\]\n(.*?)(?=^\[|\Z)", text)
    if not match:
        raise SetupError("The encrypted profile has no [802-1x] section.")
    section = match.group(1)
    for key, value in (
        ("identity", keyfile_escape(identity)),
        ("password", keyfile_escape(password)),
        ("password-flags", "0"),
    ):
        pattern = rf"(?m)^{re.escape(key)}=.*$"
        section, count = re.subn(pattern, lambda _: f"{key}={value}", section)
        if count > 1:
            raise SetupError(f"The profile contains duplicate {key} entries.")
        if not count:
            section = section.rstrip("\n") + f"\n{key}={value}\n"
    return (text[: match.start(1)] + section + text[match.end(1) :]).encode()


def write_encrypted(data):
    encrypted = run_sops(
        "encrypt", "--input-type", "binary", "--output-type", "json",
        "--filename-override", str(SECRET.relative_to(ROOT)), "/dev/stdin", data=data,
    )
    # Check the ciphertext before replacing the tracked secret.
    check = run_sops(
        "decrypt", "--input-type", "json", "--output-type", "binary",
        "/dev/stdin", data=encrypted,
    )
    if check != data:
        raise SetupError("Encrypted profile failed its round-trip check.")
    fd, temp_name = tempfile.mkstemp(prefix=".eduroam.", dir=SECRET.parent)
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(encrypted)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temp_name, SECRET)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)


def deploy(data):
    certificate = decrypted_certificate()
    if subprocess.run(["sudo", "-v"]).returncode:
        raise SetupError("sudo authentication failed; encrypted credentials were saved in ~/nix.")
    cert_command = (
        "set -eu; umask 077; "
        f"install -d -m 0755 {CERT_DIR}; "
        f"temporary=$(mktemp {CERT_DIR}/.ca-cert.XXXXXXXX); "
        "trap 'rm -f \"$temporary\"' EXIT; "
        "cat > \"$temporary\"; chmod 0644 \"$temporary\"; "
        f"mv -f \"$temporary\" {CERT}"
    )
    if subprocess.run(["sudo", "-n", "sh", "-c", cert_command], input=certificate).returncode:
        raise SetupError("Could not deploy the CA certificate. Encrypted credentials remain saved in ~/nix.")
    # The plaintext travels only through stdin and a root-owned 0600 temporary file.
    command = (
        "set -eu; umask 077; "
        "temporary=$(mktemp /etc/NetworkManager/system-connections/.eduroam.XXXXXXXX); "
        "trap 'rm -f \"$temporary\"' EXIT; "
        "cat > \"$temporary\"; chmod 0600 \"$temporary\"; "
        f"mv -f \"$temporary\" {PROFILE}; "
        f"nmcli connection load {PROFILE}"
    )
    result = subprocess.run(["sudo", "-n", "sh", "-c", command], input=data)
    if result.returncode:
        raise SetupError("Could not deploy the profile. Encrypted credentials remain saved in ~/nix.")
    print("Encrypted credentials saved and NetworkManager profile reloaded.")


def save_credentials():
    try:
        tty = open("/dev/tty", "r+")
    except OSError:
        # Some terminal integrations supply a PTY on stdin without assigning
        # it as the process's controlling terminal.
        if not sys.stdin.isatty():
            raise SetupError("No interactive terminal input is available.")
        tty = sys.stdin
    if tty is sys.stdin:
        import termios

        try:
            termios.tcgetattr(tty.fileno())
        except termios.error as error:
            raise SetupError("Cannot hide password input in this terminal.") from error
    prompt_out = sys.stderr if tty is sys.stdin else tty
    try:
        prompt_out.write("eduroam identity (usually name@hs-flensburg.de): ")
        prompt_out.flush()
        identity = tty.readline().rstrip("\n")
        password = getpass.getpass("Password: ", stream=prompt_out)
        confirmation = getpass.getpass("Confirm password: ", stream=prompt_out)
    finally:
        if tty is not sys.stdin:
            tty.close()
    if password != confirmation:
        raise SetupError("Passwords did not match; nothing was changed.")
    data = update_profile(decrypted_profile(), identity, password)
    write_encrypted(data)
    print("Encrypted credentials saved in ~/nix.")
    deploy(data)


def nmcli(*args):
    return subprocess.run(["nmcli", *args], capture_output=True, text=True)


def wifi_interface(requested):
    if requested:
        return requested
    result = nmcli("-t", "-f", "DEVICE,TYPE", "device", "status")
    if result.returncode:
        raise SetupError(result.stderr.strip() or "Could not list network devices.")
    for line in result.stdout.splitlines():
        device, _, kind = line.rpartition(":")
        if kind == "wifi":
            return device
    raise SetupError("No Wi-Fi device found. Pass --interface if needed.")


def show_status(interface):
    result = nmcli(
        "-g", "GENERAL.STATE,GENERAL.REASON,GENERAL.CONNECTION,IP4.ADDRESS",
        "device", "show", interface,
    )
    if result.returncode == 0:
        print("Device state, reason, connection, IPv4 address:")
        print(result.stdout.strip())


def test_connection(interface_arg):
    interface = wifi_interface(interface_arg)
    scan = nmcli("device", "wifi", "rescan", "ifname", interface)
    if scan.returncode:
        print(f"Wi-Fi rescan: {scan.stderr.strip()}", file=sys.stderr)
    else:
        time.sleep(3)
    visible = nmcli("-t", "-f", "SSID", "device", "wifi", "list", "ifname", interface)
    if visible.returncode:
        raise SetupError(visible.stderr.strip() or "Could not list Wi-Fi networks.")
    if "eduroam" not in visible.stdout.splitlines():
        print("eduroam is not in range yet. Run this test again when it appears.")
        return 2

    start = datetime.now().astimezone().isoformat(timespec="seconds")
    print(f"Connecting to eduroam on {interface}...")
    attempt = nmcli("--wait", "60", "connection", "up", "uuid", UUID, "ifname", interface)
    if attempt.returncode:
        print(attempt.stderr.strip() or attempt.stdout.strip(), file=sys.stderr)
        show_status(interface)
        print(f"For NetworkManager details, run: sudo journalctl -u NetworkManager --since '{start}' --no-pager")
        return 1
    show_status(interface)
    connectivity = nmcli("networking", "connectivity", "check")
    if connectivity.returncode == 0:
        print(f"Connectivity: {connectivity.stdout.strip()}")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("save", help="prompt for credentials, encrypt them in ~/nix, and deploy")
    commands.add_parser("deploy", help="deploy the encrypted profile already in ~/nix")
    test = commands.add_parser("test", help="connect and report the result when eduroam is in range")
    test.add_argument("--interface", help="Wi-Fi interface (auto-detected by default)")
    args = parser.parse_args()
    try:
        if args.command == "save":
            save_credentials()
        elif args.command == "deploy":
            deploy(decrypted_profile())
        else:
            return test_connection(args.interface)
    except (SetupError, OSError, UnicodeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

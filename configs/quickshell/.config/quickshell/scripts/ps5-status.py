"""Read PS5 power state over the local network."""

import os
import socket


def poll_status(host):
    # An ephemeral port leaves Chiaki's wake port free.
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.settimeout(1)
            probe.connect((host, 9302))
            probe.send(b"SRCH * HTTP/1.1\ndevice-discovery-protocol-version:00030010\n\0")
            reply = probe.recv(4096).split(maxsplit=2)
    except OSError:
        return "unreachable"

    if len(reply) >= 2 and reply[0] == b"HTTP/1.1":
        return {b"200": "ready", b"620": "standby"}.get(reply[1], "unreachable")
    return "unreachable"


if __name__ == "__main__":
    print(poll_status(os.environ.get("PS5_PRO_HOST", "192.168.178.60")))

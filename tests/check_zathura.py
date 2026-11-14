#!/usr/bin/env python3
"""Open a generated PDF with the system zathura in an isolated X server.

Run with: xvfb-run -a python3 -B tests/check_zathura.py
"""

import os
from pathlib import Path
import subprocess
import tempfile
import time


def make_pdf(path):
    stream = b"BT /F1 18 Tf 72 720 Td (Zathura migration check) Tj ET\n"
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Count 1 /Kids [3 0 R] >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Length %d >>\nstream\n" % len(stream) + stream + b"endstream",
    ]
    data = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for number, obj in enumerate(objects, 1):
        offsets.append(len(data))
        data.extend(f"{number} 0 obj\n".encode() + obj + b"\nendobj\n")
    xref = len(data)
    data.extend(f"xref\n0 {len(offsets)}\n".encode())
    data.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        data.extend(f"{offset:010d} 00000 n \n".encode())
    data.extend(f"trailer\n<< /Size {len(offsets)} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n".encode())
    path.write_bytes(data)


with tempfile.TemporaryDirectory(prefix="zathura-check-") as tmp:
    root = Path(tmp)
    pdf = root / "migration-check.pdf"
    make_pdf(pdf)
    for name in ("data", "cache"):
        (root / name).mkdir()
    env = dict(os.environ, HOME=tmp, XDG_DATA_HOME=str(root / "data"),
               XDG_CACHE_HOME=str(root / "cache"), GDK_BACKEND="x11")
    env.pop("WAYLAND_DISPLAY", None)
    env.pop("DBUS_SESSION_BUS_ADDRESS", None)
    config = Path.home() / ".config/zathura"
    proc = subprocess.Popen(
        ["/usr/bin/zathura", "--config-dir", str(config), "--data-dir", str(root / "data"),
         "--cache-dir", str(root / "cache"), str(pdf)],
        env=env, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
    )
    try:
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if proc.poll() is not None:
                raise RuntimeError(f"zathura exited: {proc.stderr.read().decode(errors='replace')}")
            windows = subprocess.check_output(["xwininfo", "-root", "-tree"], env=env, text=True)
            if "migration-check.pdf" in windows:
                print("System zathura opened the PDF with the current configuration")
                break
            time.sleep(0.1)
        else:
            raise RuntimeError("zathura did not display the PDF")
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()

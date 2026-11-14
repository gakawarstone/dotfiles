#!/usr/bin/env python3
"""Test current OpenCode configuration without personal data or network calls."""

import json
import os
from pathlib import Path
import subprocess
import tempfile


config = Path.home() / ".config/opencode"
data = json.loads((config / "opencode.json").read_text())
assert "strict" in data.get("agents", {})
with tempfile.TemporaryDirectory(prefix="opencode-check-") as tmp:
    root = Path(tmp)
    binary = root / "bin"
    binary.mkdir()
    wakatime = binary / "wakatime-cli"
    wakatime.write_text("#!/bin/sh\nexit 0\n")
    wakatime.chmod(0o755)
    env = dict(os.environ, HOME=tmp, WAKATIME_HOME=str(root / "wakatime"),
               PATH=f'{binary}:{os.environ.get("PATH", "")}')
    for key in list(env):
        if key.startswith("HERDR_"):
            env.pop(key)
    env.update(HERDR_ENV="1", HERDR_PANE_ID="isolated-test",
               HERDR_SOCKET_PATH=str(root / "unused.sock"))
    subprocess.run(["node", str(Path(__file__).with_suffix(".mjs")), str(config)],
                   env=env, cwd=root, timeout=15, check=True)

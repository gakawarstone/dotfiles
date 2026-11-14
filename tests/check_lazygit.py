#!/usr/bin/env python3
"""Exercise the system lazygit and gkpager using a disposable repository."""

import fcntl
import os
from pathlib import Path
import pty
import select
import shlex
import shutil
import struct
import subprocess
import tempfile
import termios
import time


with tempfile.TemporaryDirectory(prefix="lazygit-check-") as tmp:
    root = Path(tmp)
    repo = root / "repo"
    repo.mkdir()
    real_pager = shutil.which("gkpager")
    if real_pager is None:
        raise RuntimeError("gkpager is not in PATH")
    tools_dir = root / "tools"
    tools_dir.mkdir()
    calls = root / "gkpager-calls"
    pager = tools_dir / "gkpager"
    pager.write_text(
        f"#!/bin/sh\nprintf '%s\\n' \"$*\" >> {shlex.quote(str(calls))}\n"
        f"exec {shlex.quote(real_pager)} \"$@\"\n"
    )
    pager.chmod(0o755)
    env = dict(os.environ, TERM="xterm-256color", GIT_CONFIG_GLOBAL="/dev/null",
               GIT_CONFIG_NOSYSTEM="1", PATH=f'{tools_dir}:{os.environ.get("PATH", "")}')

    def git(*args):
        return subprocess.run(["git", *args], cwd=repo, env=env, check=True,
                              stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)

    git("init", "-q")
    (repo / "example.py").write_text('print("old")\n')
    git("add", "example.py")
    git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "initial")
    (repo / "example.py").write_text('print("new")\n')
    diff = subprocess.check_output(["git", "diff", "--color=always"], cwd=repo, env=env)
    rendered = subprocess.run(["gkpager", "--mode", "lazygit"], input=diff, env=env,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10, check=True)
    if not rendered.stdout:
        raise RuntimeError("gkpager produced no output")
    calls.unlink()

    pid, master = pty.fork()
    if pid == 0:
        os.execvpe("lazygit", ["lazygit", "--path", str(repo)], env)
    fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
    output = b""
    try:
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], 0.2)
            if ready:
                try:
                    output += os.read(master, 65536)
                except OSError:
                    break
                if b"example.py" in output and calls.exists():
                    break
            child, status = os.waitpid(pid, os.WNOHANG)
            if child:
                pid = 0
                break
        if b"example.py" not in output or not calls.exists():
            raise RuntimeError(f"lazygit did not display the changed file with gkpager: {output[-1000:]!r}")
        if "--mode lazygit" not in calls.read_text():
            raise RuntimeError("lazygit did not invoke gkpager in lazygit mode")
        os.write(master, b"q")
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            child, status = os.waitpid(pid, os.WNOHANG)
            if child:
                pid = 0
                if os.waitstatus_to_exitcode(status) != 0:
                    raise RuntimeError(f"lazygit exited with status {status}")
                break
            time.sleep(0.1)
        else:
            raise RuntimeError("lazygit did not exit after q")
        print("lazygit displayed the changed file through gkpager and exited cleanly")
    finally:
        if pid:
            os.kill(pid, 15)
            os.waitpid(pid, 0)
        os.close(master)

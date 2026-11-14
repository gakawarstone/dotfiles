#!/usr/bin/env python3
"""Start Yazi with the selected configuration in a disposable directory."""
import fcntl
import os
import pty
import select
import signal
import struct
import sys
import tempfile
import termios
import time
from pathlib import Path

config = Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory(prefix='yazi-check-') as tmp:
    root = Path(tmp)
    (root / 'visible-example.txt').write_text('example\n')
    env = dict(os.environ, TERM='xterm-256color', YAZI_CONFIG_HOME=str(config), PWD=str(root))
    pid, master = pty.fork()
    if pid == 0:
        os.chdir(root)
        os.execvpe('yazi', ['yazi', str(root)], env)
    fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 120, 0, 0))
    try:
        output = b''
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if select.select([master], [], [], 0.2)[0]:
                try:
                    output += os.read(master, 65536)
                except OSError:
                    break
                if b'visible-example.txt' in output:
                    break
        if b'visible-example.txt' not in output:
            raise RuntimeError(f'Yazi did not display the test file: {output[-1000:]!r}')
        os.write(master, b'q')
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            child, status = os.waitpid(pid, os.WNOHANG)
            if child:
                pid = 0
                if os.waitstatus_to_exitcode(status) != 0:
                    raise RuntimeError('Yazi exited unsuccessfully')
                break
            time.sleep(0.1)
        else:
            raise RuntimeError('Yazi did not exit')
        print('Yazi displayed the test file and exited successfully')
    finally:
        if pid:
            os.kill(pid, signal.SIGTERM)
            os.waitpid(pid, 0)
        os.close(master)

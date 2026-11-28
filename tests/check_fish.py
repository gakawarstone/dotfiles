#!/usr/bin/env python3
"""Check the shared interactive fish config without touching personal state."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

source = Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory(prefix='fish-check-') as tmp:
    root = Path(tmp)
    config = root / '.config/fish'
    shutil.copytree(source, config, ignore=shutil.ignore_patterns('fish_variables', 'fish_history'))
    tools = root / 'tools'; tools.mkdir()
    for name in ('zoxide', 'starship'):
        p = tools / name; p.write_text('#!/bin/sh\nexit 0\n'); p.chmod(0o755)
    env = dict(os.environ, HOME=tmp, XDG_CONFIG_HOME=str(root / '.config'), XDG_DATA_HOME=str(root / '.local/share'), XDG_CACHE_HOME=str(root / '.cache'), PATH=str(tools) + ':/usr/bin:/bin', TERM='xterm-256color')
    script = 'functions -q a; and functions -q csol; and functions -q cat; and test "$EDITOR" = nvim; and echo FISH_CONFIG_OK'
    result = subprocess.run(['/usr/bin/fish', '-i', '-c', script], env=env, cwd=tmp, capture_output=True, text=True, timeout=15)
    if result.returncode != 0 or 'FISH_CONFIG_OK' not in result.stdout:
        raise RuntimeError('fish startup failed: ' + result.stderr)
    print('fish interactive startup and core aliases passed in isolation')

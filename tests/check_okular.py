#!/usr/bin/env python3
"""Open a temporary PDF in isolated Okular using the current color schemes."""
import ast
import configparser
import os
from pathlib import Path
import subprocess
import tempfile
import time

schemes = Path.home() / '.local/share/color-schemes'
for name in ('CatppuccinLatteMauve', 'CatppuccinMochaMauve'):
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    assert parser.read(schemes / (name + '.colors')) and parser.has_section('Colors:Window')

# Reuse the small PDF generator without running the zathura test.
source = Path(__file__).with_name('check_zathura.py').read_text()
tree = ast.parse(source)
function = next(node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == 'make_pdf')
namespace = {}
exec(compile(ast.Module(body=[function], type_ignores=[]), '<pdf-generator>', 'exec'), namespace)
with tempfile.TemporaryDirectory(prefix='okular-check-') as tmp:
    root = Path(tmp)
    pdf = root / 'okular-migration-check.pdf'
    namespace['make_pdf'](pdf)
    data = root / 'data'; data.mkdir()
    (data / 'color-schemes').symlink_to(schemes, target_is_directory=True)
    env = dict(os.environ, HOME=tmp, XDG_CONFIG_HOME=str(root / 'config'), XDG_DATA_HOME=str(data), XDG_CACHE_HOME=str(root / 'cache'), QT_QPA_PLATFORM='xcb')
    for key in ('WAYLAND_DISPLAY', 'DBUS_SESSION_BUS_ADDRESS'):
        env.pop(key, None)
    proc = subprocess.Popen(['/usr/bin/okular', '--unique', str(pdf)], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    try:
        deadline = time.monotonic() + 12
        while time.monotonic() < deadline:
            if proc.poll() is not None:
                raise RuntimeError('Okular exited: ' + proc.stderr.read().decode(errors='replace'))
            windows = subprocess.check_output(['xwininfo', '-root', '-tree'], env=env, text=True)
            if 'okular-migration-check.pdf' in windows:
                print('Okular opened the PDF; both color schemes parse')
                break
            time.sleep(0.1)
        else:
            raise RuntimeError('Okular did not display the PDF')
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill(); proc.wait()

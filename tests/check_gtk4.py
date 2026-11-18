#!/usr/bin/python3
"""Parse both GTK 4 stylesheets and check their Catppuccin accent color."""
from pathlib import Path
import sys
import warnings
import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Gdk', '4.0')
from gi.repository import Gdk, Gtk

warnings.filterwarnings('ignore', category=DeprecationWarning)
Gtk.init()
display = Gdk.Display.get_default()
assert display is not None
root = Path(sys.argv[1])
for name in ('gtk.css', 'gtk-dark.css'):
    errors = []
    provider = Gtk.CssProvider()
    provider.connect('parsing-error', lambda _, section, error: errors.append(str(error)))
    provider.load_from_path(str(root / name))
    if errors:
        raise RuntimeError(f'{name}: {errors}')
    Gtk.StyleContext.add_provider_for_display(display, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER)
    label = Gtk.Label(label='GTK migration check')
    found, color = label.get_style_context().lookup_color('accent_color')
    if not found or any(abs(a-b) > 0.01 for a, b in zip((color.red, color.green, color.blue), (0xcb/255, 0xa6/255, 0xf7/255))):
        raise RuntimeError(f'{name}: Catppuccin accent not loaded')
    Gtk.StyleContext.remove_provider_for_display(display, provider)
print('GTK 4 parsed both stylesheets and loaded the Catppuccin accent')

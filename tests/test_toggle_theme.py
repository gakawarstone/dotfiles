import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "bins/toggle_theme"
GTK_HELPER = Path(__file__).resolve().parents[1] / "scripts/sync_gtk_theme.sh"


class ToggleThemeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        home = Path(self.tmp.name)
        repo = home / "dotfiles"
        self.hypr = repo / "configs/hyprland/.config/hypr"
        self.foot = repo / "configs/foot/.config/foot"
        self.shell = repo / "configs/quickshell/.config/quickshell"
        for directory in (self.hypr, self.foot, self.shell, repo / "scripts", home / "bin"):
            directory.mkdir(parents=True)
        for directory, name in ((self.hypr, "theme.conf"), (self.hypr, "hyprpaper.conf"),
                                (self.foot, "theme.ini"), (self.shell, "Theme.qml")):
            (directory / name).symlink_to("mocha.conf")
        for name in ("gdbus", "gsettings", "pgrep"):
            self.command(home / "bin" / name, "exit 1")
        self.command(home / "bin/hyprctl", "exit 0")
        self.command(repo / "scripts/sync_okular_theme.sh", "exit 0")
        self.env = dict(os.environ, HOME=str(home), PATH=f"{home}/bin:/usr/bin:/bin")
        self.bin = home / "bin"

    @staticmethod
    def command(path, content):
        path.write_text("#!/bin/sh\n" + content + "\n")
        path.chmod(0o755)

    def run_toggle(self):
        return subprocess.run(["bash", str(SCRIPT)], env=self.env, capture_output=True)

    def test_switches_symlinks(self):
        self.assertEqual(self.run_toggle().returncode, 0)
        self.assertEqual(os.readlink(self.hypr / "theme.conf"), "latte.conf")
        self.assertEqual(os.readlink(self.foot / "theme.ini"), "latte.ini")
        self.assertEqual(os.readlink(self.shell / "Theme.qml"), "Latte.qml")

    def test_preserves_regular_file_without_changing_other_links(self):
        target = self.foot / "theme.ini"
        target.unlink()
        target.write_text("local theme")
        self.assertNotEqual(self.run_toggle().returncode, 0)
        self.assertEqual(target.read_text(), "local theme")
        self.assertEqual(os.readlink(self.hypr / "theme.conf"), "mocha.conf")

    def test_link_failure_stops_switching(self):
        self.command(self.bin / "ln", "exit 1")
        self.assertNotEqual(self.run_toggle().returncode, 0)
        self.assertEqual(os.readlink(self.hypr / "theme.conf"), "mocha.conf")
        self.assertEqual(os.readlink(self.foot / "theme.ini"), "mocha.conf")

    def test_uses_managed_okular_helper_when_available(self):
        marker = Path(self.env["HOME"]) / "managed-theme"
        self.command(self.bin / "sync_okular_theme", f'printf "%s" "$1" > "{marker}"')
        self.assertEqual(self.run_toggle().returncode, 0)
        self.assertEqual(marker.read_text(), "latte")

    def test_falls_back_to_checkout_helper(self):
        marker = Path(self.env["HOME"]) / "checkout-theme"
        helper = Path(self.env["HOME"]) / "dotfiles/scripts/sync_okular_theme.sh"
        self.command(helper, f'printf "%s" "$1" > "{marker}"')
        self.assertEqual(self.run_toggle().returncode, 0)
        self.assertEqual(marker.read_text(), "latte")

    def test_switches_gtk_and_preserves_conflicting_state(self):
        home = Path(self.env["HOME"])
        (self.bin / "sync_gtk_theme").symlink_to(GTK_HELPER)
        palettes = home / ".local/share/dotfiles-gtk"
        palettes.mkdir(parents=True)
        for theme in ("mocha", "latte"):
            (palettes / f"{theme}.css").write_text(theme)
        self.assertEqual(self.run_toggle().returncode, 0)
        current = home / ".local/state/dotfiles-gtk/current.css"
        self.assertEqual(current.read_text(), "latte")
        current.unlink()
        current.write_text("local")
        self.assertNotEqual(self.run_toggle().returncode, 0)
        self.assertEqual(current.read_text(), "local")
        self.assertEqual(os.readlink(self.hypr / "theme.conf"), "latte.conf")


if __name__ == "__main__":
    unittest.main()
